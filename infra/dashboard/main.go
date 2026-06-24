// codemojex-dashboard — a Gin web server that fronts pgweb (Postgres browser)
// and a native Valkey monitor behind one HTTPS surface.
//
// Topology: this app reaches codemojex-db and echo-valkey over Fly's private
// 6PN. It runs pgweb as a supervised child process under the URL prefix /db, so
// pgweb owns /db/* (its own assets and API included) with no collision against
// this server's own routes. No PgBouncer: the connection counts here and in the
// game app are bounded by their own pools, well under Postgres max_connections.
package main

import (
	"context"
	"embed"
	"io/fs"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

//go:embed all:web/dist
var embeddedUI embed.FS

const (
	listenAddr = ":8080"
	pgwebBind  = "127.0.0.1"
	pgwebPort  = "8081"
	pgwebPath  = "/db" // pgweb is mounted (and prefixed) here
)

type config struct {
	dashUser    string
	dashPass    string
	pgwebDBURL  string // postgres://codemojex_ro:...@codemojex-db.internal:5432/codemojex?sslmode=disable
	valkeyAddr  string // echo-valkey.internal:6390
}

func mustEnv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		log.Fatalf("missing required env %s", k)
	}
	return v
}

func main() {
	gin.SetMode(gin.ReleaseMode)
	cfg := config{
		dashUser:   mustEnv("DASH_USER"),
		dashPass:   mustEnv("DASH_PASS"),
		pgwebDBURL: mustEnv("PGWEB_DATABASE_URL"),
		valkeyAddr: mustEnv("VALKEY_ADDRESS"),
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go supervisePgweb(ctx, cfg)

	vk, err := newValkeyMonitor(cfg.valkeyAddr)
	if err != nil {
		log.Printf("valkey monitor init: %v (will report errors per request)", err)
	}
	defer func() {
		if vk != nil {
			vk.Close()
		}
	}()

	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())

	// Public liveness for Fly checks (registered before auth).
	r.GET("/healthz", func(c *gin.Context) { c.String(http.StatusOK, "ok") })

	// Everything below is gated by HTTP basic auth.
	r.Use(gin.BasicAuth(gin.Accounts{cfg.dashUser: cfg.dashPass}))

	// Native Valkey monitor API.
	api := r.Group("/api")
	{
		api.GET("/valkey/overview", guard(vk, (*valkeyMonitor).Overview))
		api.GET("/valkey/clients", guard(vk, (*valkeyMonitor).Clients))
		api.GET("/valkey/slowlog", guard(vk, (*valkeyMonitor).Slowlog))
	}

	// pgweb, reverse-proxied at /db. Because pgweb runs with --prefix=/db, it
	// emits URLs already under /db — a clean pass-through, no rewriting.
	target, err := url.Parse("http://" + pgwebBind + ":" + pgwebPort)
	if err != nil {
		log.Fatalf("pgweb target: %v", err)
	}
	proxy := gin.WrapH(httputil.NewSingleHostReverseProxy(target))
	r.Any(pgwebPath, proxy)
	r.Any(pgwebPath+"/*rest", proxy)

	// Svelte SPA at the root, embedded in the binary.
	mountUI(r)

	srv := &http.Server{
		Addr:         listenAddr,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 60 * time.Second,
	}
	go func() {
		log.Printf("codemojex-dashboard on %s (pgweb under %s)", listenAddr, pgwebPath)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v", err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	<-stop
	cancel()
	sctx, c2 := context.WithTimeout(context.Background(), 10*time.Second)
	defer c2()
	_ = srv.Shutdown(sctx)
}

// guard returns a 503 when the Valkey client failed to initialize.
func guard(vk *valkeyMonitor, h func(*valkeyMonitor, *gin.Context)) gin.HandlerFunc {
	return func(c *gin.Context) {
		if vk == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "valkey unavailable"})
			return
		}
		h(vk, c)
	}
}

// supervisePgweb runs pgweb as a child process and restarts it if it exits.
func supervisePgweb(ctx context.Context, cfg config) {
	for ctx.Err() == nil {
		cmd := exec.CommandContext(ctx, "pgweb",
			"--bind", pgwebBind,
			"--listen", pgwebPort,
			"--prefix", pgwebPath+"/",
			"--url", cfg.pgwebDBURL,
			"--readonly",
			"--skip-open",
		)
		cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
		log.Printf("starting pgweb under %s", pgwebPath)
		if err := cmd.Run(); err != nil && ctx.Err() == nil {
			log.Printf("pgweb exited: %v; restarting in 2s", err)
			time.Sleep(2 * time.Second)
		}
	}
}

func mountUI(r *gin.Engine) {
	uiFS, err := fs.Sub(embeddedUI, "web/dist")
	if err != nil {
		log.Fatalf("embed web/dist: %v", err)
	}
	fileServer := http.FileServer(http.FS(uiFS))
	r.NoRoute(func(c *gin.Context) {
		p := c.Request.URL.Path
		if strings.HasPrefix(p, pgwebPath) || strings.HasPrefix(p, "/api") {
			c.Status(http.StatusNotFound)
			return
		}
		if rel := strings.TrimPrefix(p, "/"); rel != "" {
			if _, statErr := fs.Stat(uiFS, rel); statErr == nil {
				fileServer.ServeHTTP(c.Writer, c.Request)
				return
			}
		}
		c.Request.URL.Path = "/" // SPA fallback to index.html
		fileServer.ServeHTTP(c.Writer, c.Request)
	})
}
