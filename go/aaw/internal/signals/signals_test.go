package signals

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"time"
)

// The policy defaults are spec-pinned (MCP2 D-6): W=45min, K=3, cap=240min.
func TestPolicyConstants(t *testing.T) {
	if WindowW != 45*time.Minute {
		t.Fatalf("WindowW = %v, want 45m", WindowW)
	}
	if ThresholdK != 3 {
		t.Fatalf("ThresholdK = %d, want 3", ThresholdK)
	}
	if QuietCapMinutes != 240 {
		t.Fatalf("QuietCapMinutes = %d, want 240", QuietCapMinutes)
	}
}

func readLines(t *testing.T, path string) []string {
	t.Helper()
	b, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		t.Fatal(err)
	}
	return strings.Split(strings.TrimRight(string(b), "\n"), "\n")
}

// MCP2-D4: the fixed line format
// `<RFC3339> aaw <CODE> scope=<scope> <k>=<v>… msg="<evidence>"`, the dedup
// rule (one line per (scope, code, evidence-window)), and Open returning only
// unexpired signals.
func TestEmitFormatDedupAndOpen(t *testing.T) {
	ws := t.TempDir()
	e := NewEmitter(ws)
	if want := filepath.Join(ws, ".claude", "audit.log"); e.Path() != want {
		t.Fatalf("emitter path = %s, want %s", e.Path(), want)
	}
	now := time.Date(2026, 6, 11, 12, 0, 0, 0, time.UTC)

	ok, err := e.Emit(now, "alpha", CodeFakeN, []KV{{Key: "registered", Val: "2"}, {Key: "spawned", Val: "1"}}, `registered 2 > spawned 1 with "quotes"
and a newline`)
	if err != nil || !ok {
		t.Fatalf("first emit: ok=%v err=%v", ok, err)
	}
	lines := readLines(t, e.Path())
	if len(lines) != 1 {
		t.Fatalf("lines = %d, want 1", len(lines))
	}
	lineRe := regexp.MustCompile(`^2026-06-11T12:00:00Z aaw FAKE-N scope=alpha registered=2 spawned=1 msg="[^"]*"$`)
	if !lineRe.MatchString(lines[0]) {
		t.Fatalf("line format mismatch: %q", lines[0])
	}

	// Same (scope, code) inside the evidence window: suppressed.
	if ok, err := e.Emit(now.Add(WindowW-time.Minute), "alpha", CodeFakeN, nil, "again"); err != nil || ok {
		t.Fatalf("dedup did not suppress: ok=%v err=%v", ok, err)
	}
	// A different code or scope in the same window: its own line.
	if ok, _ := e.Emit(now, "alpha", CodeVSolo1, nil, "other code"); !ok {
		t.Fatal("different code was deduped")
	}
	if ok, _ := e.Emit(now, "beta", CodeFakeN, nil, "other scope"); !ok {
		t.Fatal("different scope was deduped")
	}
	// Past the window: re-emits.
	if ok, _ := e.Emit(now.Add(WindowW), "alpha", CodeFakeN, nil, "next window"); !ok {
		t.Fatal("emission past the window was deduped")
	}
	if got := len(readLines(t, e.Path())); got != 4 {
		t.Fatalf("audit lines = %d, want 4", got)
	}

	// Open: alpha holds two codes inside their windows shortly after now (the
	// re-emitted FAKE-N's instant is now+W, still unexpired then).
	open := e.Open("alpha", now.Add(time.Minute))
	if len(open) != 2 {
		t.Fatalf("open signals = %d, want 2 (%v)", len(open), open)
	}
	// Far past every window: nothing open.
	if open := e.Open("alpha", now.Add(3*WindowW)); len(open) != 0 {
		t.Fatalf("expired signals still open: %v", open)
	}
}

func evidence(role string, stale bool, attributed ...time.Time) AgentEvidence {
	return AgentEvidence{Role: role, Stale: stale, AttributedAt: attributed}
}

// MCP2-INV4: V-SOLO-1 requires BOTH clauses — all non-director rows stale AND
// >= ThresholdK director-attributed entries within WindowW.
func TestVSolo1TwoClause(t *testing.T) {
	now := time.Date(2026, 6, 11, 12, 0, 0, 0, time.UTC)
	recent := []time.Time{now.Add(-time.Minute), now.Add(-2 * time.Minute), now.Add(-3 * time.Minute)}
	old := []time.Time{now.Add(-2 * WindowW), now.Add(-3 * WindowW), now.Add(-4 * WindowW)}

	cases := []struct {
		name string
		rows []AgentEvidence
		want bool
	}{
		{"both clauses true", []AgentEvidence{evidence("director", false, recent...), evidence("implementor", true)}, true},
		{"a peer not stale", []AgentEvidence{evidence("director", false, recent...), evidence("implementor", false), evidence("architect", true)}, false},
		{"director under threshold", []AgentEvidence{evidence("director", false, recent[:ThresholdK-1]...), evidence("implementor", true)}, false},
		{"director entries outside the window", []AgentEvidence{evidence("director", false, old...), evidence("implementor", true)}, false},
		{"quiet whole team, no director growth", []AgentEvidence{evidence("director", false), evidence("implementor", false), evidence("architect", false)}, false},
		{"no peers spawned, director churning (vacuous first clause)", []AgentEvidence{evidence("director", false, recent...)}, true},
		{"director casing folds", []AgentEvidence{evidence("Director", false, recent...), evidence("implementor", true)}, true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			fires, _, _ := VSolo1(tc.rows, now, WindowW, ThresholdK)
			if fires != tc.want {
				t.Fatalf("fires = %v, want %v", fires, tc.want)
			}
		})
	}

	fires, stale, entries := VSolo1([]AgentEvidence{evidence("director", false, recent...), evidence("implementor", true), evidence("architect", true)}, now, WindowW, ThresholdK)
	if !fires || stale != 2 || entries != 3 {
		t.Fatalf("evidence counts: fires=%v stale=%d entries=%d, want true/2/3", fires, stale, entries)
	}
}

// The W-1 adjudication's computation: V-SOLO-2 is true exactly when
// attributed entries exist and all of them are the director's.
func TestVSolo2Computation(t *testing.T) {
	now := time.Now().UTC()
	if !VSolo2([]AgentEvidence{evidence("director", false, now), evidence("implementor", true)}) {
		t.Fatal("degraded run (director-only attributions) not computed true")
	}
	if VSolo2([]AgentEvidence{evidence("director", false, now), evidence("implementor", false, now)}) {
		t.Fatal("mixed attributions computed as degraded")
	}
	if VSolo2([]AgentEvidence{evidence("director", false), evidence("implementor", true)}) {
		t.Fatal("zero attributions computed as degraded")
	}
}
