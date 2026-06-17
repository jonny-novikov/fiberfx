// Package signals holds the advisory formation-signal contract (MCP2-D4):
// the policy constants, the closed signal-code set, the V-SOLO computations,
// and the deduplicated line emitter for <workspace>/.claude/audit.log.
//
// Every signal is advisory (MCP2-INV3): no emission, and no emission FAILURE,
// blocks a tool call — the only hard process gate remains tool_x_complete
// refused while no D-n is locked. V-SOLO-2 is computed but never emitted
// (the W-1 adjudication: the proposal's R-4 degraded run is legitimate
// history); its evidence stays registry-side.
package signals

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/jonny-novikov/aaw/internal/config"
)

// Policy defaults (Operator-tunable, D-6): the built-in layer under the
// .aaw/config.json read-through (MCP4-D1). The names stay; each value's one
// authority is internal/config. Live values load per evaluation via
// config.LoadPolicy and reach the consumers as parameters (VSolo1) or
// through the Emitter's own read-through (the dedup window).
const (
	// WindowW is the V-SOLO-1 silence window default: the staleness horizon
	// of the three-source liveness rule.
	WindowW = config.DefaultWindowW
	// ThresholdK is the director-activity threshold default: V-SOLO-1's
	// second clause requires at least this many director-attributed entries
	// within the window.
	ThresholdK = config.DefaultThresholdK
	// QuietCapMinutes is the default cap on agent_heartbeat's declared-quiet
	// window.
	QuietCapMinutes = config.DefaultQuietCapMinutes
)

// The closed signal-code set (MCP2-D4).
const (
	CodeFakeN                   = "FAKE-N"
	CodeVSolo1                  = "V-SOLO-1"
	CodeVSolo2                  = "V-SOLO-2" // computed, never emitted (W-1)
	CodeUnregisteredAttribution = "UNREGISTERED-ATTRIBUTION"
	CodeContainment             = "CONTAINMENT"
)

// KV is one ordered key=value pair of a signal line.
type KV struct {
	Key string
	Val string
}

// Signal is one emitted (or open) advisory signal.
type Signal struct {
	Scope string
	Code  string
	At    time.Time
	KVs   []KV
	Msg   string
}

// AgentEvidence is one registry row distilled for the V-SOLO computations:
// the role, the three-source staleness verdict, and the instants of the
// row's attributed ledger entries.
type AgentEvidence struct {
	Role         string
	Stale        bool
	AttributedAt []time.Time
}

func isDirector(role string) bool { return strings.EqualFold(role, "director") }

// VSolo1 evaluates the two-clause rule (MCP2-INV4): ALL non-director rows
// stale by the three-source rule AND >= k director-attributed entries within
// window of now — both required. window and k are the caller's per-evaluation
// policy read (MCP4-D1: config.LoadPolicy, defaults WindowW/ThresholdK). A
// quiet whole team (peers between stages, no director growth) fails the
// second clause and never signals; a scope with no non-director rows
// satisfies the first clause vacuously (a director churning entries with no
// peers spawned IS the solo formation the signal names).
func VSolo1(rows []AgentEvidence, now time.Time, window time.Duration, k int) (fires bool, staleRows, directorEntries int) {
	allStale := true
	for _, r := range rows {
		if isDirector(r.Role) {
			for _, at := range r.AttributedAt {
				if now.Sub(at) <= window {
					directorEntries++
				}
			}
			continue
		}
		if r.Stale {
			staleRows++
		} else {
			allStale = false
		}
	}
	return allStale && directorEntries >= k, staleRows, directorEntries
}

// VSolo2 computes the degraded-run evidence (the proposal's R-4): attributed
// ledger entries exist and every one of them belongs to a director row.
// Callers compute it and hold the result — never emit a line for it.
func VSolo2(rows []AgentEvidence) bool {
	total, director := 0, 0
	for _, r := range rows {
		total += len(r.AttributedAt)
		if isDirector(r.Role) {
			director += len(r.AttributedAt)
		}
	}
	return total > 0 && director == total
}

// Emitter appends advisory lines to <workspace>/.claude/audit.log with the
// dedup rule: one line per (scope, code, evidence-window) — a repeat within
// the dedup window of the previous emission for the same (scope, code) is
// suppressed. The window is the MCP4-D1 read-through knob (.aaw/config.json
// dedup_window_minutes, default WindowW), read on every evaluation. Dedup
// state is in-process; a restart may re-emit, which the advisory plane
// accepts. The log is line-granular, so writes use O_APPEND (not the
// whole-file atomic write).
type Emitter struct {
	workspace string
	path      string

	mu   sync.Mutex
	last map[string]Signal
}

// NewEmitter binds the emitter to a workspace root.
func NewEmitter(workspace string) *Emitter {
	return &Emitter{workspace: workspace, path: filepath.Join(workspace, ".claude", "audit.log"), last: map[string]Signal{}}
}

// Path is the audit-log location (for tests and diagnostics).
func (e *Emitter) Path() string { return e.path }

// dedupWindow is the per-evaluation policy read-through (MCP4-D1): a config
// parse failure yields the default layer — the advisory plane never blocks
// on policy.
func (e *Emitter) dedupWindow() time.Duration {
	pol, _ := config.LoadPolicy(e.workspace)
	return pol.DedupWindow
}

// Emit appends one line in the fixed format, unless deduplicated. The
// returned error is advisory: callers must not refuse a tool call on it
// (MCP2-INV3).
func (e *Emitter) Emit(now time.Time, scope, code string, kvs []KV, msg string) (bool, error) {
	e.mu.Lock()
	defer e.mu.Unlock()
	key := scope + "\x00" + code
	if prev, ok := e.last[key]; ok && now.Sub(prev.At) < e.dedupWindow() {
		return false, nil
	}
	if err := os.MkdirAll(filepath.Dir(e.path), 0o755); err != nil {
		return false, err
	}
	f, err := os.OpenFile(e.path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return false, err
	}
	defer f.Close()
	if _, err := f.WriteString(formatLine(now, scope, code, kvs, msg) + "\n"); err != nil {
		return false, err
	}
	e.last[key] = Signal{Scope: scope, Code: code, At: now, KVs: kvs, Msg: msg}
	return true, nil
}

// Open returns the scope's signals whose evidence window has not lapsed —
// the "open (unexpired) signals" of the status console.
func (e *Emitter) Open(scope string, now time.Time) []Signal {
	e.mu.Lock()
	defer e.mu.Unlock()
	window := e.dedupWindow()
	var out []Signal
	for _, s := range e.last {
		if s.Scope == scope && now.Sub(s.At) < window {
			out = append(out, s)
		}
	}
	return out
}

// formatLine renders `<RFC3339> aaw <CODE> scope=<scope> <k>=<v>… msg="<evidence>"`.
func formatLine(now time.Time, scope, code string, kvs []KV, msg string) string {
	var b strings.Builder
	fmt.Fprintf(&b, "%s aaw %s scope=%s", now.UTC().Format(time.RFC3339), code, scope)
	for _, kv := range kvs {
		fmt.Fprintf(&b, " %s=%s", kv.Key, kv.Val)
	}
	msg = strings.NewReplacer("\"", "'", "\n", " ", "\r", " ").Replace(msg)
	fmt.Fprintf(&b, " msg=%q", msg)
	return b.String()
}
