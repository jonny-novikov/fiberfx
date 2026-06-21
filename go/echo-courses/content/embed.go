// Package content carries the echo-courses course corpus: one content/<slug>.html
// per course (a YAML front-matter block + an HTML body), embedded into the binary
// via go:embed so the ec.6 single-binary deploy needs no content files on disk —
// mirroring the web package's template embed. The catalog layer
// (internal/catalog) reads this FS once at boot into the ordered catalog and the
// filter index (ec.3 — course catalog & content model).
//
// FS is exported (not unmarshalled here) so internal/catalog.Load takes a plain
// fs.FS — the loader is decoupled from the embed and unit-tested against an
// in-memory fstest.MapFS.
package content

import "embed"

// FS holds the embedded course corpus rooted at content/. The catalog loader
// globs "*.html" out of it and splits each file's front-matter from its body.
//
// The :embed pattern is relative to this file's directory; the .html sources sit
// beside it, so the pattern is the bare glob (no content/ prefix), giving an FS
// already rooted at the course files.
//
//go:embed *.html
var FS embed.FS
