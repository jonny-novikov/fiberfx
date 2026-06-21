// Command server runs the echo-courses HTTP server — the Echo v5 scaffold that
// the echo-courses rungs build on (docs/echo_courses, ec.1 → ec.6).
//
// ec.1 shipped the boot, a /healthz probe, static serving, graceful shutdown, and
// the project layout; ec.2 the Renderer; ec.3 the catalog. ec.4 (this rung) wires
// the catalog-driven routes into newEcho: the /courses + / index, the five
// published detail paths, and /courses/:slug — the live site.
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

	// gracefulTimeout bounds how long in-flight requests may drain after a
	// shutdown signal before the server is forced down. ec.6's fly.toml
	// kill_timeout must exceed this so Fly does not cut a draining machine.
	gracefulTimeout = 10 * time.Second
)

func main() {
	addr := envOr("ADDR", defaultAddr)
	staticDir := envOr("STATIC_DIR", defaultStaticDir)

	// signal.NotifyContext is the v5 graceful-shutdown trigger: when SIGINT or
	// SIGTERM cancels this context, echo.StartConfig runs server.Shutdown with
	// gracefulTimeout (Echo v5 has no e.Shutdown method).
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, addr, staticDir, gracefulTimeout); err != nil {
		_, _ = os.Stderr.WriteString("echo-courses: " + err.Error() + "\n")
		os.Exit(1)
	}
}

// run builds the Echo instance and serves it until ctx is cancelled, then drains
// in-flight requests within graceful. It returns nil on a clean shutdown
// (echo.StartConfig.Start already swallows http.ErrServerClosed). A template
// parse failure from newEcho — or a malformed course catalog — aborts the boot
// before the server ever binds (ec.2 acceptance 1 / ec.3 acceptances 2-3,
// fail-fast).
func run(ctx context.Context, addr, staticDir string, graceful time.Duration) error {
	// Load the course catalog from the embedded content/ tree and thread it into
	// newEcho — ec.4 routes the index off Catalog.Courses / .Facets and the detail
	// pages off Course.Path. Load fails the boot fast on a missing field, a
	// duplicate slug, or an unreadable file.
	cat, err := catalog.Load(content.FS)
	if err != nil {
		return err
	}

	e, err := newEcho(staticDir, cat)
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
// serving of staticDir under /static, and — ec.4 — the catalog-driven routes:
// GET /courses and GET / (the same index handler, D-2), the five published detail
// paths plus /courses/:slug (render-identical, D-3), all from the threaded
// *catalog.Catalog. A parse error returns a named error so the boot aborts.
// Handlers take *echo.Context per Echo v5.
func newEcho(staticDir string, cat *catalog.Catalog) (*echo.Echo, error) {
	r, err := render.New(web.FS)
	if err != nil {
		return nil, err
	}

	e := echo.New()
	e.Renderer = r
	e.Use(middleware.Recover())
	e.Use(middleware.RequestLogger())

	e.GET("/healthz", handler.Health)
	e.Static("/static", staticDir)

	courses := handler.NewCourses(cat)
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

	return e, nil
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
