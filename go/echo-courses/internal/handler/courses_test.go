package handler_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/fiberfx/echo-courses/content"
	"github.com/fiberfx/echo-courses/internal/catalog"
	"github.com/fiberfx/echo-courses/internal/handler"
	"github.com/fiberfx/echo-courses/internal/render"
	"github.com/fiberfx/echo-courses/web"
	"github.com/labstack/echo/v5"
)

// newServer wires a real Echo over the embedded catalog + templates and the ec.4
// routes — the same wiring as cmd/server but local to the handler tests, so each
// case exercises the handler through c.Render and the actual template tree.
func newServer(t *testing.T) *echo.Echo {
	t.Helper()
	cat, err := catalog.Load(content.FS)
	if err != nil {
		t.Fatalf("catalog.Load: %v", err)
	}
	r, err := render.New(web.FS)
	if err != nil {
		t.Fatalf("render.New: %v", err)
	}
	e := echo.New()
	e.Renderer = r
	h := handler.NewCourses(cat)
	e.GET("/courses", h.Index)
	e.GET("/", h.Index)
	e.GET("/courses/:slug", h.Detail)
	for i := range cat.Courses {
		e.GET(cat.Courses[i].Path, h.Detail)
	}
	return e
}

func get(t *testing.T, e *echo.Echo, path string) (int, string) {
	t.Helper()
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, path, nil)
	e.ServeHTTP(rec, req)
	return rec.Code, rec.Body.String()
}

// AC4: the index renders the six filter chips in the PUBLISHED order
// (All · Elixir · Agents · Redis · EchoMQ · BCS — D-1), each with its count, and
// the five cards each carry data-tags = the lower-cased facet key (the chip→card
// filter hook).
func TestIndex_ChipsAndCards(t *testing.T) {
	e := newServer(t)
	code, body := get(t, e, "/courses")
	if code != http.StatusOK {
		t.Fatalf("GET /courses = %d, want 200", code)
	}

	// Published chip order: the data-tag attributes must appear in this sequence.
	wantOrder := []string{
		`data-tag="all"`, `data-tag="elixir"`, `data-tag="agents"`,
		`data-tag="redis"`, `data-tag="echomq"`, `data-tag="bcs"`,
	}
	last := -1
	for _, chip := range wantOrder {
		at := strings.Index(body, chip)
		if at < 0 {
			t.Fatalf("index missing chip %q", chip)
		}
		if at < last {
			t.Errorf("chip %q out of published order (at %d, previous at %d)", chip, at, last)
		}
		last = at
	}
	if got := strings.Count(body, `class="filter-btn`); got != 6 {
		t.Errorf("chip count = %d, want 6", got)
	}

	// The All chip is active by default; counts are present.
	if !strings.Contains(body, `class="filter-btn active" data-tag="all" aria-pressed="true"`) {
		t.Error("All chip not rendered active by default")
	}
	if !strings.Contains(body, `All<span class="cnt">5</span>`) {
		t.Error("All chip count != 5")
	}

	// Each card carries the single lower-cased facet key as data-tags.
	for _, tag := range []string{
		`data-tags="elixir"`, `data-tags="redis"`, `data-tags="echomq"`,
		`data-tags="agents"`, `data-tags="bcs"`,
	} {
		if !strings.Contains(body, tag) {
			t.Errorf("index missing card %q", tag)
		}
	}
	if got := strings.Count(body, `class="series-card"`); got != 5 {
		t.Errorf("card count = %d, want 5", got)
	}

	// The eyebrow is tracks · English (golden format).
	if !strings.Contains(body, `Elixir · BEAM · English`) {
		t.Error("elixir card eyebrow != 'Elixir · BEAM · English'")
	}
	// The verbatim filter script rides inline. html/template strips JS comments in
	// a <script> context, so assert the load-bearing logic (byte-verbatim from the
	// golden master) rather than the dropped leading comment.
	for _, frag := range []string{
		`const fbar=document.querySelector('.filter-bar');`,
		`const cards=[...document.querySelectorAll('.series-card')];`,
		`cards.forEach(c=>{const show=tag==='all'||(c.dataset.tags||'').split(' ').includes(tag);c.classList.toggle('filter-hidden',!show)});`,
	} {
		if !strings.Contains(body, frag) {
			t.Errorf("the verbatim filter <script> is missing the fragment %q", frag)
		}
	}
}

// AC5: ?track= narrows the grid server-side, case-insensitively against the facet
// key, and marks the matching chip active; all/absent/unknown render all five.
func TestIndex_TrackFilter(t *testing.T) {
	e := newServer(t)

	// A real facet, three casings — each renders only that course's card.
	for _, q := range []string{"Redis", "redis", "REDIS"} {
		code, body := get(t, e, "/courses?track="+q)
		if code != http.StatusOK {
			t.Fatalf("GET /courses?track=%s = %d, want 200", q, code)
		}
		if got := strings.Count(body, `class="series-card"`); got != 1 {
			t.Errorf("track=%s rendered %d cards, want 1", q, got)
		}
		if !strings.Contains(body, `data-tags="redis"`) {
			t.Errorf("track=%s did not render the Redis card", q)
		}
		if strings.Contains(body, `data-tags="elixir"`) {
			t.Errorf("track=%s leaked a non-Redis card", q)
		}
		if !strings.Contains(body, `class="filter-btn active" data-tag="redis" aria-pressed="true"`) {
			t.Errorf("track=%s did not mark the Redis chip active", q)
		}
	}

	// all / absent / unknown → all five, All chip active.
	for _, path := range []string{"/courses?track=all", "/courses", "/courses?track=nope"} {
		code, body := get(t, e, path)
		if code != http.StatusOK {
			t.Fatalf("GET %s = %d, want 200", path, code)
		}
		if got := strings.Count(body, `class="series-card"`); got != 5 {
			t.Errorf("%s rendered %d cards, want 5", path, got)
		}
		if !strings.Contains(body, `class="filter-btn active" data-tag="all" aria-pressed="true"`) {
			t.Errorf("%s did not mark the All chip active", path)
		}
	}
}

// AC2/AC3: each published path and its /courses/:slug counterpart return 200 and
// render the same course (no redirect — both first-class).
func TestDetail_PathAndSlugParity(t *testing.T) {
	cat, err := catalog.Load(content.FS)
	if err != nil {
		t.Fatalf("catalog.Load: %v", err)
	}
	e := newServer(t)

	for i := range cat.Courses {
		c := &cat.Courses[i]

		pCode, pBody := get(t, e, c.Path)
		if pCode != http.StatusOK {
			t.Errorf("GET %s = %d, want 200", c.Path, pCode)
		}
		if !strings.Contains(pBody, c.Title) {
			t.Errorf("GET %s did not render its title %q", c.Path, c.Title)
		}

		sCode, sBody := get(t, e, "/courses/"+c.Slug)
		if sCode != http.StatusOK {
			t.Errorf("GET /courses/%s = %d, want 200", c.Slug, sCode)
		}
		// Render-identical (both resolve the same course → byte-identical body).
		if sBody != pBody {
			t.Errorf("course %q: /courses/%s render differs from %s", c.Slug, c.Slug, c.Path)
		}
	}
}

// AC6: an unknown slug (and an unregistered single-segment path) returns 404.
func TestDetail_UnknownSlug404(t *testing.T) {
	e := newServer(t)

	if code, _ := get(t, e, "/courses/nope"); code != http.StatusNotFound {
		t.Errorf("GET /courses/nope = %d, want 404", code)
	}
	// An unregistered single-segment path is not in the route table at all →
	// Echo's own 404 (also status 404, satisfying criterion 6).
	if code, _ := get(t, e, "/not-a-course"); code != http.StatusNotFound {
		t.Errorf("GET /not-a-course = %d, want 404", code)
	}
}
