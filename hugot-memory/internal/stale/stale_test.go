package stale

import (
	"testing"

	"github.com/fiberfx/hugot-memory/internal/config"
	"github.com/fiberfx/hugot-memory/internal/graph"
)

type fakeSource struct {
	bodies   map[string][]byte
	headings map[string][]string
	exists   map[string]bool
}

func (f *fakeSource) Body(path string) ([]byte, error) {
	if b, ok := f.bodies[path]; ok {
		return b, nil
	}
	return nil, nil
}

func (f *fakeSource) HeadingSlugs(path string) ([]string, error) {
	if s, ok := f.headings[path]; ok {
		return s, nil
	}
	return nil, nil
}

func (f *fakeSource) Exists(path string) bool {
	return f.exists[path]
}

func newFake() *fakeSource {
	return &fakeSource{
		bodies:   make(map[string][]byte),
		headings: make(map[string][]string),
		exists:   make(map[string]bool),
	}
}

func TestRuleDeadTargetFlagsMissing(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "MEMORY.md", Type: graph.NodeIndex, Status: graph.StatusActive})
	g.AddEdge(graph.Edge{From: "MEMORY.md", To: "feedback_missing.md", Kind: graph.EdgeMDLink, SourceLine: 5, Snippet: "see [x](feedback_missing.md)"})
	g.ResolveEdges()

	src := newFake()
	src.bodies["MEMORY.md"] = []byte("see [x](feedback_missing.md)\n")
	cfg := config.Defaults()

	got := ruleDeadTarget(g, cfg, src)
	if len(got) != 1 {
		t.Fatalf("expected 1 finding, got %d: %+v", len(got), got)
	}
	if got[0].Severity != SeverityError {
		t.Errorf("severity=%s want error", got[0].Severity)
	}
}

func TestRuleDeadTargetWhitelistedSkipped(t *testing.T) {
	body := []byte("Old [reference](feedback_gone.md) was deleted in the 2026 refactor.\n")
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "MEMORY.md", Type: graph.NodeIndex, Status: graph.StatusActive})
	g.AddEdge(graph.Edge{From: "MEMORY.md", To: "feedback_gone.md", Kind: graph.EdgeMDLink, SourceLine: 1, Snippet: "deleted in the 2026 refactor"})
	g.ResolveEdges()

	src := newFake()
	src.bodies["MEMORY.md"] = body
	cfg := config.Defaults()

	got := ruleDeadTarget(g, cfg, src)
	if len(got) != 0 {
		t.Fatalf("expected 0 findings (whitelisted), got %d: %+v", len(got), got)
	}
}

func TestRuleDeletedPathFlagsCodePath(t *testing.T) {
	body := []byte("Path is `apps/mcp/internal/foo.go` for legacy.\n")
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "feedback_a.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	g.AddEdge(graph.Edge{From: "feedback_a.md", To: "apps/mcp/internal/foo.go", Kind: graph.EdgeCodePath, SourceLine: 1, Snippet: "apps/mcp/internal/foo.go"})

	src := newFake()
	src.bodies["feedback_a.md"] = body
	cfg := config.Defaults()

	got := ruleDeletedPath(g, cfg, src)
	if len(got) != 1 {
		t.Fatalf("expected 1 finding, got %d", len(got))
	}
	if got[0].Severity != SeverityWarn {
		t.Errorf("severity=%s want warn (whitelisted by 'legacy' keyword)", got[0].Severity)
	}
}

func TestRuleDeletedPathErrorWhenNoContext(t *testing.T) {
	body := []byte("The path is `apps/mcp/handlers/x.go` and does the thing.\n")
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "feedback_a.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	g.AddEdge(graph.Edge{From: "feedback_a.md", To: "apps/mcp/handlers/x.go", Kind: graph.EdgeCodePath, SourceLine: 1})

	src := newFake()
	src.bodies["feedback_a.md"] = body
	cfg := config.Defaults()

	got := ruleDeletedPath(g, cfg, src)
	if len(got) != 1 {
		t.Fatalf("expected 1 finding")
	}
	if got[0].Severity != SeverityError {
		t.Errorf("severity=%s want error (no whitelist context)", got[0].Severity)
	}
}

func TestRuleRemovedToolDowngradedInRemovedSection(t *testing.T) {
	body := []byte("REMOVED in 2026 refactor (do not reference): tool_x is gone.\nUse the new flow instead.\n")
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "topics/playbook.md", Type: graph.NodeReference, Status: graph.StatusActive})

	src := newFake()
	src.bodies["topics/playbook.md"] = body
	cfg := config.Defaults()

	got := ruleRemovedTool(g, cfg, src)
	if len(got) == 0 {
		t.Fatal("expected at least one finding")
	}
	for _, f := range got {
		if f.Severity != SeverityInfo {
			t.Errorf("severity=%s want info (REMOVED context whitelist)", f.Severity)
		}
	}
}

func TestRuleRemovedToolWarnInPlainProse(t *testing.T) {
	body := []byte("Call tool_x_compress_context to handle the situation.\n")
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "feedback.md", Type: graph.NodeFeedback, Status: graph.StatusActive})

	src := newFake()
	src.bodies["feedback.md"] = body
	cfg := config.Defaults()

	got := ruleRemovedTool(g, cfg, src)
	if len(got) != 1 {
		t.Fatalf("expected 1 finding, got %d", len(got))
	}
	if got[0].Severity != SeverityWarn {
		t.Errorf("severity=%s want warn", got[0].Severity)
	}
}

func TestRuleRemovedToolMaskedInFencedCode(t *testing.T) {
	body := []byte("Outside text.\n\n```bash\ntool_x is fine here\n```\n\nMore text.\n")
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "x.md", Type: graph.NodeFeedback, Status: graph.StatusActive})

	src := newFake()
	src.bodies["x.md"] = body
	cfg := config.Defaults()

	got := ruleRemovedTool(g, cfg, src)
	if len(got) != 0 {
		t.Errorf("fenced code-block tool_x should not produce a finding, got %d: %+v", len(got), got)
	}
}

func TestRuleBrokenAnchor(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "a.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	_ = g.AddNode(&graph.Node{Path: "b.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	g.AddEdge(graph.Edge{From: "a.md", To: "b.md#nonexistent", Kind: graph.EdgeMDLinkAnchor, Anchor: "nonexistent", SourceLine: 1})
	g.ResolveEdges()

	src := newFake()
	src.headings["b.md"] = []string{"intro", "summary"}
	cfg := config.Defaults()

	got := ruleBrokenAnchor(g, cfg, src)
	if len(got) != 1 {
		t.Fatalf("expected 1 finding, got %d", len(got))
	}
	if got[0].Severity != SeverityWarn {
		t.Errorf("severity=%s", got[0].Severity)
	}
}

func TestRuleOrphan(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "MEMORY.md", Type: graph.NodeIndex, Status: graph.StatusActive})
	_ = g.AddNode(&graph.Node{Path: "feedback_orphan.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	_ = g.AddNode(&graph.Node{Path: "feedback_used.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	g.AddEdge(graph.Edge{From: "MEMORY.md", To: "feedback_used.md", Kind: graph.EdgeMDLink})
	g.ResolveEdges()

	src := newFake()
	cfg := config.Defaults()

	got := ruleOrphan(g, cfg, src)
	if len(got) != 1 {
		t.Fatalf("expected 1 orphan, got %d: %+v", len(got), got)
	}
	if got[0].File != "feedback_orphan.md" {
		t.Errorf("orphan file=%s", got[0].File)
	}
}

func TestRuleOrphanIgnoredViaConfig(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "completed-projects.md", Type: graph.NodeFeedback, Status: graph.StatusActive})

	src := newFake()
	cfg := config.Defaults()

	got := ruleOrphan(g, cfg, src)
	if len(got) != 0 {
		t.Errorf("ignored orphan should not produce finding, got %d", len(got))
	}
}

func TestRuleSupersedeCycle(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "a.md", Type: graph.NodeFeedback, Status: graph.StatusSuperseded})
	_ = g.AddNode(&graph.Node{Path: "b.md", Type: graph.NodeFeedback, Status: graph.StatusSuperseded})
	g.AddEdge(graph.Edge{From: "a.md", To: "b.md", Kind: graph.EdgeMDLink})
	g.AddEdge(graph.Edge{From: "b.md", To: "a.md", Kind: graph.EdgeMDLink})
	g.ResolveEdges()

	src := newFake()
	cfg := config.Defaults()

	got := ruleSupersedeCycle(g, cfg, src)
	if len(got) == 0 {
		t.Fatal("expected cycle finding")
	}
}

func TestRuleStaleExternalAbsent(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "a.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	g.AddEdge(graph.Edge{From: "a.md", To: "../../dev/missing.md", Kind: graph.EdgeExternalRel, SourceLine: 1})

	src := newFake()
	cfg := config.Defaults()

	got := ruleStaleExternal(g, cfg, src)
	if len(got) != 1 {
		t.Fatalf("expected 1 finding, got %d", len(got))
	}
}

func TestRuleStaleExternalPresent(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "a.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	g.AddEdge(graph.Edge{From: "a.md", To: "../../dev/present.md", Kind: graph.EdgeExternalRel, SourceLine: 1})

	src := newFake()
	src.exists["../../dev/present.md"] = true
	cfg := config.Defaults()

	got := ruleStaleExternal(g, cfg, src)
	if len(got) != 0 {
		t.Errorf("present external should not flag, got %d", len(got))
	}
}

func TestFindingsFilterBySeverity(t *testing.T) {
	f := Findings{
		{Severity: SeverityError},
		{Severity: SeverityWarn},
		{Severity: SeverityInfo},
	}
	if len(f.FilterBySeverity(SeverityError)) != 1 {
		t.Errorf("error filter wrong count")
	}
	if len(f.FilterBySeverity(SeverityWarn)) != 2 {
		t.Errorf("warn filter wrong count")
	}
	if len(f.FilterBySeverity(SeverityInfo)) != 3 {
		t.Errorf("info filter wrong count")
	}
}

func TestFindingsCounts(t *testing.T) {
	f := Findings{
		{Severity: SeverityError},
		{Severity: SeverityError},
		{Severity: SeverityWarn},
		{Severity: SeverityInfo},
	}
	c := f.Counts()
	if c[SeverityError] != 2 || c[SeverityWarn] != 1 || c[SeverityInfo] != 1 {
		t.Errorf("counts wrong: %+v", c)
	}
}

func TestRunDeduplicatesAndSorts(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "MEMORY.md", Type: graph.NodeIndex, Status: graph.StatusActive})
	_ = g.AddNode(&graph.Node{Path: "feedback_orphan.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	g.ResolveEdges()

	src := newFake()
	src.bodies["MEMORY.md"] = []byte("intro\n")
	src.bodies["feedback_orphan.md"] = []byte("body\n")
	cfg := config.Defaults()

	got := Run(g, cfg, src, []string{"all"})
	for i := 1; i < len(got); i++ {
		if got[i-1].File > got[i].File {
			t.Errorf("findings not sorted: %s before %s", got[i-1].File, got[i].File)
		}
	}
}

func TestRunSelectsByName(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "feedback_orphan.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	src := newFake()
	src.bodies["feedback_orphan.md"] = []byte("body\n")
	cfg := config.Defaults()

	got := Run(g, cfg, src, []string{"ORPHAN"})
	for _, f := range got {
		if f.Rule != RuleOrphan {
			t.Errorf("unexpected rule: %s", f.Rule)
		}
	}
}
