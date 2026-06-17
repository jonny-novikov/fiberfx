package graph

import (
	"fmt"
	"io"
	"strings"
)

func RenderDOT(w io.Writer, g *Graph, includeExternal bool) error {
	if _, err := fmt.Fprintln(w, "digraph memory {"); err != nil {
		return err
	}
	if _, err := fmt.Fprintln(w, "  rankdir=LR;"); err != nil {
		return err
	}
	if _, err := fmt.Fprintln(w, "  node [shape=box, fontsize=10];"); err != nil {
		return err
	}
	for _, n := range g.Nodes() {
		label := dotEscape(n.Path)
		color := nodeColor(n)
		if _, err := fmt.Fprintf(w, "  %q [label=%q, fillcolor=%q, style=filled];\n", n.Path, label, color); err != nil {
			return err
		}
	}
	for _, e := range g.Edges() {
		if !includeExternal && e.Kind == EdgeExternalRel {
			continue
		}
		target := e.ToResolved
		if target == "" {
			target = e.To
		}
		style := "solid"
		if !e.Resolved {
			style = "dashed"
		}
		if _, err := fmt.Fprintf(w, "  %q -> %q [label=%q, style=%q];\n", e.From, target, string(e.Kind), style); err != nil {
			return err
		}
	}
	if _, err := fmt.Fprintln(w, "}"); err != nil {
		return err
	}
	return nil
}

func nodeColor(n *Node) string {
	if n.Status == StatusSuperseded {
		return "lightgray"
	}
	switch n.Type {
	case NodeFeedback:
		return "lightblue"
	case NodeLaw:
		return "lightcoral"
	case NodeSession:
		return "lightyellow"
	case NodeIndex:
		return "khaki"
	case NodeProject:
		return "lightgreen"
	case NodeReference:
		return "lavender"
	default:
		return "white"
	}
}

func dotEscape(s string) string {
	return strings.ReplaceAll(s, "\"", "\\\"")
}
