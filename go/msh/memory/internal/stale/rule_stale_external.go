package stale

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
)

func ruleStaleExternal(g *graph.Graph, cfg *config.Config, src Source) Findings {
	_ = cfg
	var out Findings
	for _, e := range g.Edges() {
		if e.Kind != graph.EdgeExternalRel {
			continue
		}
		if strings.HasPrefix(e.To, "http://") || strings.HasPrefix(e.To, "https://") {
			continue
		}
		repoRel := externalRepoRelative(e.From, e.To)
		if repoRel == "" {
			continue
		}
		if src.Exists(repoRel) {
			continue
		}
		out = append(out, Finding{
			Rule:     RuleStaleExternal,
			Severity: SeverityWarn,
			File:     e.From,
			Line:     e.SourceLine,
			Snippet:  e.Snippet,
			Target:   e.To,
			Message:  fmt.Sprintf("external relative reference %q does not resolve to a file on disk (resolved to %q)", e.To, repoRel),
			EdgeKind: string(e.Kind),
		})
	}
	return out
}

func externalRepoRelative(from, target string) string {
	if !strings.HasPrefix(target, "../") && !strings.HasPrefix(target, "./") {
		return ""
	}
	if i := strings.Index(target, "#"); i >= 0 {
		target = target[:i]
	}
	dir := filepath.Dir(from)
	joined := filepath.Join(dir, target)
	return filepath.ToSlash(joined)
}
