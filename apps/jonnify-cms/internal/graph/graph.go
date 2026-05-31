// Package graph builds the course's structural navigation graph from the
// manifest and enriches each node with on-disk readiness (does the route
// resolve to a file). It emits Graphviz DOT, Mermaid, or JSON, all deterministic.
package graph

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/jonny-novikov/jonnify-cms/internal/manifest"
	"github.com/jonny-novikov/jonnify-cms/internal/site"
)

// Node is a page in the graph.
type Node struct {
	ID       string `json:"id"`
	Label    string `json:"label"`
	Route    string `json:"route"`
	Kind     string `json:"kind"`
	Status   string `json:"status"`
	Resolves bool   `json:"resolves"`
}

// Edge connects two nodes; Kind is spine | contains | next | dive.
type Edge struct {
	From string `json:"from"`
	To   string `json:"to"`
	Kind string `json:"kind"`
}

// Graph is the whole node/edge set.
type Graph struct {
	Nodes []Node `json:"nodes"`
	Edges []Edge `json:"edges"`
}

// Build constructs the graph, resolving each route against root for readiness.
func Build(root string) Graph {
	var g Graph
	add := func(id, label, route, kind, status string) {
		resolves := false
		if route != "" {
			_, ok, _ := site.Resolve(root, route)
			resolves = ok
		}
		g.Nodes = append(g.Nodes, Node{id, label, route, kind, status, resolves})
	}
	prevChapter := ""
	for _, c := range manifest.Chapters {
		add(c.ID, c.ID+" · "+c.Title, c.Route, "chapter", c.Status)
		if prevChapter != "" {
			g.Edges = append(g.Edges, Edge{prevChapter, c.ID, "spine"})
		}
		prevChapter = c.ID
		prevModule := ""
		for _, m := range manifest.Modules[c.ID] {
			route := c.Route + "/" + m.Slug
			add(m.N, m.N+" "+m.Title, route, "module", m.Status)
			g.Edges = append(g.Edges, Edge{c.ID, m.N, "contains"})
			if prevModule != "" {
				g.Edges = append(g.Edges, Edge{prevModule, m.N, "next"})
			}
			prevModule = m.N
			for _, s := range manifest.Subpages[m.N] {
				sid := m.N + "/" + s.Slug
				add(sid, s.Title, route+"/"+s.Slug, "subpage", m.Status)
				g.Edges = append(g.Edges, Edge{m.N, sid, "dive"})
			}
		}
	}
	return g
}

// JSON renders the graph as indented JSON.
func (g Graph) JSON() string {
	b, _ := json.MarshalIndent(g, "", "  ")
	return string(b)
}

func nid(s string) string {
	return strings.NewReplacer(".", "_", "/", "__", " ", "_", "-", "_").Replace(s)
}

// Mermaid renders a left-to-right Mermaid graph; planned nodes carry a ○ marker.
func (g Graph) Mermaid() string {
	var b strings.Builder
	b.WriteString("graph LR\n")
	for _, n := range g.Nodes {
		mark := ""
		if !manifest.Linkable(n.Status) {
			mark = " ○"
		} else if n.Route != "" && !n.Resolves {
			mark = " ⚠"
		}
		b.WriteString(fmt.Sprintf("  %s[\"%s%s\"]\n", nid(n.ID), strings.ReplaceAll(n.Label, "\"", "'"), mark))
	}
	for _, e := range g.Edges {
		arrow := "-->"
		if e.Kind == "spine" {
			arrow = "-.->"
		}
		b.WriteString(fmt.Sprintf("  %s %s %s\n", nid(e.From), arrow, nid(e.To)))
	}
	return b.String()
}

// DOT renders Graphviz output; unresolved live/built nodes are coloured red.
func (g Graph) DOT() string {
	var b strings.Builder
	b.WriteString("digraph elixir {\n  rankdir=LR;\n  node [shape=box,style=rounded];\n")
	for _, n := range g.Nodes {
		color := "gray70"
		if manifest.Linkable(n.Status) {
			color = "black"
			if n.Route != "" && !n.Resolves {
				color = "red"
			}
		}
		b.WriteString(fmt.Sprintf("  %q [label=%q,color=%s];\n", n.ID, n.Label, color))
	}
	for _, e := range g.Edges {
		style := "solid"
		if e.Kind == "spine" {
			style = "dashed"
		}
		b.WriteString(fmt.Sprintf("  %q -> %q [style=%s];\n", e.From, e.To, style))
	}
	b.WriteString("}\n")
	return b.String()
}
