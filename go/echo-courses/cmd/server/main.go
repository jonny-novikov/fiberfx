// Command server runs the echo-courses HTTP server — the Echo v5 scaffold that
// the echo-courses rungs build on (docs/echo_courses, ec.1 → ec.6).
//
// ec.1 (this rung) ships the boot, a /healthz probe, static serving, graceful
// shutdown, and the project layout. The Renderer (ec.2), the catalog (ec.3),
// and the course routes (ec.4) land on top of newEcho without reshaping it.
package main

import (
	"context"
	"errors"
	"html/template"
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
	// Load the course catalog from the embedded content/ tree. ec.3 does not
	// route or render it (ec.4 wires the index off Catalog.Courses / .Facets);
	// loading here proves the seed parses and fails the boot fast on a missing
	// field, a duplicate slug, or an unreadable file.
	if _, err := catalog.Load(content.FS); err != nil {
		return err
	}

	e, err := newEcho(staticDir)
	if err != nil {
		return err
	}
	cfg := echo.StartConfig{Address: addr, GracefulTimeout: graceful}
	if err := cfg.Start(ctx, e); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}

// newEcho wires the scaffold: recover + request-logger middleware, the render
// layer (the embedded template tree, parsed fail-fast at boot), GET /healthz,
// static serving of staticDir under /static, and the ec.2 placeholder route
// GET / proving the render path. A parse error returns a named error so the boot
// aborts. Handlers take *echo.Context per Echo v5. ec.4 replaces GET / with the
// real catalog index.
func newEcho(staticDir string) (*echo.Echo, error) {
	r, err := render.New(web.FS)
	if err != nil {
		return nil, err
	}

	e := echo.New()
	e.Renderer = r
	e.Use(middleware.Recover())
	e.Use(middleware.RequestLogger())

	e.GET("/", placeholder)
	e.GET("/healthz", handler.Health)
	e.Static("/static", staticDir)

	return e, nil
}

// placeholder renders the ec.2 placeholder page — the base layout composed with
// the card and filter partials over one sample card. ec.4 supersedes it with the
// catalog-driven index handler.
func placeholder(c *echo.Context) error {
	data := map[string]any{
		"Card": render.Card{
			Accent:  template.CSS("var(--gold-bright)"),
			Tags:    "elixir",
			Href:    "/elixir",
			Icon:    template.HTML(`<svg viewBox="0 0 44 44" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M13 35 L24 9 M21 22 L31 35"/><circle cx="22" cy="22" r="18" stroke-width="1.2" stroke-opacity="0.5"/></svg>`),
			Eyebrow: "Elixir · BEAM · English",
			Title:   "Functional Programming",
			Summary: "A deep dive into functional programming with Elixir on the BEAM — from foundational to advanced computer-science problems, with interactive elements.",
		},
	}
	return c.Render(http.StatusOK, "placeholder.html", data)
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
