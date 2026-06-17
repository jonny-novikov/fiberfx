package config

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

type Config struct {
	DeletedPaths             []string         `yaml:"deleted_paths"`
	RemovedTools             []string         `yaml:"removed_tools"`
	ContextWhitelistKeywords []string         `yaml:"context_whitelist_keywords"`
	IgnoreOrphans            []string         `yaml:"ignore_orphans"`
	Hugot                    HugotConfig      `yaml:"hugot"`
	Similarity               SimilarityConfig `yaml:"similarity"`
}

type HugotConfig struct {
	Endpoint       string `yaml:"endpoint"`
	Model          string `yaml:"model"`
	TimeoutSeconds int    `yaml:"timeout_seconds"`
}

type SimilarityConfig struct {
	DefaultThreshold float64 `yaml:"default_threshold"`
	DefaultTopK      int     `yaml:"default_top_k"`
}

func Resolve(explicitPath, root string) (*Config, string, error) {
	if explicitPath != "" {
		cfg, err := loadFile(explicitPath)
		if err != nil {
			return nil, "", fmt.Errorf("config: load %q: %w", explicitPath, err)
		}
		return cfg, explicitPath, nil
	}
	candidates := []string{
		filepath.Join(root, "msh-memory.yaml"),
		filepath.Join(root, ".msh-memory.yaml"),
	}
	for _, c := range candidates {
		cfg, err := loadFile(c)
		if err == nil {
			return cfg, c, nil
		}
		if !errors.Is(err, fs.ErrNotExist) {
			return nil, "", fmt.Errorf("config: load %q: %w", c, err)
		}
	}
	return Defaults(), "<defaults>", nil
}

func loadFile(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("yaml: %w", err)
	}
	mergeDefaults(&cfg)
	return &cfg, nil
}

func mergeDefaults(cfg *Config) {
	d := Defaults()
	if len(cfg.DeletedPaths) == 0 {
		cfg.DeletedPaths = d.DeletedPaths
	}
	if len(cfg.RemovedTools) == 0 {
		cfg.RemovedTools = d.RemovedTools
	}
	if len(cfg.ContextWhitelistKeywords) == 0 {
		cfg.ContextWhitelistKeywords = d.ContextWhitelistKeywords
	}
	if len(cfg.IgnoreOrphans) == 0 {
		cfg.IgnoreOrphans = d.IgnoreOrphans
	}
	if cfg.Hugot.Endpoint == "" {
		cfg.Hugot.Endpoint = d.Hugot.Endpoint
	}
	if cfg.Hugot.TimeoutSeconds == 0 {
		cfg.Hugot.TimeoutSeconds = d.Hugot.TimeoutSeconds
	}
	if cfg.Similarity.DefaultThreshold == 0 {
		cfg.Similarity.DefaultThreshold = d.Similarity.DefaultThreshold
	}
	if cfg.Similarity.DefaultTopK == 0 {
		cfg.Similarity.DefaultTopK = d.Similarity.DefaultTopK
	}
}
