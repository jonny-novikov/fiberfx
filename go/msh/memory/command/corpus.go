package command

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/jonny-novikov/msh/memory/internal/frontmatter"
	"github.com/jonny-novikov/msh/memory/internal/graph"
	"github.com/jonny-novikov/msh/memory/internal/linkx"
	"github.com/jonny-novikov/msh/memory/internal/walker"
)

type corpusSource struct {
	root     string
	bodies   map[string][]byte
	headings map[string][]string
}

func loadCorpus(root string) (*graph.Graph, *corpusSource, error) {
	entries, err := walker.WalkMarkdown(root)
	if err != nil {
		return nil, nil, fmt.Errorf("walk %q: %w", root, err)
	}
	g := graph.New(root)
	src := &corpusSource{
		root:     root,
		bodies:   make(map[string][]byte, len(entries)),
		headings: make(map[string][]string, len(entries)),
	}

	for _, fe := range entries {
		body, err := os.ReadFile(fe.AbsPath)
		if err != nil {
			return nil, nil, fmt.Errorf("read %q: %w", fe.AbsPath, err)
		}
		src.bodies[fe.RelPath] = body

		fmRes := frontmatter.Parse(body)
		node := &graph.Node{
			Path:           fe.RelPath,
			AbsPath:        fe.AbsPath,
			SizeBytes:      fe.Size,
			Status:         graph.StatusActive,
			HasFrontmatter: fmRes.Has,
			SHA256:         hashBody(body),
		}
		if fmRes.Has {
			node.Name = fmRes.Frontmatter.Name
			node.Description = fmRes.Frontmatter.Description
			node.OriginSessionID = fmRes.Frontmatter.OriginSessionID
			node.Type = classifyType(fmRes.Frontmatter.Type, fe.RelPath)
			node.Project = normalizeProject(fmRes.Frontmatter.Project)
			node.ReviewAfter = strings.TrimSpace(fmRes.Frontmatter.ReviewAfter)
			if fmRes.ParseError != "" {
				node.FrontmatterError = fmRes.ParseError
			}
		} else {
			node.Type = classifyType("", fe.RelPath)
		}
		// effective_project (msh2.2 §3.3), computed once at load — the one
		// authority every surface reads: the declared top-level project: wins;
		// else a nested note scopes to its first path segment; else unscoped.
		if node.Project == "" {
			if parts := strings.SplitN(fe.RelPath, "/", 2); len(parts) == 2 {
				node.Project = normalizeProject(parts[0])
			}
		}
		// status precedence (msh2.2 §3.4): a present + valid declared status:
		// IS the status and the body sniff is skipped; an invalid value records
		// a FrontmatterError and degrades loudly to the sniff; an absent key
		// keeps the sniff fallback byte-unchanged.
		statusDeclared := false
		if fmRes.Has {
			if raw := strings.TrimSpace(fmRes.Frontmatter.Status); raw != "" {
				switch graph.Status(strings.ToLower(raw)) {
				case graph.StatusActive:
					node.Status = graph.StatusActive
					statusDeclared = true
				case graph.StatusSuperseded:
					node.Status = graph.StatusSuperseded
					statusDeclared = true
				default:
					node.FrontmatterError = fmt.Sprintf("invalid status %q: want active|superseded", raw)
				}
			}
		}
		if !statusDeclared && isSupersededByText(body, fmRes.BodyOffset) {
			node.Status = graph.StatusSuperseded
		}
		if err := g.AddNode(node); err != nil {
			return nil, nil, err
		}

		extracted := linkx.Extract(fe.RelPath, body)
		slugs := make([]string, 0, len(extracted.Headings))
		for _, h := range extracted.Headings {
			slugs = append(slugs, h.Slug)
		}
		src.headings[fe.RelPath] = slugs
		for _, e := range extracted.Edges {
			g.AddEdge(e)
		}
	}

	g.ResolveEdges()
	return g, src, nil
}

func classifyType(rawType, relPath string) graph.NodeType {
	switch strings.ToLower(strings.TrimSpace(rawType)) {
	case "feedback":
		return graph.NodeFeedback
	case "project":
		return graph.NodeProject
	case "reference":
		return graph.NodeReference
	case "law":
		return graph.NodeLaw
	case "session_pause", "session-pause":
		return graph.NodeSession
	case "index":
		return graph.NodeIndex
	}
	base := filepath.Base(relPath)
	switch base {
	case "MEMORY.md", "completed-projects.md":
		return graph.NodeIndex
	}
	if strings.HasSuffix(relPath, "feedback-index.md") {
		return graph.NodeIndex
	}
	if strings.HasPrefix(base, "law") {
		return graph.NodeLaw
	}
	if strings.HasPrefix(base, "session_pause") || strings.HasPrefix(base, "session-pause") {
		return graph.NodeSession
	}
	if strings.HasPrefix(base, "feedback_") {
		return graph.NodeFeedback
	}
	if strings.HasPrefix(base, "project_") {
		return graph.NodeProject
	}
	if strings.HasPrefix(base, "reference_") {
		return graph.NodeReference
	}
	return graph.NodeUnknown
}

func isSupersededByText(body []byte, bodyOffset int) bool {
	if bodyOffset >= len(body) {
		return false
	}
	rest := body[bodyOffset:]
	const window = 1024
	if len(rest) > window {
		rest = rest[:window]
	}
	lower := strings.ToLower(string(rest))
	if strings.Contains(lower, "(superseded") || strings.Contains(lower, "[superseded") {
		return true
	}
	if strings.Contains(lower, "> **superseded") || strings.Contains(lower, "> superseded") {
		return true
	}
	return false
}

func hashBody(body []byte) string {
	sum := sha256.Sum256(body)
	return hex.EncodeToString(sum[:])
}

func (c *corpusSource) Body(path string) ([]byte, error) {
	if b, ok := c.bodies[path]; ok {
		return b, nil
	}
	return nil, fmt.Errorf("corpus: no body for %q", path)
}

func (c *corpusSource) HeadingSlugs(path string) ([]string, error) {
	if s, ok := c.headings[path]; ok {
		return s, nil
	}
	return nil, fmt.Errorf("corpus: no headings for %q", path)
}

func (c *corpusSource) Exists(repoRel string) bool {
	abs := filepath.Join(c.root, repoRel)
	if _, err := os.Stat(abs); err == nil {
		return true
	}
	parent := filepath.Dir(c.root)
	if parent != c.root {
		abs = filepath.Join(parent, repoRel)
		if _, err := os.Stat(abs); err == nil {
			return true
		}
	}
	return false
}
