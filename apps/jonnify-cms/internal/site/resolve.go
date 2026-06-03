// Package site resolves clean /elixir routes to on-disk files exactly the way
// the jonnify server's serveDirTree cascade does: a directory resolves to its
// index.html; a missing path falls back to <path>.html; an exact file serves
// itself. Mirroring the server means audit and readiness report what the running
// site would actually return — including the case where a directory without an
// index.html shadows a sibling <name>.html and yields a 404.
package site

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

// RelOf strips the /elixir prefix from a clean route, returning the path
// relative to the section root ("" for the bare /elixir route).
func RelOf(route string) string {
	return strings.Trim(strings.TrimPrefix(route, "/elixir"), "/")
}

// Resolve returns the backing file for a route under root and whether the route
// resolves. note carries a diagnostic when it does not (for example a directory
// with no index.html that shadows a sibling .html file).
func Resolve(root, route string) (file string, ok bool, note string) {
	rel := RelOf(route)
	base := filepath.Join(root, filepath.FromSlash(rel))
	info, err := os.Stat(base)
	switch {
	case err == nil && info.IsDir():
		idx := filepath.Join(base, "index.html")
		if st, e := os.Stat(idx); e == nil && !st.IsDir() {
			return idx, true, ""
		}
		if st, e := os.Stat(base + ".html"); e == nil && !st.IsDir() {
			return "", false, "directory has no index.html; sibling " + rel + ".html is shadowed (would 404)"
		}
		return "", false, "directory has no index.html"
	case err != nil:
		htmlPath := base + ".html"
		if st, e := os.Stat(htmlPath); e == nil && !st.IsDir() {
			return htmlPath, true, ""
		}
		return "", false, "no file backs this route"
	default:
		return base, true, ""
	}
}

// SectionRoutes walks a folder-routed section on disk and returns the set of
// clean URLs the server would actually serve for it — mirroring serveDirTree
// (and cmd/sitemap): a directory holding index.html maps to the directory URL
// (the bare mount for the root, mount/<sub> below it); any other <name>.html
// maps to its clean leaf URL. mount is the section's URL prefix (for example
// "/agile-agent-workflow"); a leading slash is added if absent. This is what
// makes the link/pager gates aware of a section the elixir manifest never
// declares: routes are derived from the filesystem, exactly as the server does.
func SectionRoutes(root, mount string) (map[string]bool, error) {
	mount = "/" + strings.Trim(mount, "/")
	out := map[string]bool{}
	err := filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(d.Name(), ".html") {
			return nil
		}
		rel, relErr := filepath.Rel(root, p)
		if relErr != nil {
			return nil
		}
		rel = filepath.ToSlash(rel)
		if d.Name() == "index.html" {
			sub := strings.Trim(strings.TrimSuffix(rel, "index.html"), "/")
			if sub == "" {
				out[mount] = true
			} else {
				out[mount+"/"+sub] = true
			}
		} else {
			out[mount+"/"+strings.TrimSuffix(rel, ".html")] = true
		}
		return nil
	})
	return out, err
}

// CanonicalFile is the filename a route SHOULD resolve to: a directory of that
// name implies a hub (its index.html); otherwise a leaf <name>.html.
func CanonicalFile(root, route string) string {
	rel := RelOf(route)
	dir := filepath.Join(root, filepath.FromSlash(rel))
	if st, err := os.Stat(dir); err == nil && st.IsDir() {
		return filepath.Join(dir, "index.html")
	}
	return dir + ".html"
}
