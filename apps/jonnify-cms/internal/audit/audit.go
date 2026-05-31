// Package audit finds broken internal links across the built /elixir tree and,
// where a broken route is backed by a mis-slugged "orphan" page (a file whose
// own route-tag advertises the clean URL it is missing from), proposes or
// applies a rename. Deliberate placeholders — planned modules rendered as
// non-linking cards or <dt> items — are not links and are never flagged.
package audit

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/jonny-novikov/jonnify-cms/internal/manifest"
	"github.com/jonny-novikov/jonnify-cms/internal/site"
)

var (
	hrefRE     = regexp.MustCompile(`href="([^"]+)"`)
	routeTagRE = regexp.MustCompile(`class="route-tag"[^>]*>\s*([^<]+?)\s*<`)
)

// Ref is one occurrence of an internal link.
type Ref struct {
	File string `json:"file"`
	Line int    `json:"line"`
	Href string `json:"href"`
}

// Broken is a referenced route with no backing file.
type Broken struct {
	Route     string `json:"route"`
	Refs      []Ref  `json:"refs"`
	Orphan    string `json:"orphan,omitempty"`
	Canonical string `json:"canonical,omitempty"`
}

// RouteIssue is a declared-linkable manifest route that does not resolve.
type RouteIssue struct {
	Route string `json:"route"`
	Note  string `json:"note"`
}

// Report is the full audit result.
type Report struct {
	Root             string       `json:"root"`
	Pages            int          `json:"pages"`
	RefCount         int          `json:"ref_count"`
	BrokenLinks      []Broken     `json:"broken_links"`
	UnresolvedRoutes []RouteIssue `json:"unresolved_routes"`
}

func scan(root string) (refs []Ref, routeTags map[string]string, pages int, err error) {
	routeTags = map[string]string{}
	err = filepath.WalkDir(root, func(p string, d os.DirEntry, e error) error {
		if e != nil {
			return e
		}
		if d.IsDir() || !strings.HasSuffix(d.Name(), ".html") {
			return nil
		}
		pages++
		f, e := os.Open(p)
		if e != nil {
			return e
		}
		defer f.Close()
		sc := bufio.NewScanner(f)
		sc.Buffer(make([]byte, 1<<20), 1<<20)
		ln := 0
		for sc.Scan() {
			ln++
			line := sc.Text()
			for _, m := range hrefRE.FindAllStringSubmatch(line, -1) {
				if strings.HasPrefix(m[1], "/elixir") {
					refs = append(refs, Ref{File: p, Line: ln, Href: m[1]})
				}
			}
			if rt := routeTagRE.FindStringSubmatch(line); rt != nil {
				r := strings.TrimSpace(rt[1])
				if strings.HasPrefix(r, "/elixir") {
					if _, exists := routeTags[r]; !exists {
						routeTags[r] = p
					}
				}
			}
		}
		return sc.Err()
	})
	return
}

// Run scans root and reports broken links and unresolved declared routes.
func Run(root string) (Report, error) {
	refs, routeTags, pages, err := scan(root)
	if err != nil {
		return Report{}, err
	}
	byRoute := map[string][]Ref{}
	for _, r := range refs {
		byRoute[r.Href] = append(byRoute[r.Href], r)
	}

	var broken []Broken
	for route, rs := range byRoute {
		if _, ok, _ := site.Resolve(root, route); ok {
			continue
		}
		b := Broken{Route: route, Refs: rs}
		if orphan, ok := routeTags[route]; ok {
			b.Orphan = orphan
			b.Canonical = site.CanonicalFile(root, route)
		}
		sort.Slice(b.Refs, func(i, j int) bool {
			if b.Refs[i].File != b.Refs[j].File {
				return b.Refs[i].File < b.Refs[j].File
			}
			return b.Refs[i].Line < b.Refs[j].Line
		})
		broken = append(broken, b)
	}
	sort.Slice(broken, func(i, j int) bool { return broken[i].Route < broken[j].Route })

	var unresolved []RouteIssue
	for route := range manifest.AllowedRoutes() {
		if _, ok, note := site.Resolve(root, route); !ok {
			unresolved = append(unresolved, RouteIssue{Route: route, Note: note})
		}
	}
	sort.Slice(unresolved, func(i, j int) bool { return unresolved[i].Route < unresolved[j].Route })

	return Report{Root: root, Pages: pages, RefCount: len(refs), BrokenLinks: broken, UnresolvedRoutes: unresolved}, nil
}

// ApplyFix renames a broken route's orphan file to its canonical clean-URL name.
func ApplyFix(b Broken) (string, error) {
	if b.Orphan == "" || b.Canonical == "" {
		return "", fmt.Errorf("no orphan file identified for %s", b.Route)
	}
	if b.Orphan == b.Canonical {
		return "", fmt.Errorf("orphan already at canonical path for %s", b.Route)
	}
	if _, err := os.Stat(b.Canonical); err == nil {
		return "", fmt.Errorf("canonical path %s already exists", b.Canonical)
	}
	if err := os.Rename(b.Orphan, b.Canonical); err != nil {
		return "", err
	}
	return fmt.Sprintf("renamed %s -> %s", b.Orphan, b.Canonical), nil
}
