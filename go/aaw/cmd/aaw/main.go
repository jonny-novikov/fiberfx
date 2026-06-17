// Command aaw is the minimal AAW MCP server: the team/scope registry, the
// single-file audit ledger, and the process gates behind the x-mode lead-team
// protocol. Wire contract per .mcp.json: streamable HTTP at localhost:8905.
//
// Flags go BEFORE the mode word — flag.Parse stops at the first non-flag
// argument, so flags after it silently keep their defaults (the L-5 quirk):
//
//	aaw [-addr localhost:8905] [-workspace .] [-log-level info] [-stdio] [-wire-check strict|warn|skip] serve
//	aaw [-addr localhost:8905] selftest   # connect as a client, verify registration + a ledger round-trip
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/fiberfx/mcp-go/v2/mcp"
	"github.com/jonny-novikov/aaw/internal/config"
	"github.com/jonny-novikov/aaw/internal/gates"
	"github.com/jonny-novikov/aaw/internal/signals"
	"github.com/jonny-novikov/aaw/internal/store"
)

const version = "2.0.0-min"

// The five identity flags (MCP4-D1): boot identity is flags-only; runtime
// policy lives in .aaw/config.json, read through per evaluation.
var flags = config.RegisterFlags(flag.CommandLine)

func main() {
	flag.Parse()
	if !config.ValidWireCheck(flags.WireCheck) {
		fmt.Fprintf(os.Stderr, "aaw: bad -wire-check %q (strict|warn|skip)\n", flags.WireCheck)
		os.Exit(2)
	}
	if _, err := config.SlogLevel(flags.LogLevel); err != nil {
		fmt.Fprintf(os.Stderr, "aaw: %v\n", err)
		os.Exit(2)
	}
	mode := "serve"
	if flag.NArg() > 0 {
		mode = flag.Arg(0)
	}
	switch mode {
	case "serve":
		runServer()
	case "selftest":
		runSelftest()
	default:
		fmt.Fprintf(os.Stderr, "usage: aaw [-addr host:port] [-workspace dir] [-log-level lvl] [-stdio] [-wire-check strict|warn|skip] [serve|selftest]\n")
		os.Exit(2)
	}
}

// ---- tool parameter/result types (schemas inferred from these structs) ----

type InitIn struct {
	Scope     string `json:"scope" jsonschema:"scope slug (lowercase alphanumeric + dashes, no dots)"`
	Operator  string `json:"operator,omitempty" jsonschema:"the human operator name"`
	Workspace string `json:"workspace,omitempty" jsonschema:"informational; the server is bound to its own -workspace"`
	LedgerDir string `json:"ledger_dir,omitempty" jsonschema:"REQUIRED on first init: directory holding <scope>.progress.md (convention: the scope's deliverable dir); relative paths resolve against the workspace"`
	TTLDays   int    `json:"ttl_days,omitempty" jsonschema:"scope TTL in days (archival hint)"`
	Actor     string `json:"actor,omitempty" jsonschema:"optional attributing agent codename; registry-side only (advances last_seen_at); unregistered names raise an advisory, never a refusal"`
}

// InitOut resolves the one v1 output ambiguity additively (MCP3-D3 / AD-6):
// scope_created reports the index row was new; ledger_created reports the
// ledger file was absent and a header written. created is kept as the
// documented v1 alias of scope_created — no field renamed or retyped, so a
// client holding MCP2 shapes stays valid (MCP3-INV3).
type InitOut struct {
	Ok            bool   `json:"ok"`
	Scope         string `json:"scope"`
	LedgerPath    string `json:"ledger_path"`
	Created       bool   `json:"created"`
	ScopeCreated  bool   `json:"scope_created"`
	LedgerCreated bool   `json:"ledger_created"`
}

type SpawnIn struct {
	Scope       string `json:"scope" jsonschema:"scope slug"`
	Role        string `json:"role" jsonschema:"role, e.g. director|architect|implementor|evaluator"`
	Archetype   string `json:"archetype,omitempty" jsonschema:"archetype label"`
	Name        string `json:"name" jsonschema:"agent codename, e.g. Venus-1"`
	ParentID    string `json:"parent_id,omitempty" jsonschema:"CCL-id of the parent (omit for the director)"`
	Deliverable string `json:"deliverable,omitempty" jsonschema:"spawn-declared deliverable file; its mtime is a liveness source (relative paths resolve against the workspace)"`
	Model       string `json:"model,omitempty" jsonschema:"agent model id (LAW-2 record-only evidence; empty on re-spawn keeps the recorded value)"`
	Actor       string `json:"actor,omitempty" jsonschema:"optional attributing agent codename; registry-side only"`
}
type SpawnOut struct {
	Ok    bool   `json:"ok"`
	CCLID string `json:"ccl_id"`
}

type RegisterIn struct {
	Scope string `json:"scope" jsonschema:"scope slug"`
	Name  string `json:"name" jsonschema:"agent codename"`
	Role  string `json:"role" jsonschema:"role"`
	CCLID string `json:"ccl_id,omitempty" jsonschema:"CCL-id from aaw_spawn, if known"`
	Model string `json:"model,omitempty" jsonschema:"agent model id (LAW-2 record-only evidence; empty keeps the recorded value)"`
	Actor string `json:"actor,omitempty" jsonschema:"optional attributing agent codename; registry-side only"`
}
type RegisterOut struct {
	Ok         bool `json:"ok"`
	Spawned    int  `json:"spawned"`
	Registered int  `json:"registered"`
	FakeN      bool `json:"fake_n_signal"`
}

type SendIn struct {
	Scope string `json:"scope" jsonschema:"scope slug"`
	To    string `json:"to" jsonschema:"recipient agent codename (must be registered)"`
	Body  string `json:"body" jsonschema:"message body"`
	Actor string `json:"actor,omitempty" jsonschema:"optional attributing agent codename; registry-side only"`
}
type SendOut struct {
	Ok        bool `json:"ok"`
	Delivered bool `json:"delivered"`
}

type HeartbeatIn struct {
	Scope           string `json:"scope" jsonschema:"scope slug"`
	Name            string `json:"name" jsonschema:"agent codename whose row to touch (lease-at-dispatch: the director may heartbeat for a peer it dispatched)"`
	Note            string `json:"note,omitempty" jsonschema:"optional liveness note recorded on the row"`
	QuietForMinutes int    `json:"quiet_for_minutes,omitempty" jsonschema:"optional declared-quiet window in minutes, capped at 240"`
}
type HeartbeatOut struct {
	Ok         bool   `json:"ok"`
	Name       string `json:"name"`
	LastSeenAt string `json:"last_seen_at"`
	QuietUntil string `json:"quiet_until,omitempty"`
}

type StatusIn struct {
	Scope string `json:"scope" jsonschema:"scope slug"`
}

// Gates is the x.md §10 pre-commit answer (MCP2-D3): z_eligible = d_count >= 1
// (the LAW-4 trigger — a Z append is admissible); z_count says whether a Z
// already exists, so the full §10 precondition reads off the one payload.
type Gates struct {
	ZEligible bool `json:"z_eligible"`
	DCount    int  `json:"d_count"`
	ZCount    int  `json:"z_count"`
}

// LivenessRow is one per-agent gate-console row: the three-source verdict
// with its winning source, plus the LAW-2 record-only model evidence.
type LivenessRow struct {
	Name          string `json:"name"`
	Role          string `json:"role"`
	Model         string `json:"model,omitempty"`
	CCLID         string `json:"ccl_id,omitempty"`
	LastSeenAt    string `json:"last_seen_at,omitempty"`
	Verdict       string `json:"verdict"`
	WinningSource string `json:"winning_source"`
}

// SignalRow is one open (unexpired) advisory signal on the console.
type SignalRow struct {
	Code string `json:"code"`
	At   string `json:"at"`
	Msg  string `json:"msg"`
}

// StatusOut is the gate console (MCP2-D3). Every field beyond the MCP1 five
// (scope, ledger_path, agents, tallies, messages) is additive. wire_contract
// is the verdict the BOOT computed (MCP4-D3, closing the MCP2 omission):
// never constant, never defaulted — when no boot computed one (an in-process
// harness without a bind plane), the field is absent, not fabricated.
type StatusOut struct {
	Scope      string         `json:"scope"`
	LedgerPath string         `json:"ledger_path"`
	Agents     []*store.Agent `json:"agents"`
	Tallies    map[string]int `json:"tallies"`
	Messages   int            `json:"messages"`
	Gates      Gates          `json:"gates"`
	Liveness   []LivenessRow  `json:"liveness"`
	Signals    []SignalRow    `json:"signals"`
	Archived   bool           `json:"archived"`
	ParseOK    bool           `json:"parse_ok"`
	ParseError string         `json:"parse_error,omitempty"`
	EntryCount int            `json:"entry_count"`
	// UnknownPrefixes is the additive MCP3-D7 parse-health field: entry
	// prefixes outside the reserved §8 vocabulary (a hand `### ADR-3`),
	// sorted — reported, never gating.
	UnknownPrefixes []string `json:"unknown_prefixes,omitempty"`
	WireContract    string   `json:"wire_contract,omitempty"`
}

type ProbeIn struct{}

// ProbeOut carries the AD-11 boot observability fields (MCP4-D5), all
// additive against the MCP3 shape: started_at/listeners/wire_contract are
// what the boot computed; effective_config and reopened_at are per-call
// read-throughs (a config edit or an out-of-band reopened_at stamp shows on
// the next probe).
type ProbeOut struct {
	Ok              bool                   `json:"ok"`
	Name            string                 `json:"name"`
	Version         string                 `json:"version"`
	Workspace       string                 `json:"workspace"`
	Scopes          []string               `json:"scopes"`
	InstanceID      string                 `json:"instance_id,omitempty"`
	PID             int                    `json:"pid,omitempty"`
	StartedAt       string                 `json:"started_at,omitempty"`
	Listeners       []string               `json:"listeners,omitempty"`
	ReopenedAt      map[string]string      `json:"reopened_at,omitempty"`
	EffectiveConfig map[string]config.Knob `json:"effective_config,omitempty"`
	WireContract    string                 `json:"wire_contract,omitempty"`
	At              string                 `json:"at"`
}

type EntryIn struct {
	TaskID string `json:"task_id" jsonschema:"task id (use the scope slug)"`
	Slug   string `json:"slug" jsonschema:"scope slug (must equal an initialized scope)"`
	Body   string `json:"body" jsonschema:"entry body; a first line of the form 'X-9 — title' lifts the title into the header"`
	Draft  bool   `json:"draft,omitempty" jsonschema:"analyze only: sampled-draft flag (recorded, no behavior change in the minimal server)"`
	Actor  string `json:"actor,omitempty" jsonschema:"optional attributing agent codename; registry-side only (last_seen_at + per-prefix counter) — the entry header is byte-identical with or without it"`
}
type EntryOut struct {
	Ok    bool   `json:"ok"`
	Entry string `json:"entry"`
	Path  string `json:"path"`
}

// ---- server ----

// touchActor records a non-ledger writer's optional attribution (MCP2-D1):
// registry-side only, advisory all the way — an unregistered name emits one
// UNREGISTERED-ATTRIBUTION line and the call proceeds regardless.
func touchActor(sc *store.Scope, em *signals.Emitter, scope, actor, tool string) {
	unregistered, err := sc.TouchActor(actor)
	if err != nil {
		log.Printf("aaw: advisory: attribution touch for %q failed: %v", actor, err)
		return
	}
	if unregistered {
		emitUnregistered(em, scope, actor, tool)
	}
}

// emitContainment is the MCP3-D8 rider's ONE emit site: a write through any
// tool to a legacy scope whose ledger_dir sits outside the workspace root
// leaves one deduplicated CONTAINMENT advisory line in .claude/audit.log —
// reported, never refused (AD-5; the dedup is the Emitter's window rule).
// New scopes never reach here out-of-root: the PATH_ESCAPE door refuses them
// before a row exists.
func emitContainment(em *signals.Emitter, workspace, tool string, sc *store.Scope) {
	resolved, ok := gates.Contained(workspace, sc.LedgerDir)
	if ok {
		return
	}
	_, err := em.Emit(time.Now().UTC(), sc.Name, signals.CodeContainment,
		[]signals.KV{{Key: "ledger_dir", Val: resolved}, {Key: "tool", Val: tool}},
		fmt.Sprintf("write to legacy out-of-tree scope %q: ledger_dir %s is outside the workspace root %s; the write proceeded", sc.Name, resolved, workspace))
	if err != nil {
		log.Printf("aaw: advisory: audit emit failed: %v", err)
	}
}

func emitUnregistered(em *signals.Emitter, scope, actor, tool string) {
	_, err := em.Emit(time.Now().UTC(), scope, signals.CodeUnregisteredAttribution,
		[]signals.KV{{Key: "actor", Val: actor}, {Key: "tool", Val: tool}},
		fmt.Sprintf("actor %q has no registry row in scope %q; the write proceeded unattributed, no row created", actor, scope))
	if err != nil {
		log.Printf("aaw: advisory: audit emit failed: %v", err)
	}
}

// loadPolicy is the per-evaluation policy read-through (MCP4-D1): a config
// read or parse failure logs an advisory and yields the default layer —
// policy never blocks a tool call.
func loadPolicy(workspace string) config.Policy {
	pol, err := config.LoadPolicy(workspace)
	if err != nil {
		log.Printf("aaw: advisory: policy config: %v", err)
	}
	return pol
}

// evidenceRows distills the registry into the V-SOLO inputs: per-row role,
// the three-source staleness verdict (over the policy window), and the
// attributed-entry instants.
func evidenceRows(sc *store.Scope, r *store.Registry, window time.Duration, now time.Time) []signals.AgentEvidence {
	rows := make([]signals.AgentEvidence, 0, len(r.Agents))
	for _, a := range r.Agents {
		verdict, _ := sc.Liveness(a, window, now)
		rows = append(rows, signals.AgentEvidence{Role: a.Role, Stale: verdict == store.VerdictStale, AttributedAt: a.AttributionInstants()})
	}
	return rows
}

// evaluateFormation runs the read-time signal pass (MCP2-D4) at its two
// evaluation points, aaw_status and Z-append: two-clause V-SOLO-1 emits;
// V-SOLO-2 is computed and held — never emitted (the W-1 adjudication: the
// R-4 degraded run is legitimate history; the evidence stays registry-side).
// pol is the caller's per-evaluation read-through (MCP4-D1). Advisory
// throughout: every failure is swallowed, no call blocks.
func evaluateFormation(sc *store.Scope, em *signals.Emitter, pol config.Policy, now time.Time) {
	r, err := sc.LoadRegistry()
	if err != nil {
		return
	}
	rows := evidenceRows(sc, r, pol.WindowW, now)
	if fires, stale, entries := signals.VSolo1(rows, now, pol.WindowW, pol.ThresholdK); fires {
		_, err := em.Emit(now, sc.Name, signals.CodeVSolo1,
			[]signals.KV{{Key: "stale_peers", Val: strconv.Itoa(stale)}, {Key: "director_entries", Val: strconv.Itoa(entries)}, {Key: "window", Val: pol.WindowW.String()}},
			fmt.Sprintf("all non-director rows stale and %d director-attributed entries within %s (threshold %d)", entries, pol.WindowW, pol.ThresholdK))
		if err != nil {
			log.Printf("aaw: advisory: audit emit failed: %v", err)
		}
	}
	_ = signals.VSolo2(rows)
}

// bootInfo carries what the boot computed for probe/aaw_status (MCP4-D5):
// reported, never recomputed and never defaulted — a nil bootInfo (an
// in-process harness without a bind plane) omits the fields rather than
// fabricating a verdict (MCP4-INV3).
type bootInfo struct {
	startedAt string
	listeners []string
	wire      string
}

// reopenedAt reads per-scope reopened_at stamps straight from the raw
// scopes.json — a read-through, additive surface: the durable stamp is
// written by the archival re-open (AD-10, a later rung); rows without one
// are omitted. Raw JSON is read because store.Scope does not model the
// field yet (internal/store is tests-only this rung, D-18).
func reopenedAt(workspace string) map[string]string {
	b, err := os.ReadFile(filepath.Join(workspace, ".aaw", "scopes.json"))
	if err != nil {
		return nil
	}
	rows := map[string]map[string]any{}
	if json.Unmarshal(b, &rows) != nil {
		return nil
	}
	var out map[string]string
	for name, row := range rows {
		if ts, ok := row["reopened_at"].(string); ok && ts != "" {
			if out == nil {
				out = map[string]string{}
			}
			out[name] = ts
		}
	}
	return out
}

func newServer(st *store.Store, lk *store.InstanceLock, boot *bootInfo, logger *slog.Logger) *mcp.Server {
	// The AD-11 slog wiring: -log-level drives the one stderr logger; nil
	// (tests) leaves the SDK's no-op default in place.
	server := mcp.NewServer(&mcp.Implementation{Name: "aaw", Version: version}, &mcp.ServerOptions{Logger: logger})
	em := signals.NewEmitter(st.Workspace)

	mcp.AddTool(server, &mcp.Tool{Name: "aaw_init", Description: "Create or idempotently re-open a scope: registers it in the workspace index and creates <ledger_dir>/<scope>.progress.md if absent (a hand-written ledger is first-class input and is never touched)."},
		func(ctx context.Context, req *mcp.CallToolRequest, in *InitIn) (*mcp.CallToolResult, any, error) {
			ttl := in.TTLDays
			if ttl == 0 {
				// The default ttl_days knob (MCP4-D1): an omitted ttl_days
				// takes the policy default (built-in 0 = no TTL hint).
				ttl = loadPolicy(st.Workspace).TTLDays
			}
			sc, scopeCreated, ledgerCreated, err := st.InitScope(in.Scope, in.Operator, in.LedgerDir, ttl)
			if err != nil {
				return nil, nil, err
			}
			touchActor(sc, em, in.Scope, in.Actor, "aaw_init")
			return nil, &InitOut{Ok: true, Scope: sc.Name, LedgerPath: sc.LedgerPath(), Created: scopeCreated, ScopeCreated: scopeCreated, LedgerCreated: ledgerCreated}, nil
		})

	mcp.AddTool(server, &mcp.Tool{Name: "aaw_spawn", Description: "Record a spawned agent in the scope registry and mint its CCL-id. The parent (by CCL-id) must exist, except for the director. An optional deliverable file is recorded as the agent's third liveness source (its mtime)."},
		func(ctx context.Context, req *mcp.CallToolRequest, in *SpawnIn) (*mcp.CallToolResult, any, error) {
			sc, err := st.GetScope(in.Scope)
			if err != nil {
				return nil, nil, err
			}
			if in.Name == "" || in.Role == "" {
				return nil, nil, gates.Errorf(gates.ARG_MISSING, "aaw_spawn requires name and role")
			}
			// The MCP3-D8 door: a spawn-declared deliverable must resolve
			// under the workspace root, or the call refuses creating nothing.
			if in.Deliverable != "" {
				if resolved, ok := gates.Contained(st.Workspace, in.Deliverable); !ok {
					return nil, nil, gates.Errorf(gates.PATH_ESCAPE, "deliverable %q resolves to %s, outside the workspace root %s", in.Deliverable, resolved, st.Workspace)
				}
			}
			cclID, err := sc.SpawnAgent(in.Name, in.Role, in.Archetype, in.ParentID, in.Deliverable, in.Model)
			if err != nil {
				return nil, nil, err
			}
			emitContainment(em, st.Workspace, "aaw_spawn", sc)
			touchActor(sc, em, in.Scope, in.Actor, "aaw_spawn")
			return nil, &SpawnOut{Ok: true, CCLID: cclID}, nil
		})

	mcp.AddTool(server, &mcp.Tool{Name: "agent_register", Description: "Register an agent identity in the scope registry (LAW-1). Returns the spawn-vs-register tallies; registered > spawned raises the advisory FAKE-N signal (audit.log) without refusing the call."},
		func(ctx context.Context, req *mcp.CallToolRequest, in *RegisterIn) (*mcp.CallToolResult, any, error) {
			sc, err := st.GetScope(in.Scope)
			if err != nil {
				return nil, nil, err
			}
			if in.Name == "" || in.Role == "" {
				return nil, nil, gates.Errorf(gates.ARG_MISSING, "agent_register requires name and role")
			}
			spawned, registered, err := sc.RegisterAgent(in.Name, in.Role, in.CCLID, in.Model)
			if err != nil {
				return nil, nil, err
			}
			fakeN := registered > spawned
			if fakeN {
				// Re-routed from the PoC's stderr to .claude/audit.log (MCP2-D4).
				_, eerr := em.Emit(time.Now().UTC(), in.Scope, signals.CodeFakeN,
					[]signals.KV{{Key: "registered", Val: strconv.Itoa(registered)}, {Key: "spawned", Val: strconv.Itoa(spawned)}},
					fmt.Sprintf("agent_register %q: registered %d > spawned %d (LAW-1 mismatch)", in.Name, registered, spawned))
				if eerr != nil {
					log.Printf("aaw: advisory: audit emit failed: %v", eerr)
				}
			}
			emitContainment(em, st.Workspace, "agent_register", sc)
			touchActor(sc, em, in.Scope, in.Actor, "agent_register")
			return nil, &RegisterOut{Ok: true, Spawned: spawned, Registered: registered, FakeN: fakeN}, nil
		})

	mcp.AddTool(server, &mcp.Tool{Name: "agent_send", Description: "Record a message to a registered agent in the scope registry (delivery is the harness's job; this is the durable log)."},
		func(ctx context.Context, req *mcp.CallToolRequest, in *SendIn) (*mcp.CallToolResult, any, error) {
			sc, err := st.GetScope(in.Scope)
			if err != nil {
				return nil, nil, err
			}
			if err := sc.RecordMessage(in.To, in.Body); err != nil {
				return nil, nil, err
			}
			emitContainment(em, st.Workspace, "agent_send", sc)
			touchActor(sc, em, in.Scope, in.Actor, "agent_send")
			return nil, &SendOut{Ok: true, Delivered: true}, nil
		})

	mcp.AddTool(server, &mcp.Tool{Name: "agent_heartbeat", Description: "Zero-ledger-cost liveness touch on a registry row: refreshes last_seen_at, optionally declares a quiet window (capped at 240 minutes) and a note. Lease-at-dispatch: the director may heartbeat for a peer it dispatched."},
		func(ctx context.Context, req *mcp.CallToolRequest, in *HeartbeatIn) (*mcp.CallToolResult, any, error) {
			sc, err := st.GetScope(in.Scope)
			if err != nil {
				return nil, nil, err
			}
			if in.Name == "" {
				return nil, nil, gates.Errorf(gates.ARG_MISSING, "agent_heartbeat requires name")
			}
			// The quiet cap is the policy read-through's (MCP4-D1), default
			// signals.QuietCapMinutes.
			q := in.QuietForMinutes
			if quietCap := loadPolicy(st.Workspace).QuietCapMinutes; q > quietCap {
				q = quietCap
			}
			if q < 0 {
				q = 0
			}
			a, err := sc.Heartbeat(in.Name, in.Note, time.Duration(q)*time.Minute)
			if err != nil {
				return nil, nil, err
			}
			emitContainment(em, st.Workspace, "agent_heartbeat", sc)
			return nil, &HeartbeatOut{Ok: true, Name: a.Name, LastSeenAt: a.LastSeenAt, QuietUntil: a.QuietUntil}, nil
		})

	mcp.AddTool(server, &mcp.Tool{Name: "aaw_status", Description: "The gate console: per-prefix tallies, gates{z_eligible,d_count,z_count} (the x.md §10 pre-commit check in one call), per-agent three-source liveness verdicts with winning sources, open advisory signals, parse health."},
		func(ctx context.Context, req *mcp.CallToolRequest, in *StatusIn) (*mcp.CallToolResult, any, error) {
			sc, err := st.GetScope(in.Scope)
			if err != nil {
				return nil, nil, err
			}
			r, err := sc.LoadRegistry()
			if err != nil {
				return nil, nil, err
			}
			now := time.Now().UTC()
			pol := loadPolicy(st.Workspace)
			out := &StatusOut{
				Scope: sc.Name, LedgerPath: sc.LedgerPath(), Agents: r.Agents, Messages: len(r.Messages),
				Archived: sc.Archived(now),
				ParseOK:  true,
			}
			if boot != nil {
				out.WireContract = boot.wire
			}
			t, unknown, terr := sc.ParseHealth()
			if terr != nil {
				// Parse health degrades on the payload; the console never
				// refuses over an unreadable ledger (MCP2-INV3).
				out.ParseOK, out.ParseError, t, unknown = false, terr.Error(), map[string]int{}, nil
			}
			out.Tallies, out.UnknownPrefixes = t, unknown
			for _, n := range t {
				out.EntryCount += n
			}
			out.Gates = Gates{ZEligible: t["D"] >= 1, DCount: t["D"], ZCount: t["Z"]}
			for _, a := range r.Agents {
				verdict, source := sc.Liveness(a, pol.WindowW, now)
				out.Liveness = append(out.Liveness, LivenessRow{Name: a.Name, Role: a.Role, Model: a.Model, CCLID: a.CCLID, LastSeenAt: a.LastSeenAt, Verdict: verdict, WinningSource: source})
			}
			evaluateFormation(sc, em, pol, now)
			for _, s := range em.Open(in.Scope, now) {
				out.Signals = append(out.Signals, SignalRow{Code: s.Code, At: s.At.Format(time.RFC3339), Msg: s.Msg})
			}
			return nil, out, nil
		})

	mcp.AddTool(server, &mcp.Tool{Name: "probe", Description: "Health/diagnostic: server name, version, workspace, known scopes, the instance-lock holder, and the boot surface (started_at, listeners, effective_config with winning sources, wire_contract, per-scope reopened_at)."},
		func(ctx context.Context, req *mcp.CallToolRequest, in *ProbeIn) (*mcp.CallToolResult, any, error) {
			out := &ProbeOut{Ok: true, Name: "aaw", Version: version, Workspace: st.Workspace, Scopes: st.ScopeNames(), At: store.Now()}
			if lk != nil {
				out.InstanceID, out.PID = lk.ID, lk.PID
			}
			if boot != nil {
				out.StartedAt, out.Listeners, out.WireContract = boot.startedAt, boot.listeners, boot.wire
			}
			// effective_config is a per-call read-through (MCP4-D1): the
			// report names each knob's winning source as of THIS call.
			out.EffectiveConfig = loadPolicy(st.Workspace).Effective()
			out.ReopenedAt = reopenedAt(st.Workspace)
			return nil, out, nil
		})

	// The tool_x_* ledger writers: every stream appends a tagged channel
	// section entry to the scope's single <scope>.progress.md (the locked
	// model). tool_x_complete enforces the LAW-4 trigger (Z-n requires ≥1 D-n).
	streams := []struct{ tool, stream, desc string }{
		{"tool_x_trace", "trace", "Append a derivation trace (T-n) to the {scope-thinking} channel of <scope>.progress.md."},
		{"tool_x_analyze", "analyze", "Append an analysis (A-n) to the {scope-analysis} channel of <scope>.progress.md."},
		{"tool_x_alternative", "alternative", "Append an alternative (V-n) to the {scope-alternatives} channel of <scope>.progress.md."},
		{"tool_x_decision", "decision", "Append a locked decision (D-n) to the {scope-decisions} channel of <scope>.progress.md."},
		{"tool_x_learning", "learning", "Append a learning (L-n) to the {scope-learnings} channel of <scope>.progress.md."},
		{"tool_x_nxm_synthesize", "nxm_synthesize", "Append an NxM synthesis (S-n) to the {scope-nxm} channel of <scope>.progress.md."},
		{"tool_x_consensus", "consensus", "Append a consensus record (C-n) to the {scope-consensus} channel of <scope>.progress.md."},
		{"tool_x_escalation", "escalation", "Append an escalation (E-n) to the {scope-escalations} channel of <scope>.progress.md."},
		{"tool_x_progress", "progress", "Append a progress record (P-n) to the {scope-progress} channel of <scope>.progress.md."},
		{"tool_x_complete", "complete", "Append a completion record (Z-n) to the {scope-complete} channel — REFUSED while no D-n is locked (LAW-4 trigger)."},
		{"tool_x_report", "report", "Append a final report (Y-n) to the {scope-report} channel of <scope>.progress.md."},
	}
	for _, s := range streams {
		stream, tool := s.stream, s.tool
		mcp.AddTool(server, &mcp.Tool{Name: s.tool, Description: s.desc},
			func(ctx context.Context, req *mcp.CallToolRequest, in *EntryIn) (*mcp.CallToolResult, any, error) {
				if in.TaskID == "" || in.Slug == "" {
					return nil, nil, gates.Errorf(gates.ARG_MISSING, "task_id and slug are required (the cardinal rule); use the scope slug for both")
				}
				if !store.SlugRe.MatchString(in.Slug) {
					return nil, nil, gates.Errorf(gates.SLUG_INVALID, "slug %q violates the slug rule (lowercase alphanumeric + dashes, no dots)", in.Slug)
				}
				sc, err := st.GetScope(in.Slug)
				if err != nil {
					return nil, nil, err
				}
				id, att, err := sc.AppendAttributed(stream, in.Body, in.Actor)
				if err != nil {
					return nil, nil, err
				}
				emitContainment(em, st.Workspace, tool, sc)
				if att.Unregistered {
					emitUnregistered(em, in.Slug, in.Actor, tool)
				}
				if att.Err != nil {
					log.Printf("aaw: advisory: attribution for %q on %s failed after the ledger append: %v", in.Actor, id, att.Err)
				}
				if stream == "complete" {
					evaluateFormation(sc, em, loadPolicy(st.Workspace), time.Now().UTC())
				}
				return nil, &EntryOut{Ok: true, Entry: id, Path: sc.LedgerPath()}, nil
			})
	}

	return server
}

// bindLocalhost binds BOTH loopback families all-or-nothing (MCP4-D2,
// MCP4-INV1): a localhost client may dial ::1 first, and a single-family
// listener refuses it (the dual-stack loopback mismatch) — so a family that
// cannot be bound closes anything already bound and refuses with the
// reserved PORT_BUSY constant, the one capped holder probe appended. The
// error renders the contract form through the boot logger's "aaw: %v" prefix
// (the lock.go:44 INSTANCE_LOCKED precedent). No automatic port hunting: a
// server that silently moves breaks its own wire contract.
func bindLocalhost(port string) ([]net.Listener, error) {
	var listeners []net.Listener
	for _, hp := range []struct{ net, addr string }{{"tcp4", "127.0.0.1:" + port}, {"tcp6", "[::1]:" + port}} {
		l, err := net.Listen(hp.net, hp.addr)
		if err != nil {
			for _, bound := range listeners {
				bound.Close()
			}
			return nil, fmt.Errorf("%s: %s %s could not be bound (%v); %s", gates.PORT_BUSY, hp.net, hp.addr, err, probeHolder(port))
		}
		listeners = append(listeners, l)
	}
	return listeners, nil
}

// probeHolder is the one capped (~500 ms) MCP probe of the occupied port
// (MCP4-D2) — refusal-path only, never a pre-bind check: an aaw holder
// answers probe with its workspace + version; anything else earns lsof
// guidance.
func probeHolder(port string) string {
	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
	defer cancel()
	foreign := fmt.Sprintf("the holder is not an answering aaw instance — diagnose with: lsof -nP -iTCP:%s -sTCP:LISTEN", port)
	client := mcp.NewClient(&mcp.Implementation{Name: "aaw-portprobe", Version: version}, nil)
	// The cap is enforced at the HTTP layer too: a silent holder that
	// accepts but never answers would otherwise hang the request past the
	// ctx deadline. One shot, no retries, no standalone SSE — ONE capped
	// probe, as the contract reads.
	session, err := client.Connect(ctx, &mcp.StreamableClientTransport{
		Endpoint:             "http://localhost:" + port + "/",
		HTTPClient:           &http.Client{Timeout: 500 * time.Millisecond},
		MaxRetries:           -1,
		DisableStandaloneSSE: true,
	}, nil)
	if err != nil {
		return foreign
	}
	defer session.Close(ctx)
	res, err := session.CallTool(ctx, &mcp.CallToolParams{Name: "probe", Arguments: map[string]any{}})
	if err != nil || res.IsError {
		return foreign
	}
	var out struct {
		Name      string `json:"name"`
		Version   string `json:"version"`
		Workspace string `json:"workspace"`
	}
	b, err := json.Marshal(res.StructuredContent)
	if err != nil || json.Unmarshal(b, &out) != nil || out.Name != "aaw" {
		return foreign
	}
	return fmt.Sprintf("the port is held by an aaw instance (workspace %s, version %s)", out.Workspace, out.Version)
}

// wireRefuses is the strict-mode refusal rule (MCP4-D3): only strict
// refuses, and only on mismatch/unparseable — absent never refuses (a fresh
// workspace with no .mcp.json boots clean), so the served verdict mismatch
// is reachable only under warn (MCP4-INV3).
func wireRefuses(mode, verdict string) bool {
	return mode == config.WireCheckStrict && (verdict == config.WireMismatch || verdict == config.WireUnparseable)
}

// wireFix renders the strict-refusal remedy in both directions (MCP4-D3):
// edit the committed entry to the bound address, or re-flag -addr to the
// committed entry — falling back to a repair direction when no committed
// host:port parsed (the unparseable verdict).
func wireFix(workspace, boundAddr, committed string) string {
	fix := fmt.Sprintf("fix one direction: edit %s mcpServers.aaw.url to \"http://%s/\"", filepath.Join(workspace, ".mcp.json"), boundAddr)
	if committed != "" {
		return fix + fmt.Sprintf(", or re-boot with -addr %s to match the committed entry", committed)
	}
	return fix + ", or repair the entry to a parseable url and re-boot"
}

// bannerLine is one boot banner line (MCP4-D5): the listener, the wire
// verdict, and the resolved absolute workspace — the whole boot surface in
// one read.
func bannerLine(listenAddr, workspace, wireVerdict string) string {
	return fmt.Sprintf("aaw %s listening on http://%s/ (workspace %s, wire_contract %s)", version, listenAddr, workspace, wireVerdict)
}

func runServer() {
	st, err := store.Open(flags.Workspace)
	if err != nil {
		log.Fatalf("aaw: opening workspace: %v", err)
	}
	// One instance per workspace (MCP1-D5): the flock is held for the process
	// lifetime; a second boot exits non-zero with INSTANCE_LOCKED.
	lk, err := store.AcquireInstanceLock(st.Workspace)
	if err != nil {
		log.Fatalf("aaw: %v", err)
	}
	lvl, err := config.SlogLevel(flags.LogLevel)
	if err != nil {
		log.Fatalf("aaw: %v", err) // unreachable past main()'s validation
	}
	logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: lvl}))
	boot := &bootInfo{startedAt: store.Now()}
	server := newServer(st, lk, boot, logger)

	if flags.Stdio {
		// The stdio transport is a development convenience, not a contract
		// (AD-1): no listener exists, so the wire check has no bound address
		// to validate against — the verdict is skipped, never fabricated.
		boot.wire = config.WireSkipped
		log.Printf("aaw %s serving on stdio (workspace %s, wire_contract %s)", version, st.Workspace, boot.wire)
		if err := server.Run(context.Background(), &mcp.StdioTransport{}); err != nil {
			log.Fatalf("aaw: %v", err)
		}
		return
	}

	handler := mcp.NewStreamableHTTPHandler(func(*http.Request) *mcp.Server { return server }, &mcp.StreamableHTTPOptions{Logger: logger})

	var listeners []net.Listener
	host, port, err := net.SplitHostPort(flags.Addr)
	if err != nil {
		log.Fatalf("aaw: bad -addr %q: %v", flags.Addr, err)
	}
	if host == "localhost" {
		listeners, err = bindLocalhost(port)
		if err != nil {
			log.Fatalf("aaw: %v", err)
		}
	} else {
		l, err := net.Listen("tcp", flags.Addr)
		if err != nil {
			log.Fatalf("aaw: listen %s: %v", flags.Addr, err)
		}
		listeners = append(listeners, l)
	}

	// The wire check (MCP4-D3): validate the committed .mcp.json aaw entry
	// against the bound address; strict refuses mismatch/unparseable with the
	// fix printed in both directions; warn proceeds loudly. The file is never
	// generated or edited (MCP4-INV3).
	verdict, detail, committed := config.WireCheck(st.Workspace, flags.Addr, flags.WireCheck)
	boot.wire = verdict
	if wireRefuses(flags.WireCheck, verdict) {
		for _, l := range listeners {
			l.Close()
		}
		log.Fatalf("aaw: %v", fmt.Errorf("%s: %s; %s", gates.WIRE_MISMATCH, detail, wireFix(st.Workspace, flags.Addr, committed)))
	}
	if flags.WireCheck == config.WireCheckWarn && (verdict == config.WireMismatch || verdict == config.WireUnparseable) {
		log.Printf("aaw: WARNING: wire contract %s: %s (boot proceeds under -wire-check warn)", verdict, detail)
	}

	for _, l := range listeners {
		boot.listeners = append(boot.listeners, l.Addr().String())
	}
	errc := make(chan error, len(listeners))
	for _, l := range listeners {
		log.Printf("%s", bannerLine(l.Addr().String(), st.Workspace, verdict))
		go func(l net.Listener) { errc <- http.Serve(l, handler) }(l)
	}
	log.Fatalf("aaw: %v", <-errc)
}

// runSelftest connects to a running server as an MCP client and proves the
// registration + a full ledger round-trip — the "registered without errors"
// gate, run rather than claimed.
func runSelftest() {
	ctx := context.Background()
	client := mcp.NewClient(&mcp.Implementation{Name: "aaw-selftest", Version: version}, nil)
	var session *mcp.ClientSession
	var err error
	for attempt := 1; attempt <= 5; attempt++ {
		session, err = client.Connect(ctx, &mcp.StreamableClientTransport{Endpoint: "http://" + flags.Addr + "/"}, nil)
		if err == nil {
			break
		}
		time.Sleep(300 * time.Millisecond)
	}
	if err != nil {
		log.Fatalf("selftest: connect: %v", err)
	}
	defer session.Close(ctx)

	tools, err := session.ListTools(ctx, nil)
	if err != nil {
		log.Fatalf("selftest: tools/list: %v", err)
	}
	if got, want := len(tools.Tools), 18; got != want {
		log.Fatalf("selftest: tools/list returned %d tools, want %d", got, want)
	}

	textOf := func(res *mcp.CallToolResult) string {
		detail := ""
		for _, c := range res.Content {
			if t, ok := c.(*mcp.TextContent); ok {
				detail += t.Text
			}
		}
		return detail
	}
	call := func(name string, args map[string]any) *mcp.CallToolResult {
		res, err := session.CallTool(ctx, &mcp.CallToolParams{Name: name, Arguments: args})
		if err != nil {
			log.Fatalf("selftest: %s transport error: %v", name, err)
		}
		return res
	}
	callOK := func(name string, args map[string]any) *mcp.CallToolResult {
		res := call(name, args)
		if res.IsError {
			log.Fatalf("selftest: %s refused: %s", name, textOf(res))
		}
		return res
	}
	// callCode asserts the EXACT closed-set code (MCP3-D5), not IsError
	// alone: the code is the contract, the detail is prose.
	callCode := func(name string, args map[string]any, code string) {
		res := call(name, args)
		if !res.IsError {
			log.Fatalf("selftest: %s succeeded, want the %s refusal", name, code)
		}
		if text := textOf(res); !strings.HasPrefix(text, "aaw: "+code+": ") {
			log.Fatalf("selftest: %s refused with %q, want code %s", name, text, code)
		}
	}

	// The ledger dir derives from probe.workspace (MCP3-D8): the containment
	// gate refuses out-of-root paths at the door, so an os.MkdirTemp("", …)
	// dir can no longer be init'd — it becomes the PATH_ESCAPE assertion
	// below instead. Same-host as the server, as before (the dir is created
	// and removed client-side).
	var probe struct {
		Workspace string `json:"workspace"`
	}
	b, err := json.Marshal(callOK("probe", map[string]any{}).StructuredContent)
	if err != nil {
		log.Fatalf("selftest: %v", err)
	}
	if err := json.Unmarshal(b, &probe); err != nil || probe.Workspace == "" {
		log.Fatalf("selftest: probe returned no workspace (%v): %s", err, b)
	}
	dir := filepath.Join(probe.Workspace, ".aaw", "selftest")
	// Pre-clean: a re-run (or a prior aborted run) must start from an empty
	// ledger so Z-before-D refuses again.
	os.RemoveAll(dir)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		log.Fatalf("selftest: %v", err)
	}
	defer os.RemoveAll(dir)
	outside, err := os.MkdirTemp("", "aaw-selftest-*")
	if err != nil {
		log.Fatalf("selftest: %v", err)
	}
	defer os.RemoveAll(outside)
	scope := "aaw-selftest"

	// The selftest stays SIGNAL-SILENT by design: one attributed write (under
	// signals.ThresholdK), a registered actor only, register matching spawn,
	// refusals before any row or file is created — so a run against a live
	// server appends nothing to its .claude/audit.log.
	callOK("aaw_init", map[string]any{"scope": scope, "operator": "selftest", "ledger_dir": dir})
	callCode("aaw_init", map[string]any{"scope": scope + "-escape", "operator": "selftest", "ledger_dir": outside}, gates.PATH_ESCAPE) // the old out-of-root form, refused at the door
	callOK("aaw_spawn", map[string]any{"scope": scope, "role": "director", "name": "director"})
	callOK("agent_register", map[string]any{"scope": scope, "name": "director", "role": "director"})
	callOK("agent_heartbeat", map[string]any{"scope": scope, "name": "director", "quiet_for_minutes": 5})
	callCode("tool_x_complete", map[string]any{"task_id": scope, "slug": scope, "body": "Z-0 — premature"}, gates.GATE_Z_REQUIRES_D) // Z before D must refuse
	callOK("tool_x_trace", map[string]any{"task_id": scope, "slug": scope, "body": "T-1 — selftest trace\n\nround-trip body", "actor": "director"})
	callOK("tool_x_decision", map[string]any{"task_id": scope, "slug": scope, "body": "D-1 — selftest decision\n\nlocked"})
	callOK("tool_x_complete", map[string]any{"task_id": scope, "slug": scope, "body": "Z-1 — selftest complete\n\ndone"})
	callOK("aaw_status", map[string]any{"scope": scope})

	fmt.Printf("SELFTEST PASS: 18 tools registered at http://%s/; ledger round-trip ok (T→D→Z; exact-code refusals GATE_Z_REQUIRES_D + PATH_ESCAPE; ledger dir under probe.workspace; heartbeat + attributed write ok)\n", flags.Addr)
}
