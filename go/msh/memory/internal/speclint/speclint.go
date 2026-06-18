// Package speclint checks a docs/specs tree for stale (broken) markdown links:
// dead relative file targets and missing heading anchors.
//
// It differs from the memory stale engine on purpose. The memory rules validate
// links against graph membership in a self-contained corpus, and linkx
// classifies any "../" or "subdir/file.md" target as external_rel — exactly the
// shapes a specs tree is full of. speclint instead resolves every relative link
// to the real filesystem, so a cross-area link (../aaw/x.md, ../../echo/...) is
// validated wherever it points. It reuses linkx for link/heading extraction and
// emits the same stale.Finding vocabulary the memory toolchain renders.
package speclint

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/jonny-novikov/msh/memory/internal/graph"
	"github.com/jonny-novikov/msh/memory/internal/linkx"
	"github.com/jonny-novikov/msh/memory/internal/stale"
	"github.com/jonny-novikov/msh/memory/internal/walker"
)

// Result is the outcome of a Check: the findings plus the number of markdown
// files walked (for an audit summary).
type Result struct {
	Findings stale.Findings
	Files    int
}

// Check walks the markdown tree rooted at area and returns one Finding per stale
// link — a dead relative file target (error) or a missing heading anchor
// (warn). File paths in findings are reported relative to displayRoot (the repo
// root) so they are clickable from there; an empty displayRoot reports absolute
// paths. Anchor targets are resolved and cached on demand, including files
// outside area (cross-area links).
func Check(area, displayRoot string) (Result, error) {
	entries, err := walker.WalkMarkdown(area)
	if err != nil {
		return Result{}, fmt.Errorf("speclint: walk %q: %w", area, err)
	}
	c := &checker{displayRoot: displayRoot, headings: make(map[string][]string)}
	var out stale.Findings
	for _, fe := range entries {
		body, err := os.ReadFile(fe.AbsPath)
		if err != nil {
			return Result{}, fmt.Errorf("speclint: read %q: %w", fe.AbsPath, err)
		}
		out = append(out, c.checkFile(fe.AbsPath, body)...)
	}
	return Result{Findings: out, Files: len(entries)}, nil
}

type checker struct {
	displayRoot string
	headings    map[string][]string // absPath -> heading slugs (cached)
}

func (c *checker) checkFile(absPath string, body []byte) stale.Findings {
	ext := linkx.Extract(filepath.ToSlash(absPath), body)
	// Seed this file's own headings so same-file "#anchor" links resolve and the
	// file is not re-read by headingsFor below.
	c.headings[absPath] = slugsOf(ext.Headings)

	fileDir := filepath.Dir(absPath)
	from := c.display(absPath)
	var out stale.Findings

	for _, e := range ext.Edges {
		path, anchor := linkx.SplitAnchor(e.To)
		switch e.Kind {
		case graph.EdgeMDLink, graph.EdgeMDLinkAnchor, graph.EdgeExternalRel, graph.EdgeCrossSubdir:
			if isOffsiteTarget(path) {
				continue // http(s)/mailto/tel or a site-absolute web route — not a filesystem link
			}
			if path == "" { // "[x](#frag)" — same-file anchor
				out = append(out, c.anchorFinding(from, e, absPath, anchor, "this file")...)
				continue
			}
			targetAbs := filepath.Clean(filepath.Join(fileDir, path))
			fi, statErr := os.Stat(targetAbs)
			if statErr != nil {
				out = append(out, stale.Finding{
					Rule:     stale.RuleDeadTarget,
					Severity: stale.SeverityError,
					File:     from,
					Line:     e.SourceLine,
					Snippet:  e.Snippet,
					Target:   e.To,
					Message:  fmt.Sprintf("link target %q does not exist (resolved to %s)", e.To, c.display(targetAbs)),
					EdgeKind: string(e.Kind),
				})
				continue
			}
			if anchor != "" && !fi.IsDir() && strings.EqualFold(filepath.Ext(targetAbs), ".md") {
				out = append(out, c.anchorFinding(from, e, targetAbs, anchor, c.display(targetAbs))...)
			}
		case graph.EdgeAnchorOnly:
			if strings.HasPrefix(e.To, "#") { // markdown "[x](#frag)"; "§…" prose mentions are skipped
				out = append(out, c.anchorFinding(from, e, absPath, anchor, "this file")...)
			}
		default:
			// code_path / bare_mention — not "[..](..)" markdown links.
		}
	}
	return out
}

// anchorFinding reports a BROKEN-ANCHOR when anchor is absent from the headings
// of headingFile; where names the file for the message ("this file" or a path).
func (c *checker) anchorFinding(from string, e graph.Edge, headingFile, anchor, where string) stale.Findings {
	if anchor == "" {
		return nil
	}
	slugs, err := c.headingsFor(headingFile)
	if err != nil {
		return nil // an unreadable target is already a dead link, reported above
	}
	if anchorMatches(slugs, anchor) {
		return nil
	}
	return stale.Findings{{
		Rule:     stale.RuleBrokenAnchor,
		Severity: stale.SeverityWarn,
		File:     from,
		Line:     e.SourceLine,
		Snippet:  e.Snippet,
		Target:   e.To,
		Message:  fmt.Sprintf("anchor %q not found among headings of %s", anchor, where),
		EdgeKind: string(e.Kind),
	}}
}

func (c *checker) headingsFor(absPath string) ([]string, error) {
	if s, ok := c.headings[absPath]; ok {
		return s, nil
	}
	body, err := os.ReadFile(absPath)
	if err != nil {
		return nil, err
	}
	s := slugsOf(linkx.Extract(filepath.ToSlash(absPath), body).Headings)
	c.headings[absPath] = s
	return s, nil
}

func (c *checker) display(absPath string) string {
	if c.displayRoot != "" {
		if rel, err := filepath.Rel(c.displayRoot, absPath); err == nil && !strings.HasPrefix(rel, "..") {
			return filepath.ToSlash(rel)
		}
	}
	return filepath.ToSlash(absPath)
}

func slugsOf(hs []linkx.Heading) []string {
	out := make([]string, 0, len(hs))
	for _, h := range hs {
		out = append(out, h.Slug)
	}
	return out
}

// anchorMatches reports whether anchor names a heading slug. The fragment in a
// well-formed link is already a slug; Slugify(anchor) is tried too so a raw
// "#The Door" still resolves.
func anchorMatches(slugs []string, anchor string) bool {
	a := strings.TrimPrefix(anchor, "#")
	slug := linkx.Slugify(a)
	for _, s := range slugs {
		if s == a || s == slug {
			return true
		}
	}
	return false
}

// isOffsiteTarget reports whether a link target is not a filesystem-relative
// path this checker can validate offline: an external URL (http(s)/mailto/tel)
// or a site-absolute web route ("/redis-patterns", "/echomq/...") that resolves
// against a web root, not the document's directory.
func isOffsiteTarget(path string) bool {
	if path == "" {
		return false
	}
	return strings.HasPrefix(path, "/") ||
		strings.Contains(path, "://") ||
		strings.HasPrefix(path, "mailto:") ||
		strings.HasPrefix(path, "tel:")
}
