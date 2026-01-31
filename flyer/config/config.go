// config/config.go
// nginx.conf style configuration parser for flyer
package config

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

// Config holds all flyer configuration
type Config struct {
	// Database settings (SQLite for FWHD)
	Database DatabaseConfig `json:"database"`

	// S3/Tigris settings
	S3 S3Config `json:"s3"`

	// Litestream settings
	Litestream LitestreamConfig `json:"litestream"`

	// Packages settings
	Packages PackagesConfig `json:"packages"`

	// Sync settings
	Sync SyncConfig `json:"sync"`

	// PostgreSQL settings (for pg commands)
	Postgres PostgresConfig `json:"postgres"`
}

type DatabaseConfig struct {
	Path string `json:"path"`
}

type S3Config struct {
	Endpoint  string `json:"endpoint"`
	Bucket    string `json:"bucket"`
	AccessKey string `json:"access_key"` // Can use env: prefix
	SecretKey string `json:"secret_key"` // Can use env: prefix
	Region    string `json:"region"`
}

type LitestreamConfig struct {
	ConfigPath             string `json:"config_path"`
	ReplicaURL             string `json:"replica_url"`
	RetentionDays          int    `json:"retention_days"`
	S3Path                 string `json:"s3_path"`
	SyncInterval           string `json:"sync_interval"`
	SnapshotInterval       string `json:"snapshot_interval"`
	Retention              string `json:"retention"`
	RetentionCheckInterval string `json:"retention_check_interval"`
	ValidationInterval     string `json:"validation_interval"`
}

type PackagesConfig struct {
	Dir        string `json:"dir"`
	EntryPoint string `json:"entry_point"`
}

type SyncConfig struct {
	Component string `json:"component"`
	Timeout   int    `json:"timeout"`
}

// PostgresConfig holds PostgreSQL connection settings for pg commands
type PostgresConfig struct {
	Host      string `json:"host"`
	Port      int    `json:"port"`
	Database  string `json:"database"`
	User      string `json:"user"`
	Password  string `json:"password"`   // Can use env: prefix
	ExportDir string `json:"export_dir"` // CSV export directory
	SQLDir    string `json:"sql_dir"`    // phoenix/sql directory
}

// Default returns configuration with default values
func Default() *Config {
	return &Config{
		Database: DatabaseConfig{
			Path: "/app/data/packages.db",
		},
		S3: S3Config{
			Endpoint:  "https://fly.storage.tigris.dev",
			Bucket:    "fwhd-packages",
			AccessKey: "env:AWS_ACCESS_KEY_ID",
			SecretKey: "env:AWS_SECRET_ACCESS_KEY",
			Region:    "auto",
		},
		Litestream: LitestreamConfig{
			ConfigPath:             "/app/litestream.yml",
			RetentionDays:          7,
			S3Path:                 "db/packages",
			SyncInterval:           "10s",
			SnapshotInterval:       "1h",
			Retention:              "72h",
			RetentionCheckInterval: "1h",
			ValidationInterval:     "1h",
		},
		Packages: PackagesConfig{
			Dir:        "/app/packages",
			EntryPoint: "dist/index.js",
		},
		Sync: SyncConfig{
			Component: "backend",
			Timeout:   60,
		},
		Postgres: PostgresConfig{
			Host:      "localhost",
			Port:      25432,
			Database:  "codemoji_game",
			User:      "fireheadz_studio",
			Password:  "env:PG_PASS",
			ExportDir: "/tmp/codemoji-migration",
			SQLDir:    "",
		},
	}
}

// Load loads configuration from file(s)
// Supports nginx-style include directives
func Load(paths ...string) (*Config, error) {
	cfg := Default()

	for _, path := range paths {
		if err := cfg.loadFile(path); err != nil {
			// Skip missing optional files (like flyer.conf)
			if os.IsNotExist(err) && !strings.HasSuffix(path, ".default.conf") {
				continue
			}
			return nil, fmt.Errorf("load %s: %w", path, err)
		}
	}

	// Resolve env: prefixes
	cfg.resolveEnvVars()

	return cfg, nil
}

// LoadFromDir loads flyer.default.conf and flyer.conf from directory
func LoadFromDir(dir string) (*Config, error) {
	defaultConf := filepath.Join(dir, "flyer.default.conf")
	mainConf := filepath.Join(dir, "flyer.conf")
	return Load(defaultConf, mainConf)
}

func (c *Config) loadFile(path string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	var currentBlock string
	lineNum := 0

	for scanner.Scan() {
		lineNum++
		line := strings.TrimSpace(scanner.Text())

		// Skip empty lines and comments
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Handle include directive
		if strings.HasPrefix(line, "include ") {
			includePath := strings.TrimPrefix(line, "include ")
			includePath = strings.Trim(includePath, "\";")
			// Resolve relative paths
			if !filepath.IsAbs(includePath) {
				includePath = filepath.Join(filepath.Dir(path), includePath)
			}
			if err := c.loadFile(includePath); err != nil {
				return fmt.Errorf("line %d: %w", lineNum, err)
			}
			continue
		}

		// Handle block start
		if strings.HasSuffix(line, "{") {
			currentBlock = strings.TrimSuffix(strings.TrimSpace(line), "{")
			currentBlock = strings.TrimSpace(currentBlock)
			continue
		}

		// Handle block end
		if line == "}" {
			currentBlock = ""
			continue
		}

		// Parse directive
		if err := c.parseDirective(currentBlock, line); err != nil {
			return fmt.Errorf("line %d: %w", lineNum, err)
		}
	}

	return scanner.Err()
}

var directiveRe = regexp.MustCompile(`^(\w+)\s+(.+?);?$`)

func (c *Config) parseDirective(block, line string) error {
	// Remove trailing semicolon
	line = strings.TrimSuffix(line, ";")

	matches := directiveRe.FindStringSubmatch(line)
	if matches == nil {
		return fmt.Errorf("invalid directive: %s", line)
	}

	key := matches[1]
	value := strings.Trim(matches[2], "\"'")

	switch block {
	case "database":
		switch key {
		case "path":
			c.Database.Path = value
		}

	case "s3":
		switch key {
		case "endpoint":
			c.S3.Endpoint = value
		case "bucket":
			c.S3.Bucket = value
		case "access_key":
			c.S3.AccessKey = value
		case "secret_key":
			c.S3.SecretKey = value
		case "region":
			c.S3.Region = value
		}

	case "litestream":
		switch key {
		case "config_path":
			c.Litestream.ConfigPath = value
		case "replica_url":
			c.Litestream.ReplicaURL = value
		case "retention_days":
			if v, err := strconv.Atoi(value); err == nil {
				c.Litestream.RetentionDays = v
			}
		case "s3_path":
			c.Litestream.S3Path = value
		case "sync_interval":
			c.Litestream.SyncInterval = value
		case "snapshot_interval":
			c.Litestream.SnapshotInterval = value
		case "retention":
			c.Litestream.Retention = value
		case "retention_check_interval":
			c.Litestream.RetentionCheckInterval = value
		case "validation_interval":
			c.Litestream.ValidationInterval = value
		}

	case "packages":
		switch key {
		case "dir":
			c.Packages.Dir = value
		case "entry_point":
			c.Packages.EntryPoint = value
		}

	case "sync":
		switch key {
		case "component":
			c.Sync.Component = value
		case "timeout":
			if v, err := strconv.Atoi(value); err == nil {
				c.Sync.Timeout = v
			}
		}

	case "postgres":
		switch key {
		case "host":
			c.Postgres.Host = value
		case "port":
			if v, err := strconv.Atoi(value); err == nil {
				c.Postgres.Port = v
			}
		case "database":
			c.Postgres.Database = value
		case "user":
			c.Postgres.User = value
		case "password":
			c.Postgres.Password = value
		case "export_dir":
			c.Postgres.ExportDir = value
		case "sql_dir":
			c.Postgres.SQLDir = value
		}

	default:
		// Top-level directives (shortcuts)
		switch key {
		case "db_path":
			c.Database.Path = value
		case "packages_dir":
			c.Packages.Dir = value
		}
	}

	return nil
}

func (c *Config) resolveEnvVars() {
	c.S3.AccessKey = resolveEnv(c.S3.AccessKey)
	c.S3.SecretKey = resolveEnv(c.S3.SecretKey)
	c.S3.Endpoint = resolveEnv(c.S3.Endpoint)
	c.S3.Bucket = resolveEnv(c.S3.Bucket)
	c.Database.Path = resolveEnv(c.Database.Path)
	c.Packages.Dir = resolveEnv(c.Packages.Dir)
	c.Litestream.ConfigPath = resolveEnv(c.Litestream.ConfigPath)
	// PostgreSQL config
	c.Postgres.Host = resolveEnv(c.Postgres.Host)
	c.Postgres.Database = resolveEnv(c.Postgres.Database)
	c.Postgres.User = resolveEnv(c.Postgres.User)
	c.Postgres.Password = resolveEnv(c.Postgres.Password)
	c.Postgres.ExportDir = resolveEnv(c.Postgres.ExportDir)
	c.Postgres.SQLDir = resolveEnv(c.Postgres.SQLDir)
}

func resolveEnv(value string) string {
	if strings.HasPrefix(value, "env:") {
		envName := strings.TrimPrefix(value, "env:")
		return os.Getenv(envName)
	}
	// Also handle ${VAR} syntax
	if strings.Contains(value, "${") {
		re := regexp.MustCompile(`\$\{(\w+)\}`)
		return re.ReplaceAllStringFunc(value, func(match string) string {
			envName := strings.Trim(match, "${}")
			return os.Getenv(envName)
		})
	}
	return value
}
