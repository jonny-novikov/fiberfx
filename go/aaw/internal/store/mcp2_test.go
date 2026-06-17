package store

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/jonny-novikov/aaw/internal/signals"
)

// MCP2-INV1 golden: over both hand-written exemplar ledgers, the same append
// with and without `actor` produces BYTE-IDENTICAL ledger files — attribution
// is registry-side only, and the registry row is the only thing that moves.
func TestAttributedAppendByteIdentity(t *testing.T) {
	for _, scope := range []string{"emq-design", "aaw-mcp"} {
		t.Run(scope, func(t *testing.T) {
			src, err := os.ReadFile(filepath.Join("testdata", scope+".progress.md"))
			if err != nil {
				t.Fatal(err)
			}
			plain := &Scope{Name: scope, LedgerDir: t.TempDir()}
			attributed := &Scope{Name: scope, LedgerDir: t.TempDir()}
			for _, sc := range []*Scope{plain, attributed} {
				if err := os.WriteFile(sc.LedgerPath(), src, 0o644); err != nil {
					t.Fatal(err)
				}
			}
			reg := &Registry{Scope: scope, Agents: []*Agent{{Name: "Mars", Role: "implementor", Spawned: true}}}
			b, err := json.MarshalIndent(reg, "", "  ")
			if err != nil {
				t.Fatal(err)
			}
			if err := os.WriteFile(attributed.RegistryPath(), b, 0o644); err != nil {
				t.Fatal(err)
			}

			const body = "T-0 — byte-identity probe\n\nsame bytes either way"
			idPlain, err := plain.Append("trace", body)
			if err != nil {
				t.Fatal(err)
			}
			idAttr, att, err := attributed.AppendAttributed("trace", body, "Mars")
			if err != nil {
				t.Fatal(err)
			}
			if idPlain != idAttr {
				t.Fatalf("ids diverged: %s vs %s", idPlain, idAttr)
			}
			if !att.Recorded || att.Unregistered || att.Err != nil {
				t.Fatalf("attribution not recorded: %+v", att)
			}

			lp, err := os.ReadFile(plain.LedgerPath())
			if err != nil {
				t.Fatal(err)
			}
			la, err := os.ReadFile(attributed.LedgerPath())
			if err != nil {
				t.Fatal(err)
			}
			if !bytes.Equal(lp, la) {
				t.Fatal("ledger bytes differ with vs without actor")
			}

			r, err := attributed.LoadRegistry()
			if err != nil {
				t.Fatal(err)
			}
			a := r.Find("Mars")
			if a.Activity["T"] != 1 {
				t.Fatalf("per-prefix counter = %v, want T:1", a.Activity)
			}
			if len(a.AttributedAt) != 1 || a.LastSeenAt == "" {
				t.Fatalf("liveness evidence missing: attributed_at=%v last_seen_at=%q", a.AttributedAt, a.LastSeenAt)
			}
		})
	}
}

// MCP2-D1: an unregistered actor's write proceeds and creates NO registry
// row; the advisory line is the tool layer's job (the wire test pins it).
func TestAttributedAppendUnregisteredCreatesNoRow(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "ghostly")
	id, att, err := sc.AppendAttributed("trace", "T-0 — ghost write", "Ghost")
	if err != nil {
		t.Fatal(err)
	}
	if id != "T-1" {
		t.Fatalf("write did not proceed: id=%s", id)
	}
	if !att.Unregistered || att.Recorded {
		t.Fatalf("attribution outcome: %+v, want Unregistered", att)
	}
	r, err := sc.LoadRegistry()
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Agents) != 0 {
		t.Fatalf("a row was created for the unregistered actor: %v", r.Agents)
	}
}

// MCP2-D5 / MCP2-US5: the durable audit record LEADS — with the registry side
// failing (corrupt file), the attributed append still lands the ledger entry,
// reports the registry failure as advisory, and leaves the Operator's
// recoverable registry bytes untouched. The success-path counter advance is
// pinned by the byte-identity golden above; the crash-window drift between
// the two files is bounded and advisory, detected by the later `aaw audit`
// tally-recount.
func TestAttributedWriteLedgerLeads(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "order")
	if err := os.WriteFile(sc.RegistryPath(), []byte("{not json"), 0o644); err != nil {
		t.Fatal(err)
	}
	id, att, err := sc.AppendAttributed("decision", "D-0 — durable record leads", "Mars")
	if err != nil {
		t.Fatalf("the ledger write must not refuse over the advisory side: %v", err)
	}
	if id != "D-1" {
		t.Fatalf("id = %s, want D-1", id)
	}
	if att.Err == nil || att.Recorded {
		t.Fatalf("registry failure not surfaced as advisory: %+v", att)
	}
	b, err := os.ReadFile(sc.LedgerPath())
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(b), "### D-1 — durable record leads") {
		t.Fatal("ledger entry did not land")
	}
	raw, err := os.ReadFile(sc.RegistryPath())
	if err != nil {
		t.Fatal(err)
	}
	if string(raw) != "{not json" {
		t.Fatalf("the corrupt registry was clobbered: %q", raw)
	}
}

// MCP2-INV2, the Q-4 property: the three-source fusion. A peer advancing only
// its deliverable mtime reads active with ZERO tool calls; an unexpired
// declared-quiet window reads quiet-declared; neither reads stale — each with
// the winning source named.
func TestLivenessThreeSourceFusion(t *testing.T) {
	dir := t.TempDir()
	sc := &Scope{Name: "fusion", LedgerDir: dir, Workspace: dir}
	now := time.Now().UTC()
	stamp := func(d time.Duration) string { return now.Add(d).Format(time.RFC3339) }

	deliverable := filepath.Join(dir, "design.md")
	if err := os.WriteFile(deliverable, []byte("draft"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.Chtimes(deliverable, now, now); err != nil {
		t.Fatal(err)
	}

	cases := []struct {
		name            string
		agent           *Agent
		verdict, source string
	}{
		{"deliverable mtime advanced, zero calls", &Agent{Name: "a", LastSeenAt: stamp(-2 * time.Hour), Deliverable: deliverable}, VerdictActive, SourceDeliverableMtime},
		{"deliverable relative to the workspace", &Agent{Name: "a2", LastSeenAt: stamp(-2 * time.Hour), Deliverable: "design.md"}, VerdictActive, SourceDeliverableMtime},
		{"unexpired declared-quiet window", &Agent{Name: "b", LastSeenAt: stamp(-2 * time.Hour), QuietUntil: stamp(30 * time.Minute)}, VerdictQuietDeclared, SourceQuietWindow},
		{"fresh touch", &Agent{Name: "c", LastSeenAt: stamp(-time.Minute)}, VerdictActive, SourceTouch},
		{"no recent source", &Agent{Name: "d", LastSeenAt: stamp(-2 * time.Hour), QuietUntil: stamp(-time.Hour)}, VerdictStale, SourceTouch},
		{"no evidence at all", &Agent{Name: "e"}, VerdictStale, SourceNone},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			v, s := sc.Liveness(tc.agent, signals.WindowW, now)
			if v != tc.verdict || s != tc.source {
				t.Fatalf("verdict/source = %s/%s, want %s/%s", v, s, tc.verdict, tc.source)
			}
		})
	}

	// The fusion picks the MOST RECENT source: a stale deliverable under a
	// fresh touch names the touch, and vice versa.
	stale := filepath.Join(dir, "old.md")
	if err := os.WriteFile(stale, []byte("old"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.Chtimes(stale, now.Add(-3*time.Hour), now.Add(-3*time.Hour)); err != nil {
		t.Fatal(err)
	}
	if v, s := sc.Liveness(&Agent{Name: "f", LastSeenAt: stamp(-time.Minute), Deliverable: stale}, signals.WindowW, now); v != VerdictActive || s != SourceTouch {
		t.Fatalf("most-recent rule: %s/%s, want active/touch", v, s)
	}
}

// MCP2-D2: agent_heartbeat's store half — the touch, the persisted quiet
// window and note, and the refusal on a missing row (heartbeat targets an
// existing registry row; it never creates one).
func TestHeartbeat(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "beat")
	if _, err := sc.Heartbeat("nobody", "", 0); err == nil || !strings.Contains(err.Error(), "not found") {
		t.Fatalf("missing row not refused: %v", err)
	}
	if _, err := sc.SpawnAgent("director", "director", "", "", "", ""); err != nil {
		t.Fatal(err)
	}
	a, err := sc.Heartbeat("director", "authoring the design", 30*time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	if a.Note != "authoring the design" {
		t.Fatalf("note = %q", a.Note)
	}
	qu, err := time.Parse(time.RFC3339, a.QuietUntil)
	if err != nil {
		t.Fatalf("quiet_until %q: %v", a.QuietUntil, err)
	}
	if d := time.Until(qu); d < 28*time.Minute || d > 31*time.Minute {
		t.Fatalf("quiet window = %v from now, want ~30m", d)
	}
	now := time.Now().UTC()
	if v, s := sc.Liveness(a, signals.WindowW, now); v != VerdictQuietDeclared || s != SourceQuietWindow {
		t.Fatalf("heartbeat row reads %s/%s, want quiet-declared/quiet-window", v, s)
	}
	// A plain touch (no window) leaves quiet_until alone and refreshes the row.
	b, err := sc.Heartbeat("director", "", 0)
	if err != nil {
		t.Fatal(err)
	}
	if b.QuietUntil != a.QuietUntil {
		t.Fatalf("zero-window heartbeat moved quiet_until: %q -> %q", a.QuietUntil, b.QuietUntil)
	}
}

// MCP2-D2: the spawn-declared deliverable is recorded; a re-spawn with no
// deliverable keeps the recorded one (one identity across resumed passes).
func TestSpawnRecordsDeliverable(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "spawn-d")
	dirID, err := sc.SpawnAgent("director", "director", "", "", "", "")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := sc.SpawnAgent("Venus", "architect", "", dirID, "docs/design.md", ""); err != nil {
		t.Fatal(err)
	}
	r, err := sc.LoadRegistry()
	if err != nil {
		t.Fatal(err)
	}
	if got := r.Find("Venus").Deliverable; got != "docs/design.md" {
		t.Fatalf("deliverable = %q", got)
	}
	if _, err := sc.SpawnAgent("Venus", "architect", "", dirID, "", ""); err != nil {
		t.Fatal(err)
	}
	r, err = sc.LoadRegistry()
	if err != nil {
		t.Fatal(err)
	}
	if got := r.Find("Venus").Deliverable; got != "docs/design.md" {
		t.Fatalf("re-spawn dropped the deliverable: %q", got)
	}
}
