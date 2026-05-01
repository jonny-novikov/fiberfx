package graph

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
)

func TestAddNodeDedupRejectsDuplicate(t *testing.T) {
	g := New("/root")
	if err := g.AddNode(&Node{Path: "a.md", Type: NodeFeedback, Status: StatusActive}); err != nil {
		t.Fatalf("first add: %v", err)
	}
	err := g.AddNode(&Node{Path: "a.md"})
	if err == nil {
		t.Fatal("expected duplicate error")
	}
}

func TestAddNodeRejectsNilOrEmptyPath(t *testing.T) {
	g := New("/root")
	if err := g.AddNode(nil); err == nil {
		t.Fatal("expected nil error")
	}
	if err := g.AddNode(&Node{}); err == nil {
		t.Fatal("expected empty path error")
	}
}

func TestResolveEdgesInGraph(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "MEMORY.md", Type: NodeIndex, Status: StatusActive})
	_ = g.AddNode(&Node{Path: "feedback_a.md", Type: NodeFeedback, Status: StatusActive})
	g.AddEdge(Edge{From: "MEMORY.md", To: "feedback_a.md", Kind: EdgeMDLink, SourceLine: 5})
	g.AddEdge(Edge{From: "MEMORY.md", To: "feedback_missing.md", Kind: EdgeMDLink, SourceLine: 6})
	g.ResolveEdges()
	edges := g.Edges()
	if len(edges) != 2 {
		t.Fatalf("expected 2 edges, got %d", len(edges))
	}
	if !edges[0].Resolved {
		t.Errorf("edge[0] should resolve")
	}
	if edges[1].Resolved {
		t.Errorf("edge[1] should NOT resolve")
	}
}

func TestResolveEdgesCrossSubdir(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "topics/cclin/topologies.md", Type: NodeReference, Status: StatusActive})
	_ = g.AddNode(&Node{Path: "MEMORY.md", Type: NodeIndex, Status: StatusActive})
	g.AddEdge(Edge{From: "MEMORY.md", To: "topics/cclin/topologies.md", Kind: EdgeCrossSubdir})
	g.ResolveEdges()
	if !g.Edges()[0].Resolved {
		t.Error("cross-subdir resolve failed")
	}
}

func TestRenderJSONRoundTrip(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "a.md", Type: NodeFeedback, Name: "Sample", Status: StatusActive, SizeBytes: 42, HasFrontmatter: true})
	g.AddEdge(Edge{From: "a.md", To: "b.md", Kind: EdgeMDLink, SourceLine: 1})
	var buf bytes.Buffer
	if err := RenderJSON(&buf, g, false); err != nil {
		t.Fatalf("render: %v", err)
	}
	var parsed jsonOutput
	if err := json.Unmarshal(buf.Bytes(), &parsed); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if len(parsed.Nodes) != 1 || parsed.Nodes[0].Path != "a.md" {
		t.Fatalf("nodes round-trip failed: %+v", parsed.Nodes)
	}
	if len(parsed.Edges) != 1 || parsed.Edges[0].To != "b.md" {
		t.Fatalf("edges round-trip failed: %+v", parsed.Edges)
	}
}

func TestRenderDOTHasDigraph(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "a.md", Type: NodeFeedback, Status: StatusActive})
	g.AddEdge(Edge{From: "a.md", To: "b.md", Kind: EdgeMDLink})
	var buf bytes.Buffer
	if err := RenderDOT(&buf, g, false); err != nil {
		t.Fatalf("render: %v", err)
	}
	out := buf.String()
	if !strings.Contains(out, "digraph memory") {
		t.Error("missing digraph header")
	}
	if !strings.Contains(out, `"a.md" -> "b.md"`) {
		t.Errorf("missing edge: %s", out)
	}
}

func TestIncomingCount(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "a.md", Type: NodeFeedback, Status: StatusActive})
	_ = g.AddNode(&Node{Path: "b.md", Type: NodeFeedback, Status: StatusActive})
	_ = g.AddNode(&Node{Path: "c.md", Type: NodeFeedback, Status: StatusActive})
	g.AddEdge(Edge{From: "a.md", To: "b.md", Kind: EdgeMDLink})
	g.AddEdge(Edge{From: "c.md", To: "b.md", Kind: EdgeMDLink})
	g.ResolveEdges()
	if g.IncomingCount("b.md") != 2 {
		t.Errorf("b.md incoming=%d want 2", g.IncomingCount("b.md"))
	}
	if g.IncomingCount("a.md") != 0 {
		t.Errorf("a.md incoming=%d want 0", g.IncomingCount("a.md"))
	}
}

func TestRenderJSONExcludesExternalWhenFalse(t *testing.T) {
	g := New("/root")
	_ = g.AddNode(&Node{Path: "a.md", Type: NodeFeedback, Status: StatusActive})
	g.AddEdge(Edge{From: "a.md", To: "../../dev/foo.md", Kind: EdgeExternalRel})
	g.AddEdge(Edge{From: "a.md", To: "b.md", Kind: EdgeMDLink})
	var buf bytes.Buffer
	if err := RenderJSON(&buf, g, false); err != nil {
		t.Fatal(err)
	}
	var parsed jsonOutput
	_ = json.Unmarshal(buf.Bytes(), &parsed)
	if len(parsed.Edges) != 1 {
		t.Errorf("expected 1 edge after exclusion, got %d", len(parsed.Edges))
	}
}
