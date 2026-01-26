package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/fireheadz/codemoji-gateway/internal/auth"
	"github.com/fireheadz/codemoji-gateway/internal/config"
	"github.com/fireheadz/codemoji-gateway/internal/db"
	"github.com/fireheadz/codemoji-gateway/internal/process"
	"github.com/fireheadz/codemoji-gateway/internal/proxy"
	"github.com/fireheadz/codemoji-gateway/internal/static"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env file (optional - won't fail if missing)
	// Priority: .env (default), then .env.local for overrides if needed
	_ = godotenv.Load(".env")

	// Setup structured logging
	handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	})
	slog.SetDefault(slog.New(handler))

	// Load configuration
	cfg := config.Load()

	slog.Info("Starting Codemoji Gateway",
		"port", cfg.Port,
		"studio_port", cfg.StudioPort,
		"driver", cfg.Driver,
	)

	// Connect to PostgreSQL (always needed for auth)
	pool, err := connectDatabase(cfg)
	if err != nil {
		slog.Error("Failed to connect to database", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	// Create database driver based on configuration
	dbDriver, err := createDatabaseDriver(cfg, pool)
	if err != nil {
		slog.Error("Failed to create database driver", "error", err)
		os.Exit(1)
	}
	defer dbDriver.Close()

	// Create handlers
	authHandler := auth.NewHandler(cfg, pool)
	dbHandler := db.NewHandler(dbDriver)
	processManager := process.NewManager(cfg)
	studioProxy := proxy.NewHandler(cfg, processManager)
	staticHandler := static.NewHandler(cfg)

	// Start Outerbase Studio child process
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	if err := processManager.Start(ctx); err != nil {
		slog.Error("Failed to start Studio", "error", err)
		os.Exit(1)
	}

	// Setup router
	r := chi.NewRouter()

	// Global middleware
	r.Use(middleware.RealIP)
	r.Use(middleware.RequestID)
	r.Use(middleware.Recoverer)
	r.Use(securityHeaders)

	if cfg.Debug {
		r.Use(middleware.Logger)
	}

	// Health endpoints (no auth)
	r.Get("/health", handleHealth(processManager))
	r.Get("/api/health", handleHealth(processManager))

	// Auth API endpoints (no auth required)
	r.Route("/api/auth", func(r chi.Router) {
		r.Post("/login", authHandler.HandleLogin)
		r.Options("/login", authHandler.HandleLogin) // CORS preflight
		r.Post("/logout", authHandler.HandleLogout)
	})

	// Protected auth endpoints
	r.Route("/api/me", func(r chi.Router) {
		r.Use(authHandler.Middleware)
		r.Get("/", authHandler.HandleMe)
	})

	// Database query endpoint (protected)
	// Matches Outerbase Cloud API contract for LocalPostgresQueryable
	r.Route("/api/db", func(r chi.Router) {
		r.Use(authHandler.Middleware)
		r.Post("/query", dbHandler.HandleQuery)
		r.Options("/query", dbHandler.HandleQuery) // CORS preflight
	})

	// Login page and assets - Svelte SPA (no auth)
	r.Get("/login", staticHandler.ServeHTTP)
	r.Get("/login/*", staticHandler.ServeHTTP)
	r.Get("/assets/*", staticHandler.ServeHTTP)

	// Outerbase Studio at root (protected)
	// Auth middleware redirects to /login if not authenticated
	// All requests proxy to localhost:3008 (Next.js standalone)
	// Use NotFound as catch-all to avoid route priority issues
	r.NotFound(func(w http.ResponseWriter, req *http.Request) {
		// Apply auth middleware manually
		authHandler.MiddlewareWithRedirect("/login")(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			studioProxy.ServeHTTP(w, req)
		})).ServeHTTP(w, req)
	})

	// Create server
	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      r,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Graceful shutdown
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	// Start server
	go func() {
		slog.Info("Server listening", "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("Server error", "error", err)
			os.Exit(1)
		}
	}()

	// Wait for shutdown signal
	<-shutdown
	slog.Info("Shutting down...")

	// Shutdown server
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		slog.Error("Server shutdown error", "error", err)
	}

	// Stop child process
	if err := processManager.Stop(); err != nil {
		slog.Error("Failed to stop Studio", "error", err)
	}

	slog.Info("Goodbye!")
}

// createDatabaseDriver creates the appropriate database driver based on configuration
func createDatabaseDriver(cfg *config.Config, pool *pgxpool.Pool) (db.Driver, error) {
	switch cfg.Driver {
	case "sqlite":
		slog.Info("Using SQLite driver", "path", cfg.SQLitePath)
		return db.NewSQLiteDriver(cfg.SQLitePath)
	case "postgres":
		fallthrough
	default:
		slog.Info("Using PostgreSQL driver")
		return db.NewPostgresDriver(pool), nil
	}
}

// connectDatabase connects to PostgreSQL
func connectDatabase(cfg *config.Config) (*pgxpool.Pool, error) {
	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}

	poolConfig, err := pgxpool.ParseConfig(cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database URL: %w", err)
	}

	// Configure pool
	poolConfig.MaxConns = 5
	poolConfig.MinConns = 1
	poolConfig.MaxConnLifetime = 30 * time.Minute
	poolConfig.MaxConnIdleTime = 5 * time.Minute

	pool, err := pgxpool.NewWithConfig(context.Background(), poolConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create pool: %w", err)
	}

	// Test connection
	if err := pool.Ping(context.Background()); err != nil {
		pool.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	slog.Info("Connected to database")
	return pool, nil
}

// handleHealth returns health status
func handleHealth(pm *process.Manager) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		status := "healthy"
		httpStatus := http.StatusOK

		if !pm.IsRunning() {
			status = "studio_stopped"
			httpStatus = http.StatusServiceUnavailable
		} else if !pm.IsReady() {
			status = "studio_starting"
			httpStatus = http.StatusServiceUnavailable
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(httpStatus)
		fmt.Fprintf(w, `{"status":"%s","studio_running":%t,"studio_ready":%t}`,
			status, pm.IsRunning(), pm.IsReady())
	}
}

// securityHeaders adds security headers
func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
		w.Header().Set("Permissions-Policy", "camera=(), microphone=(), geolocation=()")

		// HSTS for HTTPS
		if r.TLS != nil || r.Header.Get("X-Forwarded-Proto") == "https" {
			w.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		}

		next.ServeHTTP(w, r)
	})
}
