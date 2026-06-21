// Package web carries the echo-courses presentation assets. ec.2 embeds the
// template tree (layout + partials + pages) into the binary via go:embed so the
// ec.6 single-binary deploy needs no template files on disk. The render layer
// (internal/render) parses FS once at boot.
//
// Static assets (web/static) are NOT embedded yet — they stay filesystem-served
// from ec.1; ec.5 moves the design-system asset files under web/static.
package web

import "embed"

// FS holds the embedded template tree rooted at web/. The render layer parses
// "templates/layout.html", "templates/partials/*.html", and each
// "templates/pages/*.html" out of it.
//
//go:embed templates
var FS embed.FS
