package command

import (
	"strings"

	"github.com/jonny-novikov/msh/memory/internal/graph"
	"github.com/jonny-novikov/msh/memory/internal/stale"
)

// normalizeProject lowercases + trims a project value (the classifyType
// precedent) — applied on BOTH sides: the declared/degraded value at corpus
// load and the filter argument at entry (msh2.2 §3.3).
func normalizeProject(s string) string {
	return strings.ToLower(strings.TrimSpace(s))
}

// filterNodesByProject keeps the nodes whose effective project equals p (both
// sides normalized). Empty p means no filter. An unscoped node (empty
// Node.Project) matches no filter and appears only in unfiltered output
// (msh2.2 §3.3).
func filterNodesByProject(nodes []*graph.Node, p string) []*graph.Node {
	p = normalizeProject(p)
	if p == "" {
		return nodes
	}
	out := make([]*graph.Node, 0, len(nodes))
	for _, n := range nodes {
		if n.Project == p {
			out = append(out, n)
		}
	}
	return out
}

// filterFindingsByProject POST-filters stale findings: rules always run over
// the FULL graph, then a finding is kept when its File's effective project
// equals p. Pre-filtering the graph would invent findings — a node linked only
// from another project would false-report ORPHAN — so the filter is a view,
// never a different corpus (msh2.2 §3.3). Empty p means no filter.
func filterFindingsByProject(findings stale.Findings, g *graph.Graph, p string) stale.Findings {
	p = normalizeProject(p)
	if p == "" {
		return findings
	}
	allowed := make(map[string]bool)
	for _, n := range g.Nodes() {
		if n.Project == p {
			allowed[n.Path] = true
		}
	}
	out := make(stale.Findings, 0, len(findings))
	for _, f := range findings {
		if allowed[f.File] {
			out = append(out, f)
		}
	}
	return out
}
