// SEO surface for the courses site (ec.5 AC4): GET /sitemap.xml and
// GET /robots.txt. Both derive from the loaded *catalog.Catalog and the
// canonical base (env CANONICAL_BASE, ec.5 D-2), so the sitemap stays in lockstep
// with the catalog — adding a course adds its URL to the sitemap with no extra
// edit (the same single-source-of-truth the index/detail routes have, ec.3 §1).
package handler

import (
	"encoding/xml"
	"net/http"
	"strings"

	"github.com/fiberfx/echo-courses/internal/catalog"
	"github.com/labstack/echo/v5"
)

// SEO serves the sitemap + robots from the catalog and the canonical base. Build
// it once at boot (NewSEO) and register its methods.
type SEO struct {
	cat  *catalog.Catalog
	base string // CANONICAL_BASE, trailing slash trimmed (ec.5 D-2)
}

// NewSEO captures the catalog and the canonical base. The base's trailing slash
// is trimmed once so joining a path (which begins with "/") never doubles it.
func NewSEO(cat *catalog.Catalog, base string) *SEO {
	return &SEO{cat: cat, base: strings.TrimRight(base, "/")}
}

// urlEntry is one <url> in the sitemap. Only <loc> is emitted — a minimal, valid
// urlset (lastmod/changefreq/priority are optional and omitted, matching the
// additive-polish posture of ec.5: no invented freshness data).
type urlEntry struct {
	Loc string `xml:"loc"`
}

// urlSet is the sitemap document: the sitemaps.org urlset namespace + the entries.
type urlSet struct {
	XMLName xml.Name   `xml:"urlset"`
	XMLNS   string     `xml:"xmlns,attr"`
	URLs    []urlEntry `xml:"url"`
}

// sitemapNS is the required sitemaps.org 0.9 namespace.
const sitemapNS = "http://www.sitemaps.org/schemas/sitemap/0.9"

// Sitemap serves GET /sitemap.xml: a well-formed urlset listing /courses plus
// every published course Path, each absolute under CANONICAL_BASE (ec.5 AC4).
// The order is the catalog's published order (Courses is sorted by Order).
func (s *SEO) Sitemap(c *echo.Context) error {
	set := urlSet{XMLNS: sitemapNS}
	set.URLs = append(set.URLs, urlEntry{Loc: s.base + "/courses"})
	for i := range s.cat.Courses {
		set.URLs = append(set.URLs, urlEntry{Loc: s.base + s.cat.Courses[i].Path})
	}

	body, err := xml.MarshalIndent(set, "", "  ")
	if err != nil {
		// MarshalIndent over this fixed shape cannot fail in practice; surface it
		// as a 500 rather than a partial body if it ever does.
		return echo.NewHTTPError(http.StatusInternalServerError, "sitemap marshal failed")
	}
	out := append([]byte(xml.Header), body...)
	return c.Blob(http.StatusOK, "application/xml; charset=utf-8", out)
}

// Robots serves GET /robots.txt: an allow-all policy with a Sitemap: line
// pointing at the canonical sitemap URL (ec.5 AC4). Crawlers may fetch every
// path; the sitemap line advertises the catalog.
func (s *SEO) Robots(c *echo.Context) error {
	body := "User-agent: *\nAllow: /\nSitemap: " + s.base + "/sitemap.xml\n"
	return c.String(http.StatusOK, body)
}
