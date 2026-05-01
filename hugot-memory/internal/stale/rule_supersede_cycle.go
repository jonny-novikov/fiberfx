package stale

import (
	"fmt"

	"github.com/fiberfx/hugot-memory/internal/config"
	"github.com/fiberfx/hugot-memory/internal/graph"
)

func ruleSupersedeCycle(g *graph.Graph, cfg *config.Config, src Source) Findings {
	_ = cfg
	_ = src
	var out Findings
	supersededNodes := make(map[string]*graph.Node)
	for _, n := range g.Nodes() {
		if n.Status == graph.StatusSuperseded {
			supersededNodes[n.Path] = n
		}
	}
	if len(supersededNodes) == 0 {
		return nil
	}
	successorOf := make(map[string]map[string]bool)
	for _, e := range g.Edges() {
		if !e.Resolved {
			continue
		}
		if _, isSuperseded := supersededNodes[e.From]; !isSuperseded {
			continue
		}
		if successorOf[e.From] == nil {
			successorOf[e.From] = make(map[string]bool)
		}
		successorOf[e.From][e.ToResolved] = true
	}
	for from, successors := range successorOf {
		for succ := range successors {
			if _, succSuperseded := supersededNodes[succ]; !succSuperseded {
				continue
			}
			if successorOf[succ] != nil && successorOf[succ][from] {
				out = append(out, Finding{
					Rule:     RuleSupersedeCycle,
					Severity: SeverityWarn,
					File:     from,
					Line:     1,
					Target:   succ,
					Message:  fmt.Sprintf("superseded node cites %q which cites back — supersede chain forms cycle", succ),
				})
			}
		}
	}
	return out
}
