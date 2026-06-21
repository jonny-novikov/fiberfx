package render_test

import (
	"bytes"
	"html/template"
	"strings"
	"testing"
	"testing/fstest"

	"github.com/fiberfx/echo-courses/internal/render"
	"github.com/fiberfx/echo-courses/web"
)

// goodTree is a minimal valid template tree (layout + the two partials + one
// page) used to isolate the malformed-page case in TestNewFailFast: only the
// page is swapped for broken markup, so a returned error is unambiguously the
// page parse, not a missing layout or partial.
func goodTree() fstest.MapFS {
	return fstest.MapFS{
		"templates/layout.html":          {Data: []byte(`{{define "layout.html"}}<!doctype html>{{block "content" .}}{{end}}{{end}}`)},
		"templates/partials/card.html":   {Data: []byte(`{{define "card"}}card{{end}}`)},
		"templates/partials/filter.html": {Data: []byte(`{{define "filter"}}filter{{end}}`)},
		"templates/pages/ok.html":        {Data: []byte(`{{define "content"}}ok{{end}}`)},
	}
}

// AC1 (fail-fast): a deliberately malformed page makes New return a NAMED error
// (render: parse <page>: …) rather than a nil Renderer the server would boot on.
func TestNewFailFast(t *testing.T) {
	tree := goodTree()
	tree["templates/pages/broken.html"] = &fstest.MapFile{Data: []byte(`{{define "content"}}{{.Unclosed`)}

	r, err := render.New(tree)
	if err == nil {
		t.Fatalf("New over a malformed template returned nil error (got renderer %v); want fail-fast", r)
	}
	if !strings.HasPrefix(err.Error(), "render: ") {
		t.Fatalf("error %q is not a named render error (want a 'render: …' prefix)", err)
	}
	if !strings.Contains(err.Error(), "broken.html") {
		t.Fatalf("error %q does not name the offending page (broken.html)", err)
	}
}

// AC1 (fail-fast, empty tree): a tree with no pages is also a named error, not a
// renderer that serves nothing.
func TestNewNoPages(t *testing.T) {
	tree := fstest.MapFS{
		"templates/layout.html":          {Data: []byte(`{{define "layout.html"}}x{{end}}`)},
		"templates/partials/card.html":   {Data: []byte(`{{define "card"}}c{{end}}`)},
		"templates/partials/filter.html": {Data: []byte(`{{define "filter"}}f{{end}}`)},
	}
	if _, err := render.New(tree); err == nil {
		t.Fatal("New over a tree with no pages returned nil error; want a named error")
	}
}

// AC1 (well-formed): New(web.FS) — the real embedded tree — succeeds and knows
// the placeholder page, so c.Render(…, "placeholder.html", …) resolves.
func TestNewEmbeddedTree(t *testing.T) {
	r, err := render.New(web.FS)
	if err != nil {
		t.Fatalf("New(web.FS) failed: %v", err)
	}
	var buf bytes.Buffer
	if err := r.Render(nil, &buf, "placeholder.html", samplePageData()); err != nil {
		t.Fatalf("Render(placeholder.html) failed — page not known: %v", err)
	}
}

// An unknown page name is a named error, not a silent empty body.
func TestRenderUnknownPage(t *testing.T) {
	r, err := render.New(web.FS)
	if err != nil {
		t.Fatalf("New(web.FS) failed: %v", err)
	}
	if err := r.Render(nil, &bytes.Buffer{}, "does-not-exist.html", nil); err == nil {
		t.Fatal("Render of an unknown page returned nil error; want a named error")
	}
}

// AC2/AC3 (ec.5): the base layout's chrome — the jonnify · courses header and the
// (с) jonnify footer (note: the с is Cyrillic, as published) — plus the
// EXTERNALIZED design system and interactivity (ec.5 D-1): the head links the
// fingerprinted app.css, the footer the deferred app.js, and the inline
// <style>/reveal-<script> source is GONE (now in web/static). The head also
// carries the per-page meta (title/description/canonical/og) from render.Head.
func TestLayoutChrome(t *testing.T) {
	out := renderPlaceholder(t)

	for _, want := range []string{
		"jonnify · courses",                // .topbar brand (AC3 header)
		"(с) jonnify",                      // <footer> (AC3 footer, Cyrillic с)
		"<title>Courses · jonnify</title>", // the title block's default
		`<link rel="stylesheet" href="/static/app.abcd1234.css">`,    // the fingerprinted CSS (from sample Head)
		`<script defer src="/static/app.beef5678.js"></script>`,      // the fingerprinted, deferred JS
		`<meta name="description" content="Sample description.">`,    // per-page description (AC3)
		`<link rel="canonical" href="https://example.test/courses">`, // canonical from the sample Head (D-2)
		`<meta property="og:title" content="Sample · jonnify">`,      // og:title (AC3)
		`<meta property="og:type" content="website">`,                // og:type (AC3)
		`<meta property="og:site_name" content="jonnify">`,           // og:site_name (AC3)
		`<meta name="twitter:card" content="summary">`,               // twitter:card (AC3)
	} {
		if !strings.Contains(out, want) {
			t.Errorf("rendered shell missing %q", want)
		}
	}
	// The inline design-system source is externalized — it must NOT ride the page.
	for _, gone := range []string{
		"--gold:#d4a85a;",      // a :root token (was inline <style>)
		".series-card{",        // courses-page chrome (was inline <style>)
		"IntersectionObserver", // the reveal logic (was inline <script>)
	} {
		if strings.Contains(out, gone) {
			t.Errorf("inline source %q still rides the page (should be externalized to web/static)", gone)
		}
	}
}

// AC4: the card partial over sample data produces the tag line, title, summary,
// and the "Open →" link — and the accent custom property survives verbatim
// (the template.CSS realization; a plain string would be ZgotmplZ).
func TestCardPartial(t *testing.T) {
	out := renderPlaceholder(t)

	for _, want := range []string{
		`<a class="series-card"`,              // the .series-card shape
		`Elixir · BEAM · English`,             // .s-eyebrow tag line
		`Functional Programming`,              // <h3> title
		`A deep dive into functional`,         // <p> summary (prefix)
		`Open →`,                              // .s-go link
		`style="--accent:var(--gold-bright)"`, // accent verbatim (realization guard)
		`data-tags="elixir"`,                  // the ec.4 filter hook
		`href="/elixir"`,                      // the course link
	} {
		if !strings.Contains(out, want) {
			t.Errorf("rendered card missing %q", want)
		}
	}
	if strings.Contains(out, "ZgotmplZ") {
		t.Error("accent was neutered to ZgotmplZ — Card.Accent must be template.CSS")
	}
}

// AC5: the filter partial yields the six facet controls (labels wired to data in
// ec.4; here they are the verbatim published markup).
func TestFilterPartial(t *testing.T) {
	out := renderPlaceholder(t)

	if got := strings.Count(out, `class="filter-btn`); got != 6 {
		t.Errorf("filter facet count = %d, want 6", got)
	}
	for _, want := range []string{
		`data-tag="all"`,
		`data-tag="elixir"`,
		`data-tag="agents"`,
		`data-tag="redis"`,
		`data-tag="echomq"`,
		`data-tag="bcs"`,
	} {
		if !strings.Contains(out, want) {
			t.Errorf("filter bar missing facet %q", want)
		}
	}
}

// --- helpers ---

func samplePageData() map[string]any {
	return map[string]any{
		// A sample Head exercises the layout's ec.5 head rendering (the
		// fingerprinted asset links + the per-page meta). The hashes are arbitrary
		// fixtures — the render layer renders whatever Head it is given; boot
		// computes the real hashes (internal/asset) and the handlers populate the
		// per-page meta.
		"Head": render.Head{
			CSSURL:       "/static/app.abcd1234.css",
			JSURL:        "/static/app.beef5678.js",
			Title:        "Sample · jonnify",
			Description:  "Sample description.",
			CanonicalURL: "https://example.test/courses",
			OGType:       "website",
		},
		"Card": render.Card{
			Accent:  template.CSS("var(--gold-bright)"),
			Tags:    "elixir",
			Href:    "/elixir",
			Icon:    template.HTML(`<svg viewBox="0 0 44 44"></svg>`),
			Eyebrow: "Elixir · BEAM · English",
			Title:   "Functional Programming",
			Summary: "A deep dive into functional programming with Elixir on the BEAM.",
		},
	}
}

func renderPlaceholder(t *testing.T) string {
	t.Helper()
	r, err := render.New(web.FS)
	if err != nil {
		t.Fatalf("New(web.FS) failed: %v", err)
	}
	var buf bytes.Buffer
	if err := r.Render(nil, &buf, "placeholder.html", samplePageData()); err != nil {
		t.Fatalf("Render(placeholder.html) failed: %v", err)
	}
	return buf.String()
}
