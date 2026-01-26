package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all application configuration
type Config struct {
	// Server
	Port     int
	HostName string

	// Database
	Driver      string // "postgres" or "sqlite"
	DatabaseURL string // PostgreSQL connection URL
	SQLitePath  string // SQLite database file path

	// JWT
	JWTSecret     []byte
	JWTExpiry     time.Duration
	JWTIssuer     string
	JWTAudience   string
	CookieName    string
	CookieSecure  bool
	CookieDomain  string

	// Studio (Outerbase Next.js - child process)
	StudioPort    int    // Port where Next.js studio listens (default 3008)
	StudioWorkDir string // Working directory for studio (contains .next/standalone)
	StudioCmd     string // Command to run studio (e.g., "node .next/standalone/server.js")
	MasterPass    string // Password for gateway login (shared secret for admin access)

	// Static files
	WebDir string

	// Debug
	Debug bool
}

// Load creates configuration from environment variables
func Load() *Config {
	return &Config{
		// Server
		Port:     getEnvInt("PORT", 8080),
		HostName: getEnv("HOST_NAME", "codemoji-db-gateway.fly.dev"),

		// Database - driver selection and connection
		Driver:      getEnv("DRIVER", "postgres"),           // "postgres" or "sqlite"
		DatabaseURL: getEnv("DATABASE_URL", ""),             // PostgreSQL connection URL
		SQLitePath:  getEnv("SQLITE_PATH", "./data/app.db"), // SQLite database file path

		// JWT
		JWTSecret:    []byte(getEnv("JWT_SECRET", "dev-secret-do-not-use-in-production")),
		JWTExpiry:    time.Duration(getEnvInt("JWT_EXPIRY_HOURS", 168)) * time.Hour, // 7 days
		JWTIssuer:    "codemoji-gateway",
		JWTAudience:  "outerbase-studio",
		CookieName:   "gateway_token",
		CookieSecure: getEnvBool("COOKIE_SECURE", true),
		CookieDomain: getEnv("COOKIE_DOMAIN", ""),

		// Studio (Outerbase Next.js)
		StudioPort:    getEnvInt("STUDIO_PORT", 3008),
		StudioWorkDir: getEnv("STUDIO_WORK_DIR", "/app/studio"),
		StudioCmd:     getEnv("STUDIO_CMD", "node .next/standalone/server.js"),
		MasterPass:    getEnv("MASTER_PASSWORD", ""),

		// Static files
		WebDir: getEnv("WEB_DIR", "/app/web"),

		// Debug
		Debug: getEnvBool("DEBUG", false),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if i, err := strconv.Atoi(value); err == nil {
			return i
		}
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if b, err := strconv.ParseBool(value); err == nil {
			return b
		}
	}
	return defaultValue
}
