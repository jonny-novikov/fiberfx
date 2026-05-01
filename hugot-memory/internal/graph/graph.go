package graph

import (
	"fmt"
	"path/filepath"
	"sort"
	"strings"
)

type Graph struct {
	Root  string
	nodes map[string]*Node
	edges []Edge
}

func New(root string) *Graph {
	return &Graph{
		Root:  root,
		nodes: make(map[string]*Node),
	}
}

func (g *Graph) AddNode(n *Node) error {
	if n == nil {
		return fmt.Errorf("graph.AddNode: nil node")
	}
	if n.Path == "" {
		return fmt.Errorf("graph.AddNode: node has empty Path")
	}
	if _, dup := g.nodes[n.Path]; dup {
		return fmt.Errorf("graph.AddNode: duplicate node %q", n.Path)
	}
	g.nodes[n.Path] = n
	return nil
}

func (g *Graph) Node(path string) (*Node, bool) {
	n, ok := g.nodes[path]
	return n, ok
}

func (g *Graph) NodeCount() int {
	return len(g.nodes)
}

func (g *Graph) Nodes() []*Node {
	out := make([]*Node, 0, len(g.nodes))
	for _, n := range g.nodes {
		out = append(out, n)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Path < out[j].Path })
	return out
}

func (g *Graph) AddEdge(e Edge) {
	g.edges = append(g.edges, e)
}

func (g *Graph) Edges() []Edge {
	out := make([]Edge, len(g.edges))
	copy(out, g.edges)
	sort.SliceStable(out, func(i, j int) bool {
		if out[i].From != out[j].From {
			return out[i].From < out[j].From
		}
		if out[i].SourceLine != out[j].SourceLine {
			return out[i].SourceLine < out[j].SourceLine
		}
		if out[i].SourceCol != out[j].SourceCol {
			return out[i].SourceCol < out[j].SourceCol
		}
		return out[i].To < out[j].To
	})
	return out
}

func (g *Graph) ResolveEdges() {
	for i := range g.edges {
		ed := &g.edges[i]
		resolved := g.resolveTarget(ed.From, ed.To, ed.Kind)
		ed.ToResolved = resolved
		_, hasNode := g.nodes[resolved]
		ed.Resolved = hasNode
	}
}

func (g *Graph) resolveTarget(from, target string, kind EdgeKind) string {
	if kind == EdgeAnchorOnly {
		return ""
	}
	cleaned := target
	if i := strings.Index(cleaned, "#"); i >= 0 {
		cleaned = cleaned[:i]
	}
	if cleaned == "" {
		return from
	}
	if strings.HasPrefix(cleaned, "../") || strings.HasPrefix(cleaned, "./") {
		dir := filepath.Dir(from)
		joined := filepath.Join(dir, cleaned)
		return filepath.ToSlash(joined)
	}
	if strings.HasPrefix(cleaned, "topics/") || strings.Contains(cleaned, "/") {
		return filepath.ToSlash(cleaned)
	}
	dir := filepath.Dir(from)
	if dir == "." || dir == "" {
		return cleaned
	}
	if _, ok := g.nodes[cleaned]; ok {
		return cleaned
	}
	joined := filepath.Join(dir, cleaned)
	return filepath.ToSlash(joined)
}

func (g *Graph) IncomingCount(path string) int {
	count := 0
	for _, e := range g.edges {
		if !e.Resolved {
			continue
		}
		if e.ToResolved == path {
			count++
		}
	}
	return count
}
