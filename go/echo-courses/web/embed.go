// Package web carries the echo-courses presentation assets. ec.2 embeds the
// template tree (layout + partials + pages) into the binary via go:embed so the
// ec.6 single-binary deploy needs no template files on disk. The render layer
// (internal/render) parses FS once at boot.
//
// ec.5 also embeds web/static (the externalized design-system app.css + the
// interactive app.js): the binary now carries the assets, so internal/asset can
// read them at boot, fingerprint them by content hash, and serve them from the
// embedded bytes on an immutable-cached content-hash route (ec.5 D-1). The old
// disk path (cmd/server's e.Static) stays for anything still disk-served
// (web/static/version.txt).
package web

import "embed"

// FS holds the embedded template tree and the static assets, rooted at web/. The
// render layer parses "templates/layout.html", "templates/partials/*.html", and
// each "templates/pages/*.html" out of it; internal/asset reads "static/app.css"
// and "static/app.js" out of it (ec.5 D-1).
//
//go:embed templates static
var FS embed.FS
