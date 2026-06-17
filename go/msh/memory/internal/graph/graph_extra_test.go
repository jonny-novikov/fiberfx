package graph

import (
	"bytes"
	"strings"
	"testing"
)

func TestResolveExternalRel(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "MEMORY.md", Type: NodeIndex, Status: StatusActive})
	g.AddEdge(Edge{From: "MEMORY.md", To: "../../dev/foo.md", Kind: EdgeExternalRel})
	g.ResolveEdges()
	if g.Edges()[0].Resolved {
		t.Error("external_rel should not resolve to in-graph node")
	}
}

func TestResolveAnchorOnlyNoResolution(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "a.md", Type: NodeFeedback, Status: StatusActive})
	g.AddEdge(Edge{From: "a.md", To: "§Clause 3.6", Kind: EdgeAnchorOnly})
	g.ResolveEdges()
	if g.Edges()[0].Resolved {
		t.Error("anchor-only should not resolve")
	}
}

func TestResolveBareMentionWithSlash(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "topics/cclin/topologies.md", Type: NodeReference, Status: StatusActive})
	_ = g.AddNode(&Node{Path: "MEMORY.md", Type: NodeIndex, Status: StatusActive})
	g.AddEdge(Edge{From: "MEMORY.md", To: "topics/cclin/topologies.md", Kind: EdgeBareMention})
	g.ResolveEdges()
	if !g.Edges()[0].Resolved {
		t.Error("expected bare-mention with slash to resolve")
	}
}

func TestResolveBareMentionRelativeToFromDir(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "topics/sibling.md", Type: NodeReference, Status: StatusActive})
	_ = g.AddNode(&Node{Path: "topics/source.md", Type: NodeReference, Status: StatusActive})
	g.AddEdge(Edge{From: "topics/source.md", To: "sibling.md", Kind: EdgeBareMention})
	g.ResolveEdges()
	if !g.Edges()[0].Resolved {
		t.Error("expected sibling resolution under same dir")
	}
}

func TestRenderJSONIncludeExternal(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "a.md", Type: NodeFeedback, Status: StatusActive})
	g.AddEdge(Edge{From: "a.md", To: "../../dev/foo.md", Kind: EdgeExternalRel})
	var buf bytes.Buffer
	if err := RenderJSON(&buf, g, true); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(buf.String(), "external_rel") {
		t.Error("includeExternal=true should retain external_rel")
	}
}

func TestRenderDOTNodeColors(t *testing.T) {
	cases := []struct {
		nodeType NodeType
		status   Status
		want     string
	}{
		{NodeFeedback, StatusActive, "lightblue"},
		{NodeLaw, StatusActive, "lightcoral"},
		{NodeSession, StatusActive, "lightyellow"},
		{NodeIndex, StatusActive, "khaki"},
		{NodeProject, StatusActive, "lightgreen"},
		{NodeReference, StatusActive, "lavender"},
		{NodeUnknown, StatusActive, "white"},
		{NodeFeedback, StatusSuperseded, "lightgray"},
	}
	for _, c := range cases {
		got := nodeColor(&Node{Type: c.nodeType, Status: c.status})
		if got != c.want {
			t.Errorf("color for type=%s status=%s: got=%s want=%s", c.nodeType, c.status, got, c.want)
		}
	}
}

func TestRenderDOTUnresolvedEdgeDashed(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "a.md", Type: NodeFeedback, Status: StatusActive})
	g.AddEdge(Edge{From: "a.md", To: "missing.md", Kind: EdgeMDLink})
	g.ResolveEdges()
	var buf bytes.Buffer
	if err := RenderDOT(&buf, g, false); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(buf.String(), "dashed") {
		t.Errorf("unresolved edge should render dashed: %s", buf.String())
	}
}

func TestNodeAccessors(t *testing.T) {
	g := New("/root")
	if g.NodeCount() != 0 {
		t.Errorf("empty graph count=%d", g.NodeCount())
	}
	if _, ok := g.Node("missing"); ok {
		t.Error("missing path should report not-ok")
	}
	_ = g.AddNode(&Node{Path: "x.md", Type: NodeFeedback, Status: StatusActive})
	if _, ok := g.Node("x.md"); !ok {
		t.Error("present path should report ok")
	}
}

func TestEdgesSortedDeterministic(t *testing.T) {
	g := New("/root")
	g.AddEdge(Edge{From: "b.md", To: "x.md", Kind: EdgeMDLink, SourceLine: 1})
	g.AddEdge(Edge{From: "a.md", To: "y.md", Kind: EdgeMDLink, SourceLine: 5})
	g.AddEdge(Edge{From: "a.md", To: "x.md", Kind: EdgeMDLink, SourceLine: 1, SourceCol: 2})
	g.AddEdge(Edge{From: "a.md", To: "x.md", Kind: EdgeMDLink, SourceLine: 1, SourceCol: 1})
	got := g.Edges()
	if got[0].From != "a.md" || got[0].SourceLine != 1 || got[0].SourceCol != 1 {
		t.Errorf("sort head: %+v", got[0])
	}
	if got[1].SourceCol != 2 {
		t.Errorf("sort second: %+v", got[1])
	}
}

func TestRenderDOTEmptyGraph(t *testing.T) {
	g := New("/root")
	var buf bytes.Buffer
	if err := RenderDOT(&buf, g, false); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(buf.String(), "digraph memory") {
		t.Error("missing digraph header")
	}
}
