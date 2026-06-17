// config/config.go
// nginx.conf style configuration parser for datadog toolkit
package config

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Config holds all datadog configuration
type Config struct {
	// API credentials
	API APIConfig `json:"api"`

	// Default filters
	Defaults DefaultsConfig `json:"defaults"`
}

type APIConfig struct {
	Key    string `json:"key"`     // DD_API_KEY or direct value
	AppKey string `json:"app_key"` // DD_APP_KEY or direct value
	Site   string `json:"site"`    // datadoghq.com, datadoghq.eu, etc.
}

type DefaultsConfig struct {
	Env    string `json:"env"`    // Default environment filter
	Output string `json:"output"` // Default output format
}

// Default returns configuration with default values
func Default() *Config {
	return &Config{
		API: APIConfig{
			Key:    "env:DD_API_KEY",
			AppKey: "env:DD_APP_KEY",
			Site:   "datadoghq.com",
		},
		Defaults: DefaultsConfig{
			Env:    "production",
			Output: "json",
		},
	}
}

// Load loads configuration from file(s)
func Load(paths ...string) (*Config, error) {
	cfg := Default()

	for _, path := range paths {
		if err := cfg.loadFile(path); err != nil {
			// Skip missing optional files
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

// LoadFromDir loads datadog.default.conf and datadog.conf from directory
func LoadFromDir(dir string) (*Config, error) {
	defaultConf := filepath.Join(dir, "datadog.default.conf")
	mainConf := filepath.Join(dir, "datadog.conf")
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
	case "api":
		switch key {
		case "key":
			c.API.Key = value
		case "app_key":
			c.API.AppKey = value
		case "site":
			c.API.Site = value
		}

	case "defaults":
		switch key {
		case "env":
			c.Defaults.Env = value
		case "output":
			c.Defaults.Output = value
		}

	default:
		// Top-level shortcuts
		switch key {
		case "api_key":
			c.API.Key = value
		case "app_key":
			c.API.AppKey = value
		}
	}

	return nil
}

func (c *Config) resolveEnvVars() {
	c.API.Key = resolveEnv(c.API.Key)
	c.API.AppKey = resolveEnv(c.API.AppKey)
	c.API.Site = resolveEnv(c.API.Site)
	c.Defaults.Env = resolveEnv(c.Defaults.Env)
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
