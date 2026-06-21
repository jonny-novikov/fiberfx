// Package catalog is the echo-courses content model: the Course record and the
// file-backed loader that reads content/<slug>.html (a YAML front-matter block
// fenced by --- lines, then a raw-HTML body) into one declarative catalog. The
// index, the filter counts, and the ec.4 routes all derive from this catalog
// rather than hand-written markup, so adding a course is adding one file
// (ec.3 — course catalog & content model).
//
// Storage is HTML body + YAML front-matter (the Operator's ec.3 ruling; roadmap
// §7 decision 3) — no Markdown engine. The front-matter parses via gopkg.in/yaml.v3;
// the body becomes template.HTML (trusted, in-repo-authored markup, never reader
// input). Load is fail-fast: a missing required field, a duplicate slug, or an
// unreadable / front-matter-less file returns a named error so the boot aborts
// before the server ever binds (mirroring the render layer's fail-fast at boot).
package catalog

import (
	"bytes"
	"fmt"
	"html/template"
	"io/fs"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
)

// contentExt is the extension of a per-course source file within the provided
// fs.FS. Load walks every *.html in the tree (the embedded corpus is flat, but a
// walk is robust to any layout and makes a slug collision — two files at
// different depths reducing to the same slug — a real, testable failure).
const contentExt = ".html"

// frontMatterFence is the line that opens and closes a course file's YAML
// front-matter block. The first line of a content file must be exactly this.
const frontMatterFence = "---"

// Course is one course in the catalog. Slug is derived from the filename
// (content/<slug>.html); every other field comes from the YAML front-matter
// except Body, which is the HTML after the front-matter block.
//
// Two fields carry trusted, in-repo-authored markup (never reader input) and so
// use html/template's safe-content types, matching the render.Card contract:
//   - Accent is template.CSS so a var(--token) custom-property value survives
//     verbatim — html/template's CSS sanitizer rewrites a plain string to
//     "ZgotmplZ", which would drop the accent stripe.
//   - Icon and Body are template.HTML so the inline <svg> and the body markup
//     render unescaped.
type Course struct {
	Slug    string        // from the filename (content/<slug>.html)
	Order   int           // front-matter; sort key for published order
	Title   string        // front-matter
	Tracks  []string      // front-matter (the eyebrow labels, e.g. ["Elixir","BEAM"])
	Facet   string        // front-matter (the filter facet: Elixir|Redis|EchoMQ|Agents|BCS)
	Summary string        // front-matter
	Path    string        // front-matter (the published URL)
	Accent  template.CSS  // front-matter (the --accent value, e.g. var(--gold-bright) or #e0564e)
	Icon    template.HTML // front-matter (the card svg, verbatim from html/index.html)
	Body    template.HTML // the HTML after the front-matter block
}

// Facet is one entry in the catalog's filter index: a display Label, the
// lower-cased Key the ec.4 filter matches on, and the Count of courses under it.
// The "All" facet (Key "all") spans every course.
type Facet struct {
	Label string
	Key   string
	Count int
}

// Catalog is the loaded set of courses plus the filter index derived from it.
// Courses is ordered by Course.Order (published order). Facets begins with the
// All facet, then one facet per distinct Course.Facet in first-seen
// (published) order.
type Catalog struct {
	Courses []Course
	Facets  []Facet
}

// courseMeta is the YAML front-matter shape. It mirrors Course minus the
// filename-derived Slug and the post-front-matter Body, with the safe-content
// fields decoded as plain strings (yaml.v3 cannot unmarshal into template.CSS /
// template.HTML directly) and converted in Load.
type courseMeta struct {
	Order   int      `yaml:"order"`
	Title   string   `yaml:"title"`
	Tracks  []string `yaml:"tracks"`
	Facet   string   `yaml:"facet"`
	Summary string   `yaml:"summary"`
	Path    string   `yaml:"path"`
	Accent  string   `yaml:"accent"`
	Icon    string   `yaml:"icon"`
}

// Load reads every content/<slug>.html out of fsys, splits each file's YAML
// front-matter from its HTML body, and assembles an ordered catalog plus the
// filter index. It is fail-fast — the first error stops the load and returns a
// named "catalog: …" error so the caller can abort boot:
//
//   - an unreadable file, or one whose first line is not the --- fence, or an
//     unterminated front-matter block;
//   - a front-matter block that does not parse as YAML;
//   - a missing required field (order, title, tracks, facet, summary, path,
//     accent, icon);
//   - a duplicate slug (two files producing the same slug).
//
// On success Courses is sorted by Order and Facets carries the All facet plus
// one entry per distinct Facet (Key = strings.ToLower(Facet)) in published order.
func Load(fsys fs.FS) (*Catalog, error) {
	var files []string
	err := fs.WalkDir(fsys, ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return fmt.Errorf("catalog: walk %s: %w", p, err)
		}
		if !d.IsDir() && strings.HasSuffix(p, contentExt) {
			files = append(files, p)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	if len(files) == 0 {
		return nil, fmt.Errorf("catalog: no course files (*%s) found", contentExt)
	}
	// Walk order is lexical and deterministic; Courses is re-sorted by Order
	// below, so file order only affects which file "wins" a duplicate-slug
	// report — keep it stable.
	sort.Strings(files)

	courses := make([]Course, 0, len(files))
	seen := make(map[string]string, len(files)) // slug -> first file that defined it
	for _, file := range files {
		course, err := loadCourse(fsys, file)
		if err != nil {
			return nil, err
		}
		if prev, dup := seen[course.Slug]; dup {
			return nil, fmt.Errorf("catalog: duplicate slug %q in %s (already defined by %s)", course.Slug, file, prev)
		}
		seen[course.Slug] = file
		courses = append(courses, course)
	}

	sort.SliceStable(courses, func(i, j int) bool { return courses[i].Order < courses[j].Order })

	return &Catalog{
		Courses: courses,
		Facets:  buildFacets(courses),
	}, nil
}

// loadCourse reads and parses one content file into a Course. The slug is the
// filename without its .html extension; the body is the trimmed HTML after the
// closing front-matter fence.
func loadCourse(fsys fs.FS, file string) (Course, error) {
	slug := strings.TrimSuffix(pathBase(file), ".html")

	raw, err := fs.ReadFile(fsys, file)
	if err != nil {
		return Course{}, fmt.Errorf("catalog: read %s: %w", file, err)
	}

	front, body, err := splitFrontMatter(raw)
	if err != nil {
		return Course{}, fmt.Errorf("catalog: %s: %w", file, err)
	}

	var meta courseMeta
	if err := yaml.Unmarshal(front, &meta); err != nil {
		return Course{}, fmt.Errorf("catalog: %s: parse front-matter: %w", file, err)
	}

	course := Course{
		Slug:    slug,
		Order:   meta.Order,
		Title:   meta.Title,
		Tracks:  meta.Tracks,
		Facet:   meta.Facet,
		Summary: meta.Summary,
		Path:    meta.Path,
		Accent:  template.CSS(meta.Accent),
		Icon:    template.HTML(meta.Icon),
		Body:    template.HTML(bytes.TrimSpace(body)),
	}
	if err := validate(course, file); err != nil {
		return Course{}, err
	}
	return course, nil
}

// splitFrontMatter separates a content file's leading YAML front-matter block
// from its HTML body. The file must open with a --- fence line; the front-matter
// runs to the next --- fence line; everything after is the body. A file with no
// opening fence, or an unterminated block, is an error (a front-matter-less file
// is rejected, per the fail-fast contract).
func splitFrontMatter(raw []byte) (front, body []byte, err error) {
	lines := bytes.SplitN(raw, []byte("\n"), 2)
	if len(lines) < 2 || strings.TrimRight(string(lines[0]), "\r") != frontMatterFence {
		return nil, nil, fmt.Errorf("missing front-matter: file must open with a %q fence", frontMatterFence)
	}

	rest := lines[1]
	// Find the closing fence: a line that is exactly --- (allowing a trailing \r).
	for {
		seg := bytes.SplitN(rest, []byte("\n"), 2)
		if strings.TrimRight(string(seg[0]), "\r") == frontMatterFence {
			if len(seg) == 2 {
				body = seg[1]
			}
			return front, body, nil
		}
		front = append(front, seg[0]...)
		front = append(front, '\n')
		if len(seg) < 2 {
			return nil, nil, fmt.Errorf("unterminated front-matter: no closing %q fence", frontMatterFence)
		}
		rest = seg[1]
	}
}

// validate enforces that every required field is present; the first missing one
// is a named error citing the file and the field.
func validate(c Course, file string) error {
	missing := func(field string) error {
		return fmt.Errorf("catalog: %s: missing required field %q", file, field)
	}
	switch {
	case c.Order == 0:
		return missing("order")
	case c.Title == "":
		return missing("title")
	case len(c.Tracks) == 0:
		return missing("tracks")
	case c.Facet == "":
		return missing("facet")
	case c.Summary == "":
		return missing("summary")
	case c.Path == "":
		return missing("path")
	case c.Accent == "":
		return missing("accent")
	case c.Icon == "":
		return missing("icon")
	}
	return nil
}

// buildFacets derives the filter index from the ordered courses: the All facet
// first (Count = len(courses)), then one facet per distinct Course.Facet in
// first-seen (published) order, each Count being the number of courses with that
// facet. Key is strings.ToLower(Facet); the All facet's Key is "all".
func buildFacets(courses []Course) []Facet {
	facets := []Facet{{Label: "All", Key: "all", Count: len(courses)}}
	idx := map[string]int{} // facet label -> position in facets
	for _, c := range courses {
		if pos, ok := idx[c.Facet]; ok {
			facets[pos].Count++
			continue
		}
		idx[c.Facet] = len(facets)
		facets = append(facets, Facet{Label: c.Facet, Key: strings.ToLower(c.Facet), Count: 1})
	}
	return facets
}

// pathBase returns the final path element of a slash-separated fs.FS path
// (fs.FS always uses forward slashes, so this is OS-independent — unlike
// filepath.Base, which would split on backslashes on Windows). Mirrors the
// render package's helper of the same name.
func pathBase(p string) string {
	for i := len(p) - 1; i >= 0; i-- {
		if p[i] == '/' {
			return p[i+1:]
		}
	}
	return p
}
