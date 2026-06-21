package handler_test

import (
	"encoding/xml"
	"net/http"
	"strings"
	"testing"

	"github.com/fiberfx/echo-courses/content"
	"github.com/fiberfx/echo-courses/internal/catalog"
)

// AC4: GET /sitemap.xml is a well-formed urlset that lists /courses plus every
// published course Path, each absolute under the canonical base (testBase, D-2).
func TestSitemap(t *testing.T) {
	e := newServer(t)
	code, body := get(t, e, "/sitemap.xml")
	if code != http.StatusOK {
		t.Fatalf("GET /sitemap.xml = %d, want 200", code)
	}

	// Well-formed XML with the sitemaps.org namespace.
	type loc struct {
		Loc string `xml:"loc"`
	}
	var doc struct {
		XMLName xml.Name `xml:"urlset"`
		XMLNS   string   `xml:"xmlns,attr"`
		URLs    []loc    `xml:"url"`
	}
	if err := xml.Unmarshal([]byte(body), &doc); err != nil {
		t.Fatalf("sitemap is not well-formed XML: %v\n%s", err, body)
	}
	if doc.XMLNS != "http://www.sitemaps.org/schemas/sitemap/0.9" {
		t.Errorf("sitemap xmlns = %q, want the sitemaps.org 0.9 namespace", doc.XMLNS)
	}

	got := make(map[string]bool, len(doc.URLs))
	for _, u := range doc.URLs {
		got[u.Loc] = true
	}

	// /courses + each published path, absolute under testBase.
	want := []string{testBase + "/courses"}
	cat, err := catalog.Load(content.FS)
	if err != nil {
		t.Fatalf("catalog.Load: %v", err)
	}
	for i := range cat.Courses {
		want = append(want, testBase+cat.Courses[i].Path)
	}
	for _, w := range want {
		if !got[w] {
			t.Errorf("sitemap missing %q", w)
		}
	}
	// The five course paths + /courses = six entries (no extras).
	if len(doc.URLs) != len(cat.Courses)+1 {
		t.Errorf("sitemap has %d urls, want %d (/courses + %d courses)", len(doc.URLs), len(cat.Courses)+1, len(cat.Courses))
	}
}

// AC4: GET /robots.txt is a valid robots file — an allow-all policy with a
// Sitemap: line pointing at the canonical sitemap URL (testBase, D-2).
func TestRobots(t *testing.T) {
	e := newServer(t)
	code, body := get(t, e, "/robots.txt")
	if code != http.StatusOK {
		t.Fatalf("GET /robots.txt = %d, want 200", code)
	}
	for _, want := range []string{
		"User-agent: *",
		"Allow: /",
		"Sitemap: " + testBase + "/sitemap.xml",
	} {
		if !strings.Contains(body, want) {
			t.Errorf("robots.txt missing %q\n%s", want, body)
		}
	}
}

// AC3: the index head carries the published meta description byte-identical, the
// Open Graph tags, a canonical from testBase (D-2), and twitter:card=summary. The
// canonical reflecting testBase (not the production default) proves CANONICAL_BASE
// is CONSUMED, not a dead key (ec.5 §ec5-risks).
func TestIndexHead(t *testing.T) {
	e := newServer(t)
	_, body := get(t, e, "/")

	// The published master's meta description, byte-identical (html/index.html:7).
	const published = `<meta name="description" content="jonnify courses — five in-depth, English-language courses built on the jonnify design system: Functional Programming in Elixir on the BEAM, the Agile Agent Workflow for shipping reliable software with Claude agents, Redis Patterns Applied — the Redis design patterns taught on a real job queue and platform — EchoMQ, that job-queue protocol taught in depth as it is built, and the Branded Component System — identity as a contract, proven across five runtimes.">`
	for _, want := range []string{
		published,
		`<link rel="canonical" href="https://example.test/courses">`, // canonical from testBase (D-2 consumed)
		`<meta property="og:title" content="Courses · jonnify">`,
		`<meta property="og:type" content="website">`,
		`<meta property="og:url" content="https://example.test/courses">`,
		`<meta property="og:site_name" content="jonnify">`,
		`<meta name="twitter:card" content="summary">`,
		`<title>Courses · jonnify</title>`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("index head missing %q", want)
		}
	}
	// og:image is OMITTED (ec.5 D-3).
	if strings.Contains(body, "og:image") {
		t.Error("index head carries og:image, which D-3 omits")
	}
}

// AC3: a detail page's head description is the course Summary, its canonical/og:url
// are testBase + the course Path (D-2), and og:type is article.
func TestDetailHead(t *testing.T) {
	cat, err := catalog.Load(content.FS)
	if err != nil {
		t.Fatalf("catalog.Load: %v", err)
	}
	e := newServer(t)

	for i := range cat.Courses {
		c := &cat.Courses[i]
		_, body := get(t, e, c.Path)

		wantDesc := `<meta name="description" content="` + htmlEscape(c.Summary) + `">`
		if !strings.Contains(body, wantDesc) {
			t.Errorf("%s head description != the course Summary\n  want %q", c.Path, wantDesc)
		}
		wantCanon := `<link rel="canonical" href="` + testBase + c.Path + `">`
		if !strings.Contains(body, wantCanon) {
			t.Errorf("%s head missing canonical %q", c.Path, wantCanon)
		}
		wantOGURL := `<meta property="og:url" content="` + testBase + c.Path + `">`
		if !strings.Contains(body, wantOGURL) {
			t.Errorf("%s head missing og:url %q", c.Path, wantOGURL)
		}
		if !strings.Contains(body, `<meta property="og:type" content="article">`) {
			t.Errorf("%s head missing og:type=article", c.Path)
		}
	}
}

// htmlEscape mirrors html/template's text-context escaping for the few entities a
// course Summary may contain (& < > " '), so a head assertion compares against the
// escaped form the template emits. The catalog summaries are plain prose, but a
// future summary with an ampersand must still match.
func htmlEscape(s string) string {
	r := strings.NewReplacer(
		"&", "&amp;",
		"<", "&lt;",
		">", "&gt;",
		`"`, "&#34;",
		"'", "&#39;",
	)
	return r.Replace(s)
}
