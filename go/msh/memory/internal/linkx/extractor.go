package linkx

import (
	"regexp"
	"strings"

	"github.com/jonny-novikov/msh/memory/internal/graph"
)

var (
	mdLinkRE      = regexp.MustCompile(`\[([^\]]*)\]\(([^)\s]+)\)`)
	codePathRE    = regexp.MustCompile(`\b(?:apps|tools|phoenix|dev|memory|agents)/[A-Za-z0-9._/-]+`)
	bareMentionRE = regexp.MustCompile(`\b(feedback|law3|law|project|reference|session_pause|completed-projects)[A-Za-z0-9_-]*\.md\b`)
	anchorOnlyRE  = regexp.MustCompile(`§[A-Za-z0-9._-]+(?:\s+\d+(?:\.\d+)*)?`)
	headingRE     = regexp.MustCompile(`(?m)^(#{1,6})\s+(.+?)\s*$`)
)

type Extracted struct {
	Edges    []graph.Edge
	Headings []Heading
}

type Heading struct {
	Level int
	Text  string
	Slug  string
	Line  int
}

func Extract(fromPath string, body []byte) Extracted {
	mask := MaskCodeBlocks(body)
	headings := extractHeadings(body)
	var edges []graph.Edge

	mdLinkSpans := extractMDLinkSpans(body)
	edges = append(edges, extractMDLinks(fromPath, body, mask, mdLinkSpans)...)
	edges = append(edges, extractCodePaths(fromPath, body, mask)...)
	edges = append(edges, extractBareMentions(fromPath, body, mask, mdLinkSpans)...)
	edges = append(edges, extractAnchorOnly(fromPath, body, mask)...)

	dedupe := dedupeEdges(edges)
	return Extracted{
		Edges:    dedupe,
		Headings: headings,
	}
}

func extractMDLinkSpans(body []byte) []InlineSpan {
	matches := mdLinkRE.FindAllSubmatchIndex(body, -1)
	out := make([]InlineSpan, 0, len(matches))
	for _, m := range matches {
		out = append(out, InlineSpan{Start: m[0], End: m[1]})
	}
	return out
}

func offsetInsideAnySpan(spans []InlineSpan, offset int) bool {
	for _, s := range spans {
		if offset >= s.Start && offset < s.End {
			return true
		}
	}
	return false
}

func extractMDLinks(fromPath string, body []byte, mask Mask, _ []InlineSpan) []graph.Edge {
	var out []graph.Edge
	matches := mdLinkRE.FindAllSubmatchIndex(body, -1)
	for _, m := range matches {
		fullStart, fullEnd := m[0], m[1]
		targetStart, targetEnd := m[4], m[5]
		if mask.InCode[fullStart] {
			continue
		}
		target := string(body[targetStart:targetEnd])
		kind := ClassifyMDLink(target)
		line, col := offsetLineCol(body, fullStart)
		path, anchor := SplitAnchor(target)
		_ = path
		out = append(out, graph.Edge{
			From:       fromPath,
			To:         target,
			Kind:       kind,
			SourceLine: line,
			SourceCol:  col,
			Snippet:    snippetAround(body, fullStart, fullEnd),
			Anchor:     anchor,
		})
	}
	return out
}

func extractCodePaths(fromPath string, body []byte, mask Mask) []graph.Edge {
	var out []graph.Edge
	spans := ExtractInlineCodeRegions(body)
	for _, span := range spans {
		region := body[span.Start:span.End]
		matches := codePathRE.FindAllIndex(region, -1)
		for _, m := range matches {
			absStart := span.Start + m[0]
			absEnd := span.Start + m[1]
			if isInsideTripleFence(body, absStart) {
				continue
			}
			target := string(body[absStart:absEnd])
			line, col := offsetLineCol(body, absStart)
			out = append(out, graph.Edge{
				From:        fromPath,
				To:          target,
				Kind:        graph.EdgeCodePath,
				SourceLine:  line,
				SourceCol:   col,
				Snippet:     snippetAround(body, absStart, absEnd),
				InCodeBlock: false,
			})
		}
	}
	return out
}

func extractBareMentions(fromPath string, body []byte, mask Mask, mdLinkSpans []InlineSpan) []graph.Edge {
	var out []graph.Edge
	matches := bareMentionRE.FindAllIndex(mask.Masked, -1)
	for _, m := range matches {
		start, end := m[0], m[1]
		if mask.InCode[start] {
			continue
		}
		if offsetInsideAnySpan(mdLinkSpans, start) {
			continue
		}
		target := string(body[start:end])
		line, col := offsetLineCol(body, start)
		out = append(out, graph.Edge{
			From:       fromPath,
			To:         target,
			Kind:       graph.EdgeBareMention,
			SourceLine: line,
			SourceCol:  col,
			Snippet:    snippetAround(body, start, end),
		})
	}
	return out
}

func extractAnchorOnly(fromPath string, body []byte, mask Mask) []graph.Edge {
	var out []graph.Edge
	matches := anchorOnlyRE.FindAllIndex(mask.Masked, -1)
	for _, m := range matches {
		start, end := m[0], m[1]
		if mask.InCode[start] {
			continue
		}
		target := string(body[start:end])
		line, col := offsetLineCol(body, start)
		out = append(out, graph.Edge{
			From:       fromPath,
			To:         target,
			Kind:       graph.EdgeAnchorOnly,
			SourceLine: line,
			SourceCol:  col,
			Snippet:    snippetAround(body, start, end),
			Anchor:     strings.TrimPrefix(target, "§"),
		})
	}
	return out
}

func extractHeadings(body []byte) []Heading {
	var out []Heading
	matches := headingRE.FindAllSubmatchIndex(body, -1)
	for _, m := range matches {
		levelStart, levelEnd := m[2], m[3]
		textStart, textEnd := m[4], m[5]
		level := levelEnd - levelStart
		text := string(body[textStart:textEnd])
		line, _ := offsetLineCol(body, m[0])
		out = append(out, Heading{
			Level: level,
			Text:  text,
			Slug:  Slugify(text),
			Line:  line,
		})
	}
	return out
}

func Slugify(text string) string {
	lower := strings.ToLower(text)
	var b strings.Builder
	prevDash := false
	for _, r := range lower {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9':
			b.WriteRune(r)
			prevDash = false
		case r == ' ', r == '-', r == '_':
			if !prevDash && b.Len() > 0 {
				b.WriteByte('-')
				prevDash = true
			}
		}
	}
	out := b.String()
	out = strings.TrimRight(out, "-")
	return out
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
	return strings.TrimSpace(collapseSpaces(s))
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

func dedupeEdges(edges []graph.Edge) []graph.Edge {
	seen := make(map[string]bool, len(edges))
	out := make([]graph.Edge, 0, len(edges))
	for _, e := range edges {
		key := edgeKey(e)
		if seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, e)
	}
	return out
}

func edgeKey(e graph.Edge) string {
	var b strings.Builder
	b.WriteString(e.From)
	b.WriteByte('|')
	b.WriteString(e.To)
	b.WriteByte('|')
	b.WriteString(string(e.Kind))
	b.WriteByte('|')
	b.WriteString(itoa(e.SourceLine))
	b.WriteByte('|')
	b.WriteString(itoa(e.SourceCol))
	return b.String()
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	neg := n < 0
	if neg {
		n = -n
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	if neg {
		i--
		buf[i] = '-'
	}
	return string(buf[i:])
}
