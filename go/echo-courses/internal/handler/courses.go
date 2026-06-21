// The courses handlers serve the catalog as pages: the index (GET /courses and
// GET /, the same handler — ec.4 D-2), the five detail routes on their published
// paths plus /courses/:slug (the internal canonical, render-identical — D-3), and
// a 404 for an unknown slug. Every route derives from the loaded *catalog.Catalog
// (threaded in from newEcho), so the routes, the cards, and the filter chips have
// one source of truth — adding a course is adding one content file (ec.3 §1).
package handler

import (
	"html/template"
	"net/http"
	"strings"

	"github.com/fiberfx/echo-courses/internal/catalog"
	"github.com/fiberfx/echo-courses/internal/render"
	"github.com/labstack/echo/v5"
)

// englishSuffix is appended to the joined track list to form a card eyebrow
// (the golden master's "Elixir · BEAM · English" — English is not a track, so the
// catalog does not carry it; the index handler appends it).
const englishSuffix = " · English"

// Courses holds the loaded catalog and a path->course index, and serves the index
// and detail pages from them. Build it once at boot (NewCourses) and register its
// methods as handlers.
type Courses struct {
	cat    *catalog.Catalog
	byPath map[string]*catalog.Course // Course.Path -> course (the published routes)
	bySlug map[string]*catalog.Course // Course.Slug -> course (/courses/:slug)
}

// NewCourses indexes the catalog for routing: a path->course map (the published
// detail routes resolve through it) and a slug->course map (/courses/:slug). The
// maps point at the catalog's own course values, so they share the loaded data.
func NewCourses(cat *catalog.Catalog) *Courses {
	byPath := make(map[string]*catalog.Course, len(cat.Courses))
	bySlug := make(map[string]*catalog.Course, len(cat.Courses))
	for i := range cat.Courses {
		c := &cat.Courses[i]
		byPath[c.Path] = c
		bySlug[c.Slug] = c
	}
	return &Courses{cat: cat, byPath: byPath, bySlug: bySlug}
}

// facetView is one filter chip: the catalog facet plus the Active flag the server
// sets from ?track= (so a no-JS / direct-link request renders the right chip
// active, mirroring the client-side filter).
type facetView struct {
	Label  string
	Key    string
	Count  int
	Active bool
}

// indexData is what pages/index.html renders: the filter chips (with the active
// one resolved from ?track=) and the course cards (filtered to the track when one
// is given).
type indexData struct {
	Facets []facetView
	Cards  []render.Card
}

// detailData is what pages/course.html renders: the eyebrow/title header and the
// course body (the landing — D-3; not a re-host of the deep multi-page course).
// Body is template.HTML so the trusted, in-repo-authored course markup renders
// unescaped (matching catalog.Course.Body / render.Card.Icon).
type detailData struct {
	Eyebrow string
	Title   string
	Body    template.HTML
}

// Index serves GET /courses and GET / (D-2 — both first-class, no redirect). It
// renders the catalog through the layout: the filter chips from Catalog.Facets
// and a card per course. A ?track= query narrows the grid server-side
// (case-insensitive against Facet.Key) and marks the matching chip active; an
// absent / "all" / unknown track renders all five with the All chip active
// (criterion 5).
func (h *Courses) Index(c *echo.Context) error {
	track := strings.ToLower(strings.TrimSpace(c.QueryParam("track")))
	// active is the chip key to mark active and the membership filter. It defaults
	// to "all"; a track that matches a real facet key narrows to it. An unknown
	// (or "all", or absent) track stays "all" — all five cards, All chip active.
	active := "all"
	if track != "" && track != "all" && h.facetExists(track) {
		active = track
	}

	facets := make([]facetView, 0, len(h.cat.Facets))
	for _, f := range h.cat.Facets {
		facets = append(facets, facetView{
			Label:  f.Label,
			Key:    f.Key,
			Count:  f.Count,
			Active: f.Key == active,
		})
	}

	cards := make([]render.Card, 0, len(h.cat.Courses))
	for i := range h.cat.Courses {
		course := &h.cat.Courses[i]
		key := strings.ToLower(course.Facet)
		if active != "all" && key != active {
			continue
		}
		cards = append(cards, render.Card{
			Accent:  course.Accent,
			Tags:    key, // the single facet key, lower-cased (golden data-tags)
			Href:    course.Path,
			Icon:    course.Icon,
			Eyebrow: strings.Join(course.Tracks, " · ") + englishSuffix,
			Title:   course.Title,
			Summary: course.Summary,
		})
	}

	return c.Render(http.StatusOK, "index.html", indexData{Facets: facets, Cards: cards})
}

// Detail serves a single course's landing. The published detail routes
// (/elixir, …) and /courses/:slug both register Detail; the published routes
// resolve through the path->course map (keyed on the request path), and
// /courses/:slug resolves through the slug->course map. Both render identically
// (D-3, no redirect). An unrecognized course is a 404 via
// echo.NewHTTPError(http.StatusNotFound, …).
func (h *Courses) Detail(c *echo.Context) error {
	var course *catalog.Course
	if slug := c.Param("slug"); slug != "" {
		course = h.bySlug[slug]
	} else {
		course = h.byPath[c.Request().URL.Path]
	}
	if course == nil {
		return echo.NewHTTPError(http.StatusNotFound, "course not found")
	}
	return c.Render(http.StatusOK, "course.html", detailData{
		Eyebrow: strings.Join(course.Tracks, " · ") + englishSuffix,
		Title:   course.Title,
		Body:    course.Body,
	})
}

// facetExists reports whether key matches a real facet key (lower-cased) other
// than All — the set ?track= can narrow to.
func (h *Courses) facetExists(key string) bool {
	for _, f := range h.cat.Facets {
		if f.Key == key && f.Key != "all" {
			return true
		}
	}
	return false
}
