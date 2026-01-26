package proxy

import (
	"fmt"
	"log/slog"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"

	"github.com/fireheadz/codemoji-gateway/internal/config"
	"github.com/fireheadz/codemoji-gateway/internal/process"
)

// Handler handles proxying to Outerbase Studio (Next.js)
type Handler struct {
	cfg     *config.Config
	manager *process.Manager
	proxy   *httputil.ReverseProxy
}

// NewHandler creates a new proxy handler for Studio
func NewHandler(cfg *config.Config, manager *process.Manager) *Handler {
	target, _ := url.Parse(fmt.Sprintf("http://127.0.0.1:%d", cfg.StudioPort))

	proxy := httputil.NewSingleHostReverseProxy(target)

	// Customize director to preserve original host and add forwarding headers
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)

		// Set proper forwarding headers for Next.js SSR
		if clientIP := req.Header.Get("X-Forwarded-For"); clientIP == "" {
			req.Header.Set("X-Forwarded-For", req.RemoteAddr)
		}
		req.Header.Set("X-Forwarded-Proto", "https")
		req.Header.Set("X-Real-IP", strings.Split(req.RemoteAddr, ":")[0])
	}

	// Error handler
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		slog.Error("Proxy error",
			"error", err,
			"path", r.URL.Path,
			"method", r.Method,
		)
		http.Error(w, "Studio unavailable", http.StatusBadGateway)
	}

	return &Handler{
		cfg:     cfg,
		manager: manager,
		proxy:   proxy,
	}
}

// ServeHTTP proxies requests to Outerbase Studio
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Check if studio is ready
	if !h.manager.IsReady() {
		http.Error(w, "Studio starting up, please wait...", http.StatusServiceUnavailable)
		return
	}

	// Check if studio is running
	if !h.manager.IsRunning() {
		http.Error(w, "Studio is not running", http.StatusServiceUnavailable)
		return
	}

	// Proxy the request
	h.proxy.ServeHTTP(w, r)
}

// StripPrefix creates a handler that strips prefix before proxying
func (h *Handler) StripPrefix(prefix string) http.Handler {
	return http.StripPrefix(prefix, h)
}
