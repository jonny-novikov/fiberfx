package main

import (
	"context"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/labstack/echo/v5"
)

// AC2 (wired): newEcho serves GET /healthz with 200 through the middleware chain.
func TestNewEcho_Healthz(t *testing.T) {
	e := newEcho(t.TempDir())

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
	e := newEcho(dir)

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
