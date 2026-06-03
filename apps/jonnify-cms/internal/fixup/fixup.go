// Package fixup applies deterministic, do-no-harm repairs to a built HTML page —
// the two drifts that recur when a page is authored from an older template and
// that the Apollo gates cannot see (they strip <style> before checking, and they
// only flag a dead link, never the route it should have been):
//
//   - clamp/calc spacing. CSS requires whitespace on both sides of a binary +/-
//     inside a length expression. "1.9rem+4.2vw" is a parse error, so the whole
//     font-size declaration is dropped and the element falls back to the UA
//     default. Spaces are inserted to restore the intended value.
//   - relink. Links are normalized onto the section's canonical mount (a
//     shortened prefix is repointed to it) and an author chapter slug is swapped
//     for the page's real chapter dir. Every rewrite is verified against the
//     allowed route set (the section's filesystem routes derived at its mount)
//     and applied ONLY when it lands on a real route — a rewrite that would not
//     resolve is left untouched, so the links gate still flags it.
//
// Apply is idempotent: a repaired page passed back through Apply changes nothing.
package fixup

import (
	"path/filepath"
	"regexp"
	"strings"
)

// clampRE matches a length token immediately joined to a signed number by +/- —
// the spaceless-calc bug. The space-restored form ("rem + 4") no longer matches,
// which is what makes Apply idempotent.
var clampRE = regexp.MustCompile(`([0-9](?:rem|em|vw|vh|px|ch|%))([+\-])([0-9.])`)

var (
	hrefRE     = regexp.MustCompile(`href="([^"]+)"`)
	routeTagRE = regexp.MustCompile(`(route-tag">)([^<]*)`)
)

// Result reports what Apply changed.
type Result struct {
	Clamps   int      // count of spaceless calc operators repaired
	Relinks  int      // count of dead links rewritten to a real route
	RouteTag bool     // the visible route-tag was corrected to the canonical self-route
	Changes  []string // human-readable, e.g. "/course/x/a1 -> /course/x/why"
}

// Changed reports whether Apply altered the document.
func (r Result) Changed() bool { return r.Clamps > 0 || r.Relinks > 0 || r.RouteTag }

// Apply repairs doc. file is the page's path (used to derive its own chapter and
// canonical route); sectionRoot is the on-disk section dir and mount its URL
// prefix (for example "/course/agile-agent-workflow"); aliases maps a positional
// chapter slug to its semantic dir (for example "a0"->"intro", "a1"->"why"); and
// allowed is the resolvable-route set. When sectionRoot is empty only the clamp
// repair runs (relink needs the route set). It returns the repaired document and
// a record of the changes.
func Apply(doc, file, sectionRoot, mount string, aliases map[string]string, allowed map[string]bool) (string, Result) {
	var res Result

	// 1) clamp/calc spacing — always safe, no route context needed.
	doc = clampRE.ReplaceAllStringFunc(doc, func(m string) string {
		sub := clampRE.FindStringSubmatch(m)
		res.Clamps++
		return sub[1] + " " + sub[2] + " " + sub[3]
	})

	if sectionRoot == "" {
		return doc, res
	}
	mount = "/" + strings.Trim(mount, "/")
	chapter := pageChapter(sectionRoot, file)
	selfRoute := canonicalRoute(sectionRoot, file, mount)

	// 2) relink hrefs — only ever rewrite to a route that actually resolves.
	doc = hrefRE.ReplaceAllStringFunc(doc, func(m string) string {
		h := hrefRE.FindStringSubmatch(m)[1]
		if !strings.HasPrefix(h, "/") || allowed[h] {
			return m // external/anchor, or already valid
		}
		if fixed, ok := repairRoute(h, mount, chapter, aliases, allowed); ok {
			res.Relinks++
			res.Changes = append(res.Changes, h+" -> "+fixed)
			return `href="` + fixed + `"`
		}
		return m
	})

	// 3) route-tag — the visible breadcrumb chip; set it to the canonical self-route.
	if selfRoute != "" {
		doc = routeTagRE.ReplaceAllStringFunc(doc, func(m string) string {
			sub := routeTagRE.FindStringSubmatch(m)
			if sub[2] == selfRoute {
				return m
			}
			res.RouteTag = true
			res.Changes = append(res.Changes, "route-tag "+sub[2]+" -> "+selfRoute)
			return sub[1] + selfRoute
		})
	}
	return doc, res
}

// repairRoute tries the known transforms in order and returns the first result
// that lands in allowed: normalize a shortened section prefix onto the canonical
// mount, alias a positional chapter slug to its semantic dir (a0->intro),
// collapse a nested deep-dive reference to its flat hyphenated file, or swap in
// the page's own chapter dir. Every candidate is route-verified, so a link with
// no real target is left untouched.
func repairRoute(h, mount, chapter string, aliases map[string]string, allowed map[string]bool) (string, bool) {
	np := normalizePrefix(h, mount)
	na := aliasChapter(np, mount, aliases)
	for _, cand := range []string{
		np,
		na,
		aliasChapter(h, mount, aliases),
		flattenLeaf(na, mount),
		flattenLeaf(np, mount),
		swapChapter(np, mount, chapter),
	} {
		if cand != h && cand != "" && allowed[cand] {
			return cand, true
		}
	}
	return "", false
}

// aliasChapter replaces the first path segment under mount via the aliases map
// (a positional "a0" -> the semantic dir "intro"). An unmapped or non-section
// link is returned unchanged.
func aliasChapter(h, mount string, aliases map[string]string) string {
	if len(aliases) == 0 || !strings.HasPrefix(h, mount+"/") {
		return h
	}
	segs := strings.Split(strings.TrimPrefix(h, mount+"/"), "/")
	if alias, ok := aliases[segs[0]]; ok {
		segs[0] = alias
	}
	return mount + "/" + strings.Join(segs, "/")
}

// flattenLeaf collapses a nested deep-dive reference (chapter/leaf/sub…) to the
// flat hyphenated filename the section actually uses (chapter/leaf-sub). It only
// joins the components after the chapter; the caller route-verifies the result.
func flattenLeaf(h, mount string) string {
	if !strings.HasPrefix(h, mount+"/") {
		return h
	}
	segs := strings.Split(strings.TrimPrefix(h, mount+"/"), "/")
	if len(segs) < 3 {
		return h // nothing nested beyond chapter/leaf
	}
	return mount + "/" + segs[0] + "/" + strings.Join(segs[1:], "-")
}

// normalizePrefix repoints a link that targets the section under a shortened
// prefix to the canonical mount. For mount "/course/agile-agent-workflow" the
// shortened form is "/agile-agent-workflow"; a link to it (or anything below it)
// is rewritten onto the mount. A link already under mount is returned unchanged.
func normalizePrefix(h, mount string) string {
	short := shortPrefix(mount)
	if short == mount {
		return h
	}
	switch {
	case h == short:
		return mount
	case strings.HasPrefix(h, short+"/"):
		return mount + strings.TrimPrefix(h, short)
	}
	return h
}

// shortPrefix drops a leading "/course" segment from mount, yielding the
// section's bare prefix (the variant authors and earlier passes may have used).
func shortPrefix(mount string) string {
	if strings.HasPrefix(mount, "/course/") {
		return strings.TrimPrefix(mount, "/course")
	}
	return mount
}

// swapChapter replaces the first path segment under mount with chapter (the
// page's real on-disk chapter dir). The bare mount and non-mount links are
// returned unchanged.
func swapChapter(h, mount, chapter string) string {
	if chapter == "" || !strings.HasPrefix(h, mount+"/") {
		return h
	}
	rest := strings.TrimPrefix(h, mount+"/")
	segs := strings.Split(rest, "/")
	segs[0] = chapter
	return mount + "/" + strings.Join(segs, "/")
}

// pageChapter is the first path component of file relative to sectionRoot — the
// chapter directory the page lives in ("" for a page at the section root).
func pageChapter(sectionRoot, file string) string {
	rel, err := filepath.Rel(sectionRoot, file)
	if err != nil {
		return ""
	}
	rel = filepath.ToSlash(rel)
	if i := strings.IndexByte(rel, '/'); i >= 0 {
		return rel[:i]
	}
	return "" // file sits directly in the section root (e.g. the section hub)
}

// canonicalRoute is the clean URL the server serves this file at, mirroring
// serveDirTree: index.html -> its directory URL; <name>.html -> the leaf URL.
func canonicalRoute(sectionRoot, file, mount string) string {
	rel, err := filepath.Rel(sectionRoot, file)
	if err != nil {
		return ""
	}
	rel = filepath.ToSlash(rel)
	if filepath.Base(file) == "index.html" {
		sub := strings.Trim(strings.TrimSuffix(rel, "index.html"), "/")
		if sub == "" {
			return mount
		}
		return mount + "/" + sub
	}
	return mount + "/" + strings.TrimSuffix(rel, ".html")
}
