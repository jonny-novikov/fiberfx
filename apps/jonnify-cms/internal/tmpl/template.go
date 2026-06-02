// Package tmpl holds the page-envelope constants and the HTML-escaper shared by
// the content store (internal/store, which decomposes published pages) and the
// assembler (internal/builder, which recomposes them). Keeping these primitives
// in one leaf package lets the store and the builder agree on the exact bytes
// without a dependency cycle between them.
//
// DOCTYPE, BodySep, BOOTSTRAP, and Suffix are copied byte-for-byte from
// docs/elixir/toolkit/build_page.py's _assemble so the recomposed document
// matches the published file exactly. Esc reproduces Python
// html.escape(s, quote=True): the apostrophe is emitted as &#x27; (Python form),
// not the &#39; that Go's html.EscapeString would produce, because the published
// pages carry &#x27; (verified against elixir/phoenix/blueprint.html, whose title
// is "What we&#x27;re building").
package tmpl

import "strings"

// DOCTYPE is the document preamble that opens every assembled page, copied
// verbatim from build_page.py's _assemble return value.
const DOCTYPE = "<!doctype html>\n<html lang=\"en\">\n"

// BodySep is the literal separator _assemble writes between the head and the
// body fragment.
const BodySep = "\n<body>\n"

// BOOTSTRAP is the progressive-enhancement script _assemble appends at the end
// of <body>. Copied byte-for-byte from build_page.py (the BOOTSTRAP constant).
const BOOTSTRAP = `<script>
/* progressive enhancement: mark JS on, then reveal-on-scroll */
document.documentElement.classList.add('js');
document.addEventListener('DOMContentLoaded', function () {
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var els = document.querySelectorAll('.reveal');
  if (reduce || !('IntersectionObserver' in window)) {
    els.forEach(function (e) { e.classList.add('in'); });
    return;
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); }
    });
  }, { threshold: 0.12 });
  els.forEach(function (e) { io.observe(e); });
});
</script>`

// Suffix is the exact tail _assemble writes after the body fragment: a newline,
// the bootstrap script, then the closing body and html tags.
const Suffix = "\n" + BOOTSTRAP + "\n</body>\n</html>\n"

// Placeholders the head and fragment templates carry.
const (
	PhTitle   = "{{TITLE}}"
	PhDesc    = "{{DESC}}"
	PhBuildID = "{{BUILD_ID}}"
	PhBuildTS = "{{BUILD_TS}}"
)

// escReplacer applies the five HTML-escape replacements of Python
// html.escape(s, quote=True), in the order & first then < > " ', emitting
// &#x27; for the apostrophe to match the published bytes. strings.NewReplacer
// scans the input once and never re-escapes its own output, so the leading &
// rule does not double-encode the & in the later entities.
var escReplacer = strings.NewReplacer(
	"&", "&amp;",
	"<", "&lt;",
	">", "&gt;",
	"\"", "&quot;",
	"'", "&#x27;",
)

// Esc HTML-escapes s the way Python html.escape(s, quote=True) does, including
// the &#x27; apostrophe form the published pages use.
func Esc(s string) string { return escReplacer.Replace(s) }
