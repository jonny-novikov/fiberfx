package stale

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
	"github.com/jonny-novikov/msh/memory/internal/linkx"
)

func ruleRemovedTool(g *graph.Graph, cfg *config.Config, src Source) Findings {
	if len(cfg.RemovedTools) == 0 {
		return nil
	}
	pattern := compileRemovedTools(cfg.RemovedTools)
	if pattern == nil {
		return nil
	}
	var out Findings
	for _, n := range g.Nodes() {
		body, err := src.Body(n.Path)
		if err != nil {
			continue
		}
		mask := linkx.MaskCodeBlocks(body)
		ctx := NewDeletionContext(body, cfg.ContextWhitelistKeywords)
		hits := pattern.FindAllIndex(body, -1)
		for _, h := range hits {
			start, end := h[0], h[1]
			if start < len(mask.InCode) && mask.InCode[start] {
				inline := isInlineCodeMatch(body, start, end)
				if !inline {
					continue
				}
			}
			tok := string(body[start:end])
			line, col := offsetLineCol(body, start)
			snippet := snippetAround(body, start, end)
			severity := SeverityWarn
			message := fmt.Sprintf("references removed MCP tool %q", tok)
			if ctx.MatchesAt(start) {
				severity = SeverityInfo
				message += " — surrounding context cites removal"
			}
			_ = col
			out = append(out, Finding{
				Rule:     RuleRemovedTool,
				Severity: severity,
				File:     n.Path,
				Line:     line,
				Snippet:  snippet,
				Target:   tok,
				Message:  message,
				EdgeKind: edgeKindForCodeMatch(body, start, end),
			})
		}
	}
	return out
}

func compileRemovedTools(tools []string) *regexp.Regexp {
	if len(tools) == 0 {
		return nil
	}
	sorted := make([]string, len(tools))
	copy(sorted, tools)
	sortByLengthDesc(sorted)
	parts := make([]string, len(sorted))
	for i, t := range sorted {
		parts[i] = regexp.QuoteMeta(t)
	}
	expr := `\b(?:` + strings.Join(parts, "|") + `)\b`
	return regexp.MustCompile(expr)
}

func sortByLengthDesc(s []string) {
	for i := 0; i < len(s); i++ {
		for j := i + 1; j < len(s); j++ {
			if len(s[j]) > len(s[i]) {
				s[i], s[j] = s[j], s[i]
			}
		}
	}
}

func isInlineCodeMatch(body []byte, start, end int) bool {
	bol := start
	for bol > 0 && body[bol-1] != '\n' {
		bol--
	}
	prefix := body[bol:start]
	tickCount := strings.Count(string(prefix), "`")
	return tickCount%2 == 1
}

func edgeKindForCodeMatch(body []byte, start, end int) string {
	if isInlineCodeMatch(body, start, end) {
		return string(graph.EdgeCodePath)
	}
	return string(graph.EdgeBareMention)
}

func offsetLineCol(body []byte, offset int) (int, int) {
	if offset < 0 {
		offset = 0
	}
	if offset > len(body) {
		offset = len(body)
	}
	line := 1
	col := 1
	for i := 0; i < offset; i++ {
		if body[i] == '\n' {
			line++
			col = 1
			continue
		}
		col++
	}
	return line, col
}

func snippetAround(body []byte, start, end int) string {
	const window = 40
	from := start - window
	if from < 0 {
		from = 0
	}
	to := end + window
	if to > len(body) {
		to = len(body)
	}
	s := string(body[from:to])
	s = strings.ReplaceAll(s, "\n", " ")
	s = strings.ReplaceAll(s, "\r", " ")
	s = strings.TrimSpace(collapseSpaces(s))
	return s
}

func collapseSpaces(s string) string {
	var b strings.Builder
	prev := byte(0)
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c == ' ' && prev == ' ' {
			continue
		}
		b.WriteByte(c)
		prev = c
	}
	return b.String()
}
