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
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/fiberfx/echo-courses/internal/handler"
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
// (echo.StartConfig.Start already swallows http.ErrServerClosed).
func run(ctx context.Context, addr, staticDir string, graceful time.Duration) error {
	e := newEcho(staticDir)
	cfg := echo.StartConfig{Address: addr, GracefulTimeout: graceful}
	if err := cfg.Start(ctx, e); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}

// newEcho wires the ec.1 scaffold: recover + request-logger middleware,
// GET /healthz, and static serving of staticDir under /static. Handlers take
// *echo.Context per Echo v5.
func newEcho(staticDir string) *echo.Echo {
	e := echo.New()
	e.Use(middleware.Recover())
	e.Use(middleware.RequestLogger())

	e.GET("/healthz", handler.Health)
	e.Static("/static", staticDir)

	return e
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
