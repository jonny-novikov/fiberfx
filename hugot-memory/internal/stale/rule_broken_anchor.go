package stale

import (
	"fmt"

	"github.com/fiberfx/hugot-memory/internal/config"
	"github.com/fiberfx/hugot-memory/internal/graph"
)

func ruleBrokenAnchor(g *graph.Graph, cfg *config.Config, src Source) Findings {
	_ = cfg
	var out Findings
	for _, e := range g.Edges() {
		if e.Kind != graph.EdgeMDLinkAnchor {
			continue
		}
		if !e.Resolved {
			continue
		}
		if e.Anchor == "" {
			continue
		}
		slugs, err := src.HeadingSlugs(e.ToResolved)
		if err != nil {
			continue
		}
		if containsString(slugs, e.Anchor) {
			continue
		}
		out = append(out, Finding{
			Rule:     RuleBrokenAnchor,
			Severity: SeverityWarn,
			File:     e.From,
			Line:     e.SourceLine,
			Snippet:  e.Snippet,
			Target:   e.To,
			Message:  fmt.Sprintf("anchor %q not found among headings of %q", e.Anchor, e.ToResolved),
			EdgeKind: string(e.Kind),
		})
	}
	return out
}

func containsString(haystack []string, needle string) bool {
	for _, s := range haystack {
		if s == needle {
			return true
		}
	}
	return false
}
