// internal/pgdb/config.go
// PostgreSQL configuration for flyer pg commands

package pgdb

import (
	"fmt"
	"os"
	"strconv"
)

// Config holds PostgreSQL connection parameters
type Config struct {
	Host      string
	Port      int
	Database  string
	User      string
	Password  string
	ExportDir string
	SQLDir    string
}

// DefaultConfig returns configuration with default values
func DefaultConfig() *Config {
	return &Config{
		Host:      "localhost",
		Port:      25432,
		Database:  "codemoji_game",
		User:      "fireheadz_studio",
		Password:  "",
		ExportDir: "/tmp/codemoji-migration",
		SQLDir:    "",
	}
}

// LoadFromEnv loads configuration from environment variables
func LoadFromEnv() *Config {
	cfg := DefaultConfig()

	if v := os.Getenv("PG_HOST"); v != "" {
		cfg.Host = v
	}
	if v := os.Getenv("PG_PORT"); v != "" {
		if port, err := strconv.Atoi(v); err == nil {
			cfg.Port = port
		}
	}
	if v := os.Getenv("PG_NAME"); v != "" {
		cfg.Database = v
	}
	if v := os.Getenv("PG_USER"); v != "" {
		cfg.User = v
	}
	if v := os.Getenv("PG_PASS"); v != "" {
		cfg.Password = v
	}
	if v := os.Getenv("EXPORT_DIR"); v != "" {
		cfg.ExportDir = v
	}
	if v := os.Getenv("SQL_DIR"); v != "" {
		cfg.SQLDir = v
	}

	return cfg
}

// ConnString returns the PostgreSQL connection string
func (c *Config) ConnString() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=disable",
		c.User, c.Password, c.Host, c.Port, c.Database,
	)
}

// Validate checks if required configuration is present
func (c *Config) Validate() error {
	if c.Password == "" {
		return fmt.Errorf("PG_PASS environment variable is required")
	}
	return nil
}

// String returns a human-readable config summary (no password)
func (c *Config) String() string {
	return fmt.Sprintf("%s@%s:%d/%s", c.User, c.Host, c.Port, c.Database)
}

// PostgresConfigSource defines the interface for flyer config's PostgresConfig
// This avoids import cycle between config and pgdb packages
type PostgresConfigSource interface {
	GetHost() string
	GetPort() int
	GetDatabase() string
	GetUser() string
	GetPassword() string
	GetExportDir() string
	GetSQLDir() string
}

// LoadFromConfig creates Config from flyer.conf PostgresConfig values.
// Falls back to defaults for empty values, then applies env var overrides.
func LoadFromConfig(host string, port int, database, user, password, exportDir, sqlDir string) *Config {
	cfg := DefaultConfig()

	// Apply non-empty config values
	if host != "" {
		cfg.Host = host
	}
	if port > 0 {
		cfg.Port = port
	}
	if database != "" {
		cfg.Database = database
	}
	if user != "" {
		cfg.User = user
	}
	if password != "" {
		cfg.Password = password
	}
	if exportDir != "" {
		cfg.ExportDir = exportDir
	}
	if sqlDir != "" {
		cfg.SQLDir = sqlDir
	}

	return cfg
}
