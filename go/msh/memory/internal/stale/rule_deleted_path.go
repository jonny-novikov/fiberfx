package stale

import (
	"fmt"
	"strings"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
)

func ruleDeletedPath(g *graph.Graph, cfg *config.Config, src Source) Findings {
	contexts := buildContextsFor(g, cfg, src)
	var out Findings
	for _, e := range g.Edges() {
		if e.Kind != graph.EdgeCodePath {
			continue
		}
		hit := matchDeletedPath(e.To, cfg.DeletedPaths)
		if hit == "" {
			continue
		}
		ctx := contexts[e.From]
		whitelisted := ctx != nil && ctx.MatchesAt(byteOffsetForLine(g, src, e.From, e.SourceLine))
		severity := SeverityError
		message := fmt.Sprintf("references deleted path %q (matched %q)", e.To, hit)
		if whitelisted {
			severity = SeverityWarn
			message += " — surrounding context cites deletion/removal"
		}
		out = append(out, Finding{
			Rule:     RuleDeletedPath,
			Severity: severity,
			File:     e.From,
			Line:     e.SourceLine,
			Snippet:  e.Snippet,
			Target:   e.To,
			Message:  message,
			EdgeKind: string(e.Kind),
		})
	}
	return out
}

func matchDeletedPath(target string, patterns []string) string {
	t := strings.TrimSpace(target)
	for _, p := range patterns {
		if matchGlob(p, t) {
			return p
		}
	}
	return ""
}

func matchGlob(pattern, target string) bool {
	p := strings.TrimSpace(pattern)
	if p == "" {
		return false
	}
	if strings.HasSuffix(p, "/**") {
		prefix := strings.TrimSuffix(p, "/**")
		return strings.HasPrefix(target, prefix+"/") || target == prefix
	}
	if strings.HasSuffix(p, "/*") {
		prefix := strings.TrimSuffix(p, "/*")
		if !strings.HasPrefix(target, prefix+"/") {
			return false
		}
		rest := target[len(prefix)+1:]
		return !strings.Contains(rest, "/")
	}
	return target == p
}
