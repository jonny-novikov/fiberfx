package static

import (
	"io"
	"log/slog"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/fireheadz/codemoji-gateway/internal/auth"
	"github.com/fireheadz/codemoji-gateway/internal/config"
)

// Handler serves static files with memory-mapped caching
type Handler struct {
	cfg   *config.Config
	cache *FileCache
}

// FileCache caches file contents in memory
type FileCache struct {
	mu    sync.RWMutex
	files map[string]*CachedFile
}

// CachedFile represents a cached file
type CachedFile struct {
	Content     []byte
	ContentType string
	ModTime     int64
}

// NewHandler creates a new static file handler
func NewHandler(cfg *config.Config) *Handler {
	return &Handler{
		cfg: cfg,
		cache: &FileCache{
			files: make(map[string]*CachedFile),
		},
	}
}

// ServeHTTP handles static file requests
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path

	// Check authentication for protected paths
	if h.requiresAuth(path) && !auth.IsAuthenticated(r.Context()) {
		// Redirect to login for HTML requests
		if acceptsHTML(r) {
			http.Redirect(w, r, "/login", http.StatusTemporaryRedirect)
			return
		}
		// Return 404 for API/asset requests (security through obscurity)
		http.NotFound(w, r)
		return
	}

	// Clean path
	if path == "/" {
		path = "/index.html"
	}

	// Try to serve from cache first
	if cached := h.cache.Get(path); cached != nil {
		h.serveFromCache(w, r, cached)
		return
	}

	// Build file path
	filePath := filepath.Join(h.cfg.WebDir, filepath.Clean(path))

	// Security: ensure we don't escape webdir
	// Normalize both paths to handle ./prefix differences
	absWebDir, _ := filepath.Abs(h.cfg.WebDir)
	absFilePath, _ := filepath.Abs(filePath)
	if !strings.HasPrefix(absFilePath, absWebDir) {
		http.NotFound(w, r)
		return
	}

	// Check if file exists
	info, err := os.Stat(filePath)
	if err != nil {
		// Try with .html extension
		htmlPath := filePath + ".html"
		if _, err := os.Stat(htmlPath); err == nil {
			filePath = htmlPath
			info, _ = os.Stat(filePath)
		} else {
			// SPA fallback - serve index.html for routes
			if acceptsHTML(r) && !hasExtension(path) {
				h.serveSPA(w, r)
				return
			}
			http.NotFound(w, r)
			return
		}
	}

	// Don't serve directories
	if info.IsDir() {
		indexPath := filepath.Join(filePath, "index.html")
		if _, err := os.Stat(indexPath); err == nil {
			filePath = indexPath
		} else {
			http.NotFound(w, r)
			return
		}
	}

	// Read and cache file
	content, err := os.ReadFile(filePath)
	if err != nil {
		slog.Error("Failed to read file", "path", filePath, "error", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	// Determine content type
	contentType := mime.TypeByExtension(filepath.Ext(filePath))
	if contentType == "" {
		contentType = http.DetectContentType(content)
	}

	// Cache the file
	cached := &CachedFile{
		Content:     content,
		ContentType: contentType,
		ModTime:     info.ModTime().Unix(),
	}
	h.cache.Set(path, cached)

	h.serveFromCache(w, r, cached)
}

// requiresAuth returns true if the path requires authentication
func (h *Handler) requiresAuth(path string) bool {
	// Login page and its assets don't require auth
	if path == "/login" || path == "/login.html" {
		return false
	}

	// Static assets for login page
	if strings.HasPrefix(path, "/assets/") {
		return false
	}

	// Health check
	if path == "/health" || path == "/api/health" {
		return false
	}

	// Auth endpoints
	if strings.HasPrefix(path, "/api/auth/") {
		return false
	}

	// Everything else requires auth
	return true
}

// serveSPA serves the SPA index.html for client-side routing
func (h *Handler) serveSPA(w http.ResponseWriter, r *http.Request) {
	indexPath := filepath.Join(h.cfg.WebDir, "index.html")
	content, err := os.ReadFile(indexPath)
	if err != nil {
		http.NotFound(w, r)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	w.Write(content)
}

// serveFromCache serves a file from cache
func (h *Handler) serveFromCache(w http.ResponseWriter, r *http.Request, cached *CachedFile) {
	// Set headers
	w.Header().Set("Content-Type", cached.ContentType)

	// Cache control based on content type
	if strings.HasPrefix(cached.ContentType, "text/html") {
		w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	} else if strings.Contains(cached.ContentType, "javascript") ||
		strings.Contains(cached.ContentType, "css") {
		// Immutable for hashed assets
		w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
	} else {
		w.Header().Set("Cache-Control", "public, max-age=3600")
	}

	// Write content
	w.WriteHeader(http.StatusOK)
	io.Copy(w, strings.NewReader(string(cached.Content)))
}

// Get retrieves a file from cache
func (c *FileCache) Get(path string) *CachedFile {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.files[path]
}

// Set stores a file in cache
func (c *FileCache) Set(path string, file *CachedFile) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.files[path] = file
}

// Clear clears the cache
func (c *FileCache) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.files = make(map[string]*CachedFile)
}

// Helper functions

func acceptsHTML(r *http.Request) bool {
	accept := r.Header.Get("Accept")
	return strings.Contains(accept, "text/html") ||
		strings.Contains(accept, "*/*") ||
		accept == ""
}

func hasExtension(path string) bool {
	ext := filepath.Ext(path)
	return ext != ""
}
