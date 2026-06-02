// Package builder recomposes a decomposed page (head template + body-fragment
// template + per-page data) into the exact bytes the static server publishes.
// It is the assembler half of the filesystem-mirrored content store
// (internal/store): the store decomposes each published /elixir page, this
// package fills the templates and re-wraps them in the document envelope that
// docs/elixir/toolkit/build_page.py's _assemble emits. The envelope constants
// and the HTML-escaper live in internal/tmpl, shared with the store so both
// agree on the bytes.
package builder

import (
	"strings"

	"github.com/jonny-novikov/jonnify-cms/internal/store"
	"github.com/jonny-novikov/jonnify-cms/internal/tmpl"
)

// fillHead fills a head template's title and description placeholders with their
// HTML-escaped values, reproducing build_page.py's
// head.replace("{{TITLE}}", esc(title)).replace("{{DESC}}", esc(desc)).
//
// Replace(..., 1) fills the first occurrence; this is safe because decompose
// re-placeholds exactly one {{TITLE}} and one {{DESC}} per page (splicing the
// single captured value span) and no published head carries a duplicate literal
// placeholder. The round-trip parity test guards any future violation.
func fillHead(headTemplate []byte, title, descr string) string {
	h := strings.Replace(string(headTemplate), tmpl.PhTitle, tmpl.Esc(title), 1)
	h = strings.Replace(h, tmpl.PhDesc, tmpl.Esc(descr), 1)
	return h
}

// fillStamp fills a fragment template's build-stamp placeholders with the page's
// pinned id and timestamp. The values are inserted verbatim (they are not
// HTML-escaped: a branded id is base62 and a timestamp is digits/colons/spaces).
//
// Replace(..., 1) fills the first occurrence; this is safe because decompose
// re-placeholds at most one {{BUILD_ID}} and one {{BUILD_TS}} per page and no
// published fragment carries a duplicate literal placeholder. The round-trip
// parity test guards any future violation.
func fillStamp(fragment []byte, buildID, buildTS string) string {
	f := strings.Replace(string(fragment), tmpl.PhBuildID, buildID, 1)
	f = strings.Replace(f, tmpl.PhBuildTS, buildTS, 1)
	return f
}

// Assemble recomposes the published document for a page from its head template
// and its stored data. The result reproduces _assemble's return value exactly:
// DOCTYPE + filled head + "\n<body>\n" + filled fragment + "\n" + BOOTSTRAP +
// "\n</body>\n</html>\n".
func Assemble(headTemplate []byte, p store.Page) []byte {
	var b strings.Builder
	b.Grow(len(tmpl.DOCTYPE) + len(headTemplate) + len(tmpl.BodySep) + len(p.Fragment) + len(tmpl.Suffix))
	b.WriteString(tmpl.DOCTYPE)
	b.WriteString(fillHead(headTemplate, p.Title, p.Descr))
	b.WriteString(tmpl.BodySep)
	b.WriteString(fillStamp(p.Fragment, p.BuildID, p.BuildTS))
	b.WriteString(tmpl.Suffix)
	return []byte(b.String())
}

// BuildFromStore assembles the published document for a clean route by reading
// the page and its head template from the store.
func BuildFromStore(s *store.Store, route string) ([]byte, error) {
	p, head, err := s.Get(route)
	if err != nil {
		return nil, err
	}
	return Assemble(head, p), nil
}
