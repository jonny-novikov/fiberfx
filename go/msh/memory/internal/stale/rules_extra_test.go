package stale

import (
	"testing"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
)

func TestMatchGlobVariants(t *testing.T) {
	cases := []struct {
		pattern, target string
		want            bool
	}{
		{"apps/mcp/**", "apps/mcp/foo.go", true},
		{"apps/mcp/**", "apps/mcp", true},
		{"apps/mcp/**", "apps/other/foo.go", false},
		{"apps/x/*", "apps/x/foo.go", true},
		{"apps/x/*", "apps/x/sub/foo.go", false},
		{"apps/y", "apps/y", true},
		{"apps/y", "apps/y/extra", false},
		{"", "anything", false},
	}
	for _, c := range cases {
		got := matchGlob(c.pattern, c.target)
		if got != c.want {
			t.Errorf("matchGlob(%q,%q)=%v want %v", c.pattern, c.target, got, c.want)
		}
	}
}

func TestSortByLengthDesc(t *testing.T) {
	in := []string{"a", "ccc", "bb"}
	sortByLengthDesc(in)
	if in[0] != "ccc" || in[1] != "bb" || in[2] != "a" {
		t.Errorf("sort: %+v", in)
	}
}

func TestRunUnknownRuleNamesIgnored(t *testing.T) {
	g := graph.New("/root")
	src := newFake()
	cfg := config.Defaults()
	got := Run(g, cfg, src, []string{"NOT-A-RULE", "ALSO-NOT"})
	if len(got) != 0 {
		t.Errorf("expected 0 findings, got %d", len(got))
	}
}

func TestRunDefaultsToAllWhenEmpty(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "feedback_orphan.md", Type: graph.NodeFeedback, Status: graph.StatusActive})
	src := newFake()
	src.bodies["feedback_orphan.md"] = []byte("body\n")
	cfg := config.Defaults()
	got := Run(g, cfg, src, []string{})
	hasOrphan := false
	for _, f := range got {
		if f.Rule == RuleOrphan {
			hasOrphan = true
		}
	}
	if !hasOrphan {
		t.Error("expected orphan rule to fire by default")
	}
}

func TestSeverityRankInvalid(t *testing.T) {
	if severityRank("not-real") != 0 {
		t.Error("invalid severity should rank 0")
	}
}

func TestSortFindingsStableByLine(t *testing.T) {
	f := Findings{
		{File: "b.md", Line: 1, Rule: "X"},
		{File: "a.md", Line: 5, Rule: "X"},
		{File: "a.md", Line: 1, Rule: "X"},
		{File: "a.md", Line: 1, Rule: "Y"},
		{File: "a.md", Line: 1, Rule: "X", Target: "z"},
	}
	sortFindings(f)
	if f[0].File != "a.md" || f[0].Line != 1 || f[0].Rule != "X" {
		t.Errorf("sort head: %+v", f[0])
	}
}

func TestEdgeKindForCodeMatchBareMention(t *testing.T) {
	body := []byte("plain prose tool_x mention\n")
	if edgeKindForCodeMatch(body, 12, 18) != string(graph.EdgeBareMention) {
		t.Errorf("expected bare_mention for plain prose")
	}
}

func TestEdgeKindForCodeMatchInline(t *testing.T) {
	body := []byte("see `tool_x` here\n")
	if edgeKindForCodeMatch(body, 5, 11) != string(graph.EdgeCodePath) {
		t.Errorf("expected code_path for inline-code wrapped match")
	}
}
