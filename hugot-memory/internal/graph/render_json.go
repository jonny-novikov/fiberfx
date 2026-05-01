package graph

import (
	"encoding/json"
	"fmt"
	"io"
)

type jsonOutput struct {
	Root  string  `json:"root"`
	Nodes []*Node `json:"nodes"`
	Edges []Edge  `json:"edges"`
}

func RenderJSON(w io.Writer, g *Graph, includeExternal bool) error {
	edges := g.Edges()
	if !includeExternal {
		filtered := make([]Edge, 0, len(edges))
		for _, e := range edges {
			if e.Kind == EdgeExternalRel {
				continue
			}
			filtered = append(filtered, e)
		}
		edges = filtered
	}
	out := jsonOutput{
		Root:  g.Root,
		Nodes: g.Nodes(),
		Edges: edges,
	}
	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")
	if err := enc.Encode(out); err != nil {
		return fmt.Errorf("graph: render json: %w", err)
	}
	return nil
}
