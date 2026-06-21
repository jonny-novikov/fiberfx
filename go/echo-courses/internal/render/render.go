// Package render is the echo-courses presentation layer: a custom echo.Renderer
// over html/template. It parses the embedded template tree (web.FS) once at boot
// — one fully-resolved *template.Template per page (layout + partials + that
// page) — and fails fast: a parse error at New aborts the server boot rather
// than surfacing a broken page to a reader (ec.2 acceptance 1).
//
// The page composition is block-based: layout.html declares {{block "content" .}},
// each page supplies {{define "content"}}, and the partials (card, filter) are
// {{define}}d templates the pages invoke. Render executes "layout.html" for the
// requested page's set.
package render

import (
	"fmt"
	"html/template"
	"io"
	"io/fs"

	"github.com/labstack/echo/v5"
)

// Template-tree locations within the provided fs.FS (web.FS is rooted at web/).
const (
	layoutFile   = "templates/layout.html"
	partialsGlob = "templates/partials/*.html"
	pagesGlob    = "templates/pages/*.html"
)

// Card is the data shape the "card" partial renders — one course tile on the
// series grid. Two fields carry trusted, in-repo-authored markup (never reader
// input) and so use html/template's safe-content types:
//   - Accent is template.CSS: it lands in the style="--accent:…" custom property,
//     and html/template's CSS sanitizer does NOT recognize a var(--token) value
//     in a custom-property declaration — a plain string is silently rewritten to
//     "ZgotmplZ", dropping the accent stripe. template.CSS emits it verbatim
//     (matching the published markup's style="--accent:var(--gold-bright)").
//   - Icon is template.HTML so the inline <svg> renders unescaped.
//
// The remaining fields are plain strings, contextually escaped as text/URL/attr.
type Card struct {
	Accent  template.CSS  // CSS value for --accent (e.g. "var(--gold-bright)" or "#e0564e")
	Tags    string        // space-separated track tags for the ec.4 filter (data-tags)
	Href    string        // course link
	Icon    template.HTML // inline <svg> markup
	Eyebrow string        // the .s-eyebrow tag line
	Title   string        // the <h3> course title
	Summary string        // the <p> course summary
}

// Head is the per-page document-head payload the layout renders (ec.5 AC3): the
// boot-computed fingerprinted asset URLs (shared across every page) plus the
// page-specific SEO metadata. Each view-model embeds it (D-5 Option A — a Head
// struct in the view-model, populated by the handlers, so render.New stays
// FuncMap-free); the layout reads .Head.* in <head> and the asset <script> before
// </body>.
//
// Description is the meta description and the og:description; for the index it is
// byte-identical to the published master (ec.5 AC3 strict-parity duty), for a
// detail page it is the course Summary. CanonicalURL is CANONICAL_BASE + the
// page path (ec.5 D-2) — the <link rel="canonical"> and og:url. OGType is the
// Open Graph type ("website" for the index, "article" for a course landing).
// og:image is omitted (ec.5 D-3). All fields are plain strings, contextually
// escaped by html/template as text/URL/attr.
type Head struct {
	CSSURL       string // /static/app.<hash>.css (the boot-fingerprinted stylesheet)
	JSURL        string // /static/app.<hash>.js (the boot-fingerprinted deferred script)
	Title        string // the document <title>
	Description  string // meta description + og:description
	CanonicalURL string // CANONICAL_BASE + path (canonical link + og:url)
	OGType       string // og:type ("website" | "article")
}

// Renderer implements echo.Renderer. It holds one parsed template set per page,
// keyed by the page's base filename (e.g. "placeholder.html"). Each set carries
// the layout, every partial, and exactly that one page, so executing
// "layout.html" composes the full document.
type Renderer struct {
	pages map[string]*template.Template
}

// New parses the template tree out of fsys into one set per templates/pages/*.html.
// Each set = ParseFS(fsys, layout, partials/*, <page>). A parse failure — or a
// tree with no pages — returns a named error (render: …) so main can abort boot
// (fail-fast). The returned Renderer is ready to serve every page it parsed.
func New(fsys fs.FS) (*Renderer, error) {
	pages, err := fs.Glob(fsys, pagesGlob)
	if err != nil {
		return nil, fmt.Errorf("render: glob %s: %w", pagesGlob, err)
	}
	if len(pages) == 0 {
		return nil, fmt.Errorf("render: no pages matched %s", pagesGlob)
	}

	sets := make(map[string]*template.Template, len(pages))
	for _, page := range pages {
		name := pathBase(page)
		set, err := template.New(name).ParseFS(fsys, layoutFile, partialsGlob, page)
		if err != nil {
			return nil, fmt.Errorf("render: parse %s: %w", name, err)
		}
		sets[name] = set
	}

	return &Renderer{pages: sets}, nil
}

// Render satisfies echo.Renderer (v5: the *echo.Context is first). It looks up
// the page set by name and executes the base layout for it. An unknown page name
// is a named error rather than a silent empty body.
func (r *Renderer) Render(_ *echo.Context, w io.Writer, name string, data any) error {
	set, ok := r.pages[name]
	if !ok {
		return fmt.Errorf("render: unknown page %q", name)
	}
	return set.ExecuteTemplate(w, "layout.html", data)
}

// pathBase returns the final path element of a slash-separated fs.FS path
// (fs.FS always uses forward slashes, so this is OS-independent — unlike
// filepath.Base, which would split on backslashes on Windows).
func pathBase(p string) string {
	for i := len(p) - 1; i >= 0; i-- {
		if p[i] == '/' {
			return p[i+1:]
		}
	}
	return p
}
