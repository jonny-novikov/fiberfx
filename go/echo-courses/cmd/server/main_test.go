package main

import (
	"context"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/fiberfx/echo-courses/content"
	"github.com/fiberfx/echo-courses/internal/catalog"
	"github.com/labstack/echo/v5"
)

// testCanonicalBase is the CANONICAL_BASE the newEcho fixtures inject (ec.5 D-2)
// — a stable non-default value so a head/og:url assertion proves the base is
// consumed, not the production default.
const testCanonicalBase = "https://example.test"

// loadCatalog loads the embedded course corpus for the newEcho fixtures (ec.4
// threads the catalog into newEcho). A load failure is a fatal test setup error.
func loadCatalog(t *testing.T) *catalog.Catalog {
	t.Helper()
	cat, err := catalog.Load(content.FS)
	if err != nil {
		t.Fatalf("catalog.Load(content.FS): %v", err)
	}
	return cat
}

// AC2 (wired): newEcho serves GET /healthz with 200 through the middleware chain.
func TestNewEcho_Healthz(t *testing.T) {
	e, err := newEcho(t.TempDir(), testCanonicalBase, loadCatalog(t))
	if err != nil {
		t.Fatalf("newEcho: %v", err)
	}

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
}

// AC3: a file under the static root is served under /static with its content.
func TestNewEcho_StaticServing(t *testing.T) {
	dir := t.TempDir()
	want := "echo-courses static ok\n"
	if err := os.WriteFile(filepath.Join(dir, "probe.txt"), []byte(want), 0o644); err != nil {
		t.Fatal(err)
	}
	e, err := newEcho(dir, testCanonicalBase, loadCatalog(t))
	if err != nil {
		t.Fatalf("newEcho: %v", err)
	}

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/static/probe.txt", nil)
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	if got := rec.Body.String(); got != want {
		t.Fatalf("body = %q, want %q", got, want)
	}
}

// AC4: on shutdown (ctx cancel) an in-flight request drains to completion rather
// than being reset — the echo.StartConfig{GracefulTimeout} contract run() relies
// on. Mirrors echo's own TestStartConfig_GracefulShutdown idiom.
func TestRun_GracefulDrain(t *testing.T) {
	// A handler slower than the cancel, far faster than the graceful budget.
	e := echo.New()
	e.GET("/slow", func(c *echo.Context) error {
		time.Sleep(150 * time.Millisecond)
		return c.String(http.StatusOK, "drained")
	})

	addrCh := make(chan string, 1)
	errCh := make(chan error, 1)
	ctx, cancel := context.WithCancel(context.Background())

	go func() {
		errCh <- echo.StartConfig{
			Address:          "127.0.0.1:0",
			GracefulTimeout:  gracefulTimeout,
			ListenerAddrFunc: func(a net.Addr) { addrCh <- a.String() },
		}.Start(ctx, e)
	}()

	var addr string
	select {
	case addr = <-addrCh:
	case err := <-errCh:
		t.Fatalf("server failed to start: %v", err)
	case <-time.After(2 * time.Second):
		t.Fatal("server did not report a listen address in time")
	}

	type result struct {
		status int
		body   string
		err    error
	}
	resCh := make(chan result, 1)
	go func() {
		resp, err := http.Get("http://" + addr + "/slow")
		if err != nil {
			resCh <- result{err: err}
			return
		}
		defer func() { _ = resp.Body.Close() }()
		body, _ := io.ReadAll(resp.Body)
		resCh <- result{status: resp.StatusCode, body: string(body)}
	}()

	time.Sleep(30 * time.Millisecond) // let the request reach the handler
	cancel()                          // trigger graceful shutdown mid-request

	select {
	case res := <-resCh:
		if res.err != nil {
			t.Fatalf("in-flight request was dropped during shutdown: %v", res.err)
		}
		if res.status != http.StatusOK || res.body != "drained" {
			t.Fatalf("got %d %q, want 200 %q", res.status, res.body, "drained")
		}
	case <-time.After(2 * time.Second):
		t.Fatal("in-flight request never completed")
	}

	if err := <-errCh; err != nil && err != http.ErrServerClosed {
		t.Fatalf("Start returned error: %v", err)
	}
}

// ec.4 D-2 (HTTP boundary): GET / and GET /courses both serve the catalog index
// through the real route wiring (e.Renderer + the threaded catalog set in
// newEcho), rendering the base-layout chrome, the golden hero/section copy, the
// five cards, and the six filter chips. The handler-level filter/404 cases live
// in internal/handler; this proves the wiring composes end to end at both paths.
func TestNewEcho_IndexRoute(t *testing.T) {
	e, err := newEcho(t.TempDir(), testCanonicalBase, loadCatalog(t))
	if err != nil {
		t.Fatalf("newEcho (template parse + catalog are fail-fast at boot): %v", err)
	}

	for _, path := range []string{"/", "/courses"} {
		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, path, nil)
		e.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("GET %s status = %d, want %d", path, rec.Code, http.StatusOK)
		}
		body := rec.Body.String()
		for _, want := range []string{
			"jonnify · courses", // .topbar brand (layout chrome)
			"(с) jonnify",       // <footer>, Cyrillic с (layout chrome)
			"Choose a course",   // the golden section copy (not the ec.2 placeholder)
			"5 deep dives",      // the golden section mark
			"Open →",            // a rendered card
			`href="/elixir"`,    // the first card's published path
			`href="/bcs"`,       // the last card's published path
			`data-tag="agents"`, // a filter chip
		} {
			if !strings.Contains(body, want) {
				t.Errorf("GET %s body missing %q", path, want)
			}
		}
		if got := strings.Count(body, `class="series-card"`); got != 5 {
			t.Errorf("GET %s rendered %d cards, want 5", path, got)
		}
	}
}

// ec.4 AC2 (HTTP boundary): a published detail path renders its course landing
// through the wiring — the course title in the hero and the course body.
func TestNewEcho_DetailRoute(t *testing.T) {
	e, err := newEcho(t.TempDir(), testCanonicalBase, loadCatalog(t))
	if err != nil {
		t.Fatalf("newEcho: %v", err)
	}

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/elixir", nil)
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("GET /elixir status = %d, want %d", rec.Code, http.StatusOK)
	}
	body := rec.Body.String()
	for _, want := range []string{
		"jonnify · courses",                               // layout chrome
		"Functional Programming",                          // the course title (hero + body <h1>)
		"<title>Functional Programming · jonnify</title>", // the per-page title override
		"deep dive into functional programming",           // the course body landing copy
	} {
		if !strings.Contains(body, want) {
			t.Errorf("GET /elixir body missing %q", want)
		}
	}
}
