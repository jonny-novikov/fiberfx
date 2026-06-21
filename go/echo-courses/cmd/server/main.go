// Command server runs the echo-courses HTTP server — the Echo v5 scaffold that
// the echo-courses rungs build on (docs/echo_courses, ec.1 → ec.6).
//
// ec.1 shipped the boot, a /healthz probe, static serving, graceful shutdown, and
// the project layout; ec.2 the Renderer; ec.3 the catalog; ec.4 the catalog-driven
// routes (the live site). ec.5 (this rung) adds the polish over that live site:
// the externalized design-system app.css + interactive app.js served from
// boot-fingerprinted content-hash routes (D-1), per-page SEO meta + Open Graph +
// canonical from CANONICAL_BASE (D-2/D-3), and /sitemap.xml + /robots.txt.
package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/fiberfx/echo-courses/content"
	"github.com/fiberfx/echo-courses/internal/asset"
	"github.com/fiberfx/echo-courses/internal/catalog"
	"github.com/fiberfx/echo-courses/internal/handler"
	"github.com/fiberfx/echo-courses/internal/render"
	"github.com/fiberfx/echo-courses/web"
	"github.com/labstack/echo/v5"
	"github.com/labstack/echo/v5/middleware"
)

const (
	defaultAddr      = ":1323"
	defaultStaticDir = "web/static"

	// defaultCanonicalBase is the canonical/og:url base when CANONICAL_BASE is
	// unset (ec.5 D-2 — the current Fly host). A page's canonical = this + path.
	defaultCanonicalBase = "https://jonnify.fly.dev"

	// gracefulTimeout bounds how long in-flight requests may drain after a
	// shutdown signal before the server is forced down. ec.6's fly.toml
	// kill_timeout must exceed this so Fly does not cut a draining machine.
	gracefulTimeout = 10 * time.Second
)

func main() {
	addr := envOr("ADDR", defaultAddr)
	staticDir := envOr("STATIC_DIR", defaultStaticDir)
	canonicalBase := envOr("CANONICAL_BASE", defaultCanonicalBase)

	// signal.NotifyContext is the v5 graceful-shutdown trigger: when SIGINT or
	// SIGTERM cancels this context, echo.StartConfig runs server.Shutdown with
	// gracefulTimeout (Echo v5 has no e.Shutdown method).
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, addr, staticDir, canonicalBase, gracefulTimeout); err != nil {
		_, _ = os.Stderr.WriteString("echo-courses: " + err.Error() + "\n")
		os.Exit(1)
	}
}

// run builds the Echo instance and serves it until ctx is cancelled, then drains
// in-flight requests within graceful. It returns nil on a clean shutdown
// (echo.StartConfig.Start already swallows http.ErrServerClosed). A template
// parse failure from newEcho — or a malformed course catalog, or a missing
// embedded asset — aborts the boot before the server ever binds (ec.2 acceptance
// 1 / ec.3 acceptances 2-3 / ec.5 D-1, fail-fast).
func run(ctx context.Context, addr, staticDir, canonicalBase string, graceful time.Duration) error {
	// Load the course catalog from the embedded content/ tree and thread it into
	// newEcho — ec.4 routes the index off Catalog.Courses / .Facets and the detail
	// pages off Course.Path. Load fails the boot fast on a missing field, a
	// duplicate slug, or an unreadable file.
	cat, err := catalog.Load(content.FS)
	if err != nil {
		return err
	}

	e, err := newEcho(staticDir, canonicalBase, cat)
	if err != nil {
		return err
	}
	cfg := echo.StartConfig{Address: addr, GracefulTimeout: graceful}
	if err := cfg.Start(ctx, e); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}

// newEcho wires the server: recover + request-logger middleware, the render layer
// (the embedded template tree, parsed fail-fast at boot), GET /healthz, static
// serving of staticDir under /static, the catalog-driven routes (ec.4), and the
// ec.5 polish: the content-hash asset routes (D-1, from the embedded bytes), the
// per-page head injected via NewCourses' asset URLs + CANONICAL_BASE (D-2/D-3),
// and /sitemap.xml + /robots.txt. A parse error — or a missing embedded asset —
// returns a named error so the boot aborts. Handlers take *echo.Context (Echo v5).
func newEcho(staticDir, canonicalBase string, cat *catalog.Catalog) (*echo.Echo, error) {
	r, err := render.New(web.FS)
	if err != nil {
		return nil, err
	}

	// Fingerprint the embedded design-system + interactive assets at boot (ec.5
	// D-1). A missing embedded file fails the boot fast rather than serving a dead
	// asset link.
	assets, err := asset.Load(web.FS)
	if err != nil {
		return nil, err
	}

	e := echo.New()
	e.Renderer = r
	e.Use(middleware.Recover())
	e.Use(middleware.RequestLogger())

	e.GET("/healthz", handler.Health)
	// Disk static (ec.1) stays for anything still file-served (web/static/version.txt).
	// The fingerprinted app.css/app.js are served from the embedded bytes by the
	// content-hash routes below; their concrete static paths take router priority
	// over this "/static/*" wildcard, so a wrong hash falls through here and 404s.
	e.Static("/static", staticDir)
	// The content-hash asset routes (ec.5 D-1): GET /static/app.<hash>.{css,js},
	// the embedded bytes with an immutable Cache-Control + the exact Content-Type.
	assets.Register(e)

	courses := handler.NewCourses(cat, assets.CSSURL(), assets.JSURL(), canonicalBase)
	// The index at both /courses and / (D-2 — both first-class, no redirect; the
	// topbar brand href="/" resolves).
	e.GET("/courses", courses.Index)
	e.GET("/", courses.Index)
	// /courses/:slug is the internal canonical; each published path is registered
	// explicitly from Course.Path (not a /:slug catch-all — /course/agile-agent-workflow
	// is multi-segment and would collide). Both render identically (D-3).
	e.GET("/courses/:slug", courses.Detail)
	for i := range cat.Courses {
		e.GET(cat.Courses[i].Path, courses.Detail)
	}

	// The SEO surface (ec.5 AC4): the sitemap + robots, both derived from the
	// catalog and CANONICAL_BASE (D-2).
	seo := handler.NewSEO(cat, canonicalBase)
	e.GET("/sitemap.xml", seo.Sitemap)
	e.GET("/robots.txt", seo.Robots)

	return e, nil
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
