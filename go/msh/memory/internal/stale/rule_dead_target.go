package stale

import (
	"fmt"
	"strings"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
)

func ruleDeadTarget(g *graph.Graph, cfg *config.Config, src Source) Findings {
	contexts := buildContextsFor(g, cfg, src)
	var out Findings
	for _, e := range g.Edges() {
		if !isInternalMDEdge(e) {
			continue
		}
		target := strings.TrimSpace(e.ToResolved)
		if target == "" {
			continue
		}
		if !strings.HasSuffix(target, ".md") {
			continue
		}
		if _, ok := g.Node(target); ok {
			continue
		}
		ctx := contexts[e.From]
		whitelisted := ctx != nil && ctx.MatchesAt(byteOffsetForLine(g, src, e.From, e.SourceLine))
		if whitelisted {
			continue
		}
		out = append(out, Finding{
			Rule:     RuleDeadTarget,
			Severity: SeverityError,
			File:     e.From,
			Line:     e.SourceLine,
			Snippet:  e.Snippet,
			Target:   target,
			Message:  fmt.Sprintf("link target %q does not resolve to any node in graph", target),
			EdgeKind: string(e.Kind),
		})
	}
	return out
}

func isInternalMDEdge(e graph.Edge) bool {
	switch e.Kind {
	case graph.EdgeMDLink, graph.EdgeMDLinkAnchor, graph.EdgeBareMention, graph.EdgeCrossSubdir:
		return true
	}
	return false
}

func buildContextsFor(g *graph.Graph, cfg *config.Config, src Source) map[string]*DeletionContext {
	out := make(map[string]*DeletionContext, g.NodeCount())
	for _, n := range g.Nodes() {
		body, err := src.Body(n.Path)
		if err != nil {
			continue
		}
		out[n.Path] = NewDeletionContext(body, cfg.ContextWhitelistKeywords)
	}
	return out
}

func byteOffsetForLine(g *graph.Graph, src Source, fromPath string, line int) int {
	body, err := src.Body(fromPath)
	if err != nil {
		return 0
	}
	if line <= 1 {
		return 0
	}
	count := 1
	for i := 0; i < len(body); i++ {
		if count == line {
			return i
		}
		if body[i] == '\n' {
			count++
		}
	}
	return len(body)
}
