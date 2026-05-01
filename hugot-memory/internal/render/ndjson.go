package render

import (
	"encoding/json"
	"fmt"
	"io"

	"github.com/fiberfx/hugot-memory/internal/graph"
	"github.com/fiberfx/hugot-memory/internal/stale"
)

func NDJSONNodes(w io.Writer, nodes []*graph.Node) error {
	enc := json.NewEncoder(w)
	for _, n := range nodes {
		if err := enc.Encode(n); err != nil {
			return fmt.Errorf("ndjson nodes: %w", err)
		}
	}
	return nil
}

func NDJSONFindings(w io.Writer, findings stale.Findings) error {
	enc := json.NewEncoder(w)
	for _, f := range findings {
		if err := enc.Encode(f); err != nil {
			return fmt.Errorf("ndjson findings: %w", err)
		}
	}
	return nil
}
