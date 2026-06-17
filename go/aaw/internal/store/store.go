// Package store holds the aaw server's durable state: the workspace-level
// scope index, the per-scope registry (agents, messages), and the per-scope
// single-file ledger (ledger.go). Files are the source of record; the server
// keeps no state that cannot be rebuilt from them.
//
// The single-writer discipline (MCP1): the index is read-through — every
// lookup re-reads .aaw/scopes.json under the store lock, every mutation
// read-merge-writes the single row (ADR-1); all writes to a scope's ledger,
// registry, and messages serialize under one per-scope mutex (ADR-3); every
// whole-file write is temp+fsync+rename (ADR-4); CCL-ids mint from the
// registry's persisted next_ccl counter (ADR-22). No lock nests except
// store→scope.
package store

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/jonny-novikov/aaw/internal/gates"
)

// SlugRe is the scope/slug rule: lowercase alphanumeric + dashes, no dots.
var SlugRe = regexp.MustCompile(`^[a-z0-9][a-z0-9-]*$`)

// Scope is one row of the workspace scope index.
type Scope struct {
	Name      string `json:"name"`
	Operator  string `json:"operator"`
	Workspace string `json:"workspace"`
	LedgerDir string `json:"ledger_dir"`
	TTLDays   int    `json:"ttl_days"`
	CreatedAt string `json:"created_at"`
}

// Agent is one registry row. The MCP2 fields are all additive: Model (LAW-2
// record-only evidence, no behavior), Deliverable (the spawn-declared
// liveness file), QuietUntil/Note (agent_heartbeat), Activity (the per-prefix
// attributed-entry counter) and AttributedAt (the bounded recent
// attributed-entry instants feeding the V-SOLO clauses).
type Agent struct {
	Name         string         `json:"name"`
	Role         string         `json:"role"`
	Model        string         `json:"model,omitempty"`
	Archetype    string         `json:"archetype,omitempty"`
	CCLID        string         `json:"ccl_id,omitempty"`
	ParentID     string         `json:"parent_id,omitempty"`
	Spawned      bool           `json:"spawned"`
	Registered   bool           `json:"registered"`
	SpawnedAt    string         `json:"spawned_at,omitempty"`
	RegisteredAt string         `json:"registered_at,omitempty"`
	LastSeenAt   string         `json:"last_seen_at,omitempty"`
	Deliverable  string         `json:"deliverable,omitempty"`
	QuietUntil   string         `json:"quiet_until,omitempty"`
	Note         string         `json:"note,omitempty"`
	Activity     map[string]int `json:"activity,omitempty"`
	AttributedAt []string       `json:"attributed_at,omitempty"`
}

// maxAttributedInstants bounds Agent.AttributedAt: enough recent instants to
// evaluate the V-SOLO-1 clause (ThresholdK within WindowW) with margin; the
// unbounded tally lives in Activity.
const maxAttributedInstants = 32

// Message is one agent_send record.
type Message struct {
	To   string `json:"to"`
	Body string `json:"body"`
	At   string `json:"at"`
}

// Registry is the per-scope agent/message state, persisted beside the ledger
// as <scope>.registry.json. NextCCL is the persisted CCL mint counter
// (MCP1-D2): the id space survives row churn, so an id is never re-minted.
type Registry struct {
	Scope    string    `json:"scope"`
	NextCCL  int       `json:"next_ccl"`
	Agents   []*Agent  `json:"agents"`
	Messages []Message `json:"messages"`
}

// Store is the server's root handle.
type Store struct {
	Workspace string

	mu sync.Mutex // guards the index file alone; scope files lock via lockFor
}

func now() string { return time.Now().UTC().Format(time.RFC3339) }

// Open binds the store to <workspace> and verifies any existing scope index
// parses. No index state is resident: every read is read-through per call
// (MCP1-D4), so out-of-band edits to .aaw/scopes.json are always honored.
func Open(workspace string) (*Store, error) {
	abs, err := filepath.Abs(workspace)
	if err != nil {
		return nil, err
	}
	s := &Store{Workspace: abs}
	if _, err := s.readIndex(); err != nil {
		return nil, err
	}
	return s, nil
}

func (s *Store) indexPath() string { return filepath.Join(s.Workspace, ".aaw", "scopes.json") }

// readIndex loads .aaw/scopes.json fresh (empty when absent). Callers other
// than Open hold s.mu.
func (s *Store) readIndex() (map[string]*Scope, error) {
	scopes := map[string]*Scope{}
	b, err := os.ReadFile(s.indexPath())
	if os.IsNotExist(err) {
		return scopes, nil
	}
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(b, &scopes); err != nil {
		return nil, gates.Errorf(gates.CORRUPT_STATE, "corrupt scope index %s: %w", s.indexPath(), err)
	}
	return scopes, nil
}

// writeIndex persists the merged row set atomically. Callers hold s.mu and
// pass a map freshly read in the same critical section, so a server write
// never clobbers an out-of-band edit to another row.
func (s *Store) writeIndex(scopes map[string]*Scope) error {
	if err := os.MkdirAll(filepath.Dir(s.indexPath()), 0o755); err != nil {
		return err
	}
	b, err := json.MarshalIndent(scopes, "", "  ")
	if err != nil {
		return err
	}
	return writeFileAtomic(s.indexPath(), b, 0o644)
}

// InitScope creates or idempotently re-opens a scope. ledgerDir is required on
// first init (the locked single-file model fixes the ledger location at init;
// by convention the scope's deliverable directory). A relative ledgerDir is
// resolved against the workspace and must be contained under it (MCP3-D8: an
// out-of-root first-init refuses PATH_ESCAPE before any row, dir, or file is
// created; an existing index row is honored as-is — no retro-refusal). Re-init
// with a different ledgerDir errors. The MCP3-D3 split: scopeCreated reports
// the index row was new (the v1 `created` meaning); ledgerCreated reports the
// ledger file was absent and a header written.
func (s *Store) InitScope(name, operator, ledgerDir string, ttlDays int) (*Scope, bool, bool, error) {
	if !SlugRe.MatchString(name) {
		return nil, false, false, gates.Errorf(gates.SLUG_INVALID, "scope %q violates the slug rule %s (lowercase alphanumeric + dashes, no dots)", name, SlugRe)
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	scopes, err := s.readIndex()
	if err != nil {
		return nil, false, false, err
	}
	if sc, ok := scopes[name]; ok {
		if ledgerDir != "" {
			if abs := s.resolve(ledgerDir); abs != sc.LedgerDir {
				return nil, false, false, gates.Errorf(gates.LEDGER_DIR_CONFLICT, "scope %q already initialized with ledger_dir=%s; re-init must omit ledger_dir or repeat it", name, sc.LedgerDir)
			}
		}
		return sc, false, false, nil
	}
	if ledgerDir == "" {
		return nil, false, false, gates.Errorf(gates.LEDGER_DIR_REQUIRED, "scope %q is new: ledger_dir is required at first aaw_init (convention: the scope's deliverable directory; the ledger is <ledger_dir>/%s.progress.md)", name, name)
	}
	dir, contained := gates.Contained(s.Workspace, ledgerDir)
	if !contained {
		return nil, false, false, gates.Errorf(gates.PATH_ESCAPE, "ledger_dir %q resolves to %s, outside the workspace root %s", ledgerDir, dir, s.Workspace)
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, false, false, err
	}
	sc := &Scope{Name: name, Operator: operator, Workspace: s.Workspace, LedgerDir: dir, TTLDays: ttlDays, CreatedAt: now()}
	// Create the ledger file only if absent — a hand-written ledger is
	// first-class input and is never touched at init. The write takes the
	// scope lock (store→scope, the one permitted nesting).
	ledgerCreated := false
	if err := func() error {
		mu := lockFor(name)
		mu.Lock()
		defer mu.Unlock()
		lp := sc.LedgerPath()
		if _, err := os.Stat(lp); os.IsNotExist(err) {
			head := fmt.Sprintf("# %s — AAW scope ledger\n", name)
			if werr := writeFileAtomic(lp, []byte(head), 0o644); werr != nil {
				return werr
			}
			ledgerCreated = true
		}
		return nil
	}(); err != nil {
		return nil, false, false, err
	}
	scopes[name] = sc
	if err := s.writeIndex(scopes); err != nil {
		return nil, false, false, err
	}
	return sc, true, ledgerCreated, nil
}

func (s *Store) resolve(dir string) string {
	if filepath.IsAbs(dir) {
		return filepath.Clean(dir)
	}
	return filepath.Join(s.Workspace, dir)
}

// GetScope returns an initialized scope or a uniform "not initialized" error.
// The row is read from disk per call: a row deleted out of band stays deleted
// (MCP1-INV3).
func (s *Store) GetScope(name string) (*Scope, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	scopes, err := s.readIndex()
	if err != nil {
		return nil, err
	}
	sc, ok := scopes[name]
	if !ok {
		return nil, gates.Errorf(gates.NOT_INITIALIZED, "scope %q not initialized — call aaw_init first (the single-file ledger has no derivable location before init)", name)
	}
	return sc, nil
}

// ScopeNames lists known scopes (for probe).
func (s *Store) ScopeNames() []string {
	s.mu.Lock()
	defer s.mu.Unlock()
	scopes, err := s.readIndex()
	if err != nil {
		return nil
	}
	names := make([]string, 0, len(scopes))
	for n := range scopes {
		names = append(names, n)
	}
	return names
}

// LedgerPath is <ledger_dir>/<scope>.progress.md.
func (sc *Scope) LedgerPath() string {
	return filepath.Join(sc.LedgerDir, sc.Name+".progress.md")
}

// RegistryPath is <ledger_dir>/<scope>.registry.json.
func (sc *Scope) RegistryPath() string {
	return filepath.Join(sc.LedgerDir, sc.Name+".registry.json")
}

// LoadRegistry reads the per-scope registry (empty if absent). Reads are
// lock-free: the atomic write discipline keeps every observed file whole.
func (sc *Scope) LoadRegistry() (*Registry, error) {
	r := &Registry{Scope: sc.Name}
	b, err := os.ReadFile(sc.RegistryPath())
	if os.IsNotExist(err) {
		return r, nil
	}
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(b, r); err != nil {
		return nil, gates.Errorf(gates.CORRUPT_STATE, "corrupt registry %s: %w", sc.RegistryPath(), err)
	}
	return r, nil
}

// saveRegistry persists the registry atomically. Callers hold the scope lock.
func (sc *Scope) saveRegistry(r *Registry) error {
	b, err := json.MarshalIndent(r, "", "  ")
	if err != nil {
		return err
	}
	return writeFileAtomic(sc.RegistryPath(), b, 0o644)
}

// updateRegistry runs one read-modify-write of the scope registry under the
// scope's writer lock (MCP1-D1: registry IO is never an unlocked RMW); fn
// returning an error abandons the write.
func (sc *Scope) updateRegistry(fn func(*Registry) error) error {
	mu := lockFor(sc.Name)
	mu.Lock()
	defer mu.Unlock()
	r, err := sc.LoadRegistry()
	if err != nil {
		return err
	}
	if err := fn(r); err != nil {
		return err
	}
	return sc.saveRegistry(r)
}

// mintCCL returns the next ccl-<scope>-<n>, advancing the persisted counter
// (MCP1-D2 / ADR-22). A registry from before the counter (next_ccl 0) seeds
// from the highest existing suffix + 1, so legacy rows — including historical
// duplicates — are never collided (MCP1-INV5).
func (r *Registry) mintCCL(scope string) string {
	if r.NextCCL <= 0 {
		r.NextCCL = 1
		prefix := "ccl-" + scope + "-"
		for _, a := range r.Agents {
			if !strings.HasPrefix(a.CCLID, prefix) {
				continue
			}
			if n, err := strconv.Atoi(a.CCLID[len(prefix):]); err == nil && n >= r.NextCCL {
				r.NextCCL = n + 1
			}
		}
	}
	id := fmt.Sprintf("ccl-%s-%d", scope, r.NextCCL)
	r.NextCCL++
	return id
}

// SpawnAgent records a spawn under the scope lock: the parent (by CCL-id)
// must exist except for the director; a first spawn mints from next_ccl; a
// re-spawn of an existing name keeps its CCL-id and refreshes spawned_at —
// one identity across resumed passes (MCP1-D1, MCP1-D2). deliverable is the
// spawn-declared liveness file (MCP2-D2): its mtime is the third liveness
// source. model is LAW-2 record-only evidence. Both follow the CCL-id
// continuity rule: empty on re-spawn keeps the recorded value.
func (sc *Scope) SpawnAgent(name, role, archetype, parentID, deliverable, model string) (string, error) {
	var cclID string
	err := sc.updateRegistry(func(r *Registry) error {
		if parentID != "" {
			found := false
			for _, a := range r.Agents {
				if a.CCLID == parentID {
					found = true
					break
				}
			}
			if !found {
				return gates.Errorf(gates.PARENT_NOT_FOUND, "parent_id %q not found in scope %q", parentID, sc.Name)
			}
		} else if !strings.EqualFold(role, "director") {
			// A required parameter is empty — ARG_MISSING, not PARENT_NOT_FOUND
			// (the MCP3-D2 site map).
			return gates.Errorf(gates.ARG_MISSING, "non-director role %q requires parent_id (the director's CCL-id)", role)
		}
		a := r.Find(name)
		if a == nil {
			a = &Agent{Name: name}
			r.Agents = append(r.Agents, a)
		}
		if a.CCLID == "" {
			a.CCLID = r.mintCCL(sc.Name)
		}
		cclID = a.CCLID
		a.Role, a.Archetype, a.ParentID = role, archetype, parentID
		if deliverable != "" {
			a.Deliverable = deliverable
		}
		if model != "" {
			a.Model = model
		}
		a.Spawned, a.SpawnedAt, a.LastSeenAt = true, now(), now()
		return nil
	})
	if err != nil {
		return "", err
	}
	return cclID, nil
}

// RegisterAgent records a registration under the scope lock and returns the
// spawn-vs-register tallies for the FAKE-N signal (MCP1-D1). model is LAW-2
// record-only evidence; empty keeps the stored value (the CCL-id continuity
// rule).
func (sc *Scope) RegisterAgent(name, role, cclID, model string) (spawned, registered int, err error) {
	err = sc.updateRegistry(func(r *Registry) error {
		a := r.Find(name)
		if a == nil {
			a = &Agent{Name: name}
			r.Agents = append(r.Agents, a)
		}
		a.Role = role
		if cclID != "" {
			a.CCLID = cclID
		}
		if model != "" {
			a.Model = model
		}
		a.Registered, a.RegisteredAt, a.LastSeenAt = true, now(), now()
		spawned, registered = r.Counts()
		return nil
	})
	return
}

// RecordMessage appends an agent_send record under the scope lock — the
// messages write shares the scope's single writer (MCP1-D1).
func (sc *Scope) RecordMessage(to, body string) error {
	return sc.updateRegistry(func(r *Registry) error {
		a := r.Find(to)
		if a == nil || !a.Registered {
			return gates.Errorf(gates.NOT_REGISTERED, "recipient %q is not registered in scope %q", to, sc.Name)
		}
		r.Messages = append(r.Messages, Message{To: to, Body: body, At: now()})
		r.Touch(to)
		return nil
	})
}

// Find returns the named agent row, or nil.
func (r *Registry) Find(name string) *Agent {
	for _, a := range r.Agents {
		if a.Name == name {
			return a
		}
	}
	return nil
}

// Touch updates last_seen_at on the named agent if present.
func (r *Registry) Touch(name string) {
	if a := r.Find(name); a != nil {
		a.LastSeenAt = now()
	}
}

// Counts returns (spawned, registered) tallies for the FAKE-N signal.
func (r *Registry) Counts() (spawned, registered int) {
	for _, a := range r.Agents {
		if a.Spawned {
			spawned++
		}
		if a.Registered {
			registered++
		}
	}
	return
}

// Now is exported for callers stamping registry rows.
func Now() string { return now() }

// The three-source liveness vocabulary (MCP2-D2): verdicts and the winning
// sources named on every status row.
const (
	VerdictActive        = "active"
	VerdictQuietDeclared = "quiet-declared"
	VerdictStale         = "stale"

	SourceTouch            = "touch"             // last_seen_at: attributed call, heartbeat, register, send
	SourceQuietWindow      = "quiet-window"      // an unexpired declared-quiet window
	SourceDeliverableMtime = "deliverable-mtime" // the spawn-declared deliverable advanced
	SourceNone             = "none"              // no evidence on the row at all
)

// Heartbeat is the agent_heartbeat write (MCP2-D2): a zero-ledger-cost touch
// of last_seen_at, an optional declared-quiet window, and an optional note,
// on an EXISTING registry row (lease-at-dispatch: the caller need not be the
// named agent — the director may heartbeat for a peer it dispatched). The
// quietFor cap is the tool boundary's job (signals.QuietCapMinutes).
func (sc *Scope) Heartbeat(name, note string, quietFor time.Duration) (*Agent, error) {
	var out Agent
	err := sc.updateRegistry(func(r *Registry) error {
		a := r.Find(name)
		if a == nil {
			return gates.Errorf(gates.AGENT_UNKNOWN, "agent %q not found in scope %q — agent_heartbeat touches an existing registry row (aaw_spawn or agent_register first)", name, sc.Name)
		}
		a.LastSeenAt = now()
		if note != "" {
			a.Note = note
		}
		if quietFor > 0 {
			a.QuietUntil = time.Now().UTC().Add(quietFor).Format(time.RFC3339)
		}
		out = *a
		return nil
	})
	if err != nil {
		return nil, err
	}
	return &out, nil
}

// TouchActor records the registry-side attribution of a non-ledger write
// (MCP2-D1): a name with a row advances last_seen_at only (registry writers
// carry no entry prefix, so no per-prefix counter moves); a name with no row
// reports unregistered=true and creates nothing — the caller emits the
// UNREGISTERED-ATTRIBUTION advisory.
func (sc *Scope) TouchActor(actor string) (unregistered bool, err error) {
	if actor == "" {
		return false, nil
	}
	mu := lockFor(sc.Name)
	mu.Lock()
	defer mu.Unlock()
	r, err := sc.LoadRegistry()
	if err != nil {
		return false, err
	}
	a := r.Find(actor)
	if a == nil {
		return true, nil
	}
	a.LastSeenAt = now()
	return false, sc.saveRegistry(r)
}

// Liveness fuses the three file-backed sources at read time (MCP2-D2, the
// Q-4 property): an unexpired declared-quiet window wins outright (it extends
// into the future); otherwise the most recent of {last_seen_at touch,
// deliverable mtime} within the window reads active; otherwise stale — with
// the winning (most recent) source named even on a stale row. window is the
// staleness horizon (signals.WindowW at the tool boundary). Evaluated only at
// aaw_status and Z-append — no background janitor.
func (sc *Scope) Liveness(a *Agent, window time.Duration, at time.Time) (verdict, source string) {
	if qu, err := time.Parse(time.RFC3339, a.QuietUntil); err == nil && qu.After(at) {
		return VerdictQuietDeclared, SourceQuietWindow
	}
	var best time.Time
	source = SourceNone
	if ts, err := time.Parse(time.RFC3339, a.LastSeenAt); err == nil && ts.After(best) {
		best, source = ts, SourceTouch
	}
	if a.Deliverable != "" {
		p := a.Deliverable
		if !filepath.IsAbs(p) {
			p = filepath.Join(sc.Workspace, p)
		}
		if fi, err := os.Stat(p); err == nil && fi.ModTime().UTC().After(best) {
			best, source = fi.ModTime().UTC(), SourceDeliverableMtime
		}
	}
	if !best.IsZero() && at.Sub(best) <= window {
		return VerdictActive, source
	}
	return VerdictStale, source
}

// AttributionInstants parses the row's bounded attributed-entry instants for
// the V-SOLO evidence; unparseable stamps are dropped.
func (a *Agent) AttributionInstants() []time.Time {
	var out []time.Time
	for _, s := range a.AttributedAt {
		if t, err := time.Parse(time.RFC3339, s); err == nil {
			out = append(out, t)
		}
	}
	return out
}

// Archived reports whether the scope's TTL hint has lapsed (created_at +
// ttl_days is past). TTL is an archival HINT — no rung enforces it; the flag
// only surfaces on the status console (MCP2-D3).
func (sc *Scope) Archived(at time.Time) bool {
	if sc.TTLDays <= 0 {
		return false
	}
	created, err := time.Parse(time.RFC3339, sc.CreatedAt)
	if err != nil {
		return false
	}
	return at.After(created.Add(time.Duration(sc.TTLDays) * 24 * time.Hour))
}
