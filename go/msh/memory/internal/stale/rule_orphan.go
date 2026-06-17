package stale

import (
	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
)

func ruleOrphan(g *graph.Graph, cfg *config.Config, src Source) Findings {
	_ = src
	ignore := make(map[string]bool, len(cfg.IgnoreOrphans))
	for _, p := range cfg.IgnoreOrphans {
		ignore[p] = true
	}
	var out Findings
	for _, n := range g.Nodes() {
		if n.Type == graph.NodeIndex {
			continue
		}
		if ignore[n.Path] {
			continue
		}
		if g.IncomingCount(n.Path) > 0 {
			continue
		}
		out = append(out, Finding{
			Rule:     RuleOrphan,
			Severity: SeverityInfo,
			File:     n.Path,
			Line:     1,
			Snippet:  "",
			Target:   n.Path,
			Message:  "node has zero incoming edges; consider linking from MEMORY.md or feedback-index",
		})
	}
	return out
}
