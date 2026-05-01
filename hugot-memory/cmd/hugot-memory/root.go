package main

import (
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

type rootConfig struct {
	Stdout io.Writer
	Stderr io.Writer
	Logger *slog.Logger
}

type globalFlags struct {
	LogLevel  string
	LogFormat string
	Root      string
	Config    string
}

func newRootCmd(cfg rootConfig) *cobra.Command {
	if cfg.Stdout == nil {
		cfg.Stdout = os.Stdout
	}
	if cfg.Stderr == nil {
		cfg.Stderr = os.Stderr
	}

	flags := &globalFlags{}

	cmd := &cobra.Command{
		Use:           "hugot-memory",
		Short:         "Memory graph + stale-reference toolchain.",
		Long:          "Walks a memory/ corpus of markdown notes, builds a typed cross-reference graph, and detects stale references via context-aware rules.",
		SilenceUsage:  true,
		SilenceErrors: false,
		PersistentPreRunE: func(cmd *cobra.Command, _ []string) error {
			logger, err := buildLogger(cfg.Stderr, flags)
			if err != nil {
				return fmt.Errorf("init logger: %w", err)
			}
			cfg.Logger = logger
			return nil
		},
	}
	cmd.SetOut(cfg.Stdout)
	cmd.SetErr(cfg.Stderr)

	cmd.PersistentFlags().StringVar(&flags.LogLevel, "log-level", "info", "Log level: debug|info|warn|error")
	cmd.PersistentFlags().StringVar(&flags.LogFormat, "log-format", "text", "Log format: json|text")
	cmd.PersistentFlags().StringVar(&flags.Root, "root", "", "Memory root path (default: walk-up from cwd looking for MEMORY.md)")
	cmd.PersistentFlags().StringVar(&flags.Config, "config", "", "Path to hugot-memory.yaml (default: <root>/hugot-memory.yaml or <root>/.hugot-memory.yaml)")

	cmd.AddCommand(newScanCmd(&cfg, flags))
	cmd.AddCommand(newGraphCmd(&cfg, flags))
	cmd.AddCommand(newStaleCmd(&cfg, flags))
	cmd.AddCommand(newAuditCmd(&cfg, flags))
	cmd.AddCommand(newVersionCmd(&cfg))

	return cmd
}

func buildLogger(sink io.Writer, flags *globalFlags) (*slog.Logger, error) {
	level, err := parseLogLevel(flags.LogLevel)
	if err != nil {
		return nil, err
	}
	opts := &slog.HandlerOptions{Level: level}
	switch strings.ToLower(flags.LogFormat) {
	case "", "text":
		return slog.New(slog.NewTextHandler(sink, opts)), nil
	case "json":
		return slog.New(slog.NewJSONHandler(sink, opts)), nil
	default:
		return nil, fmt.Errorf("unknown log format: %s (want json|text)", flags.LogFormat)
	}
}

func parseLogLevel(raw string) (slog.Level, error) {
	switch strings.ToLower(raw) {
	case "debug":
		return slog.LevelDebug, nil
	case "", "info":
		return slog.LevelInfo, nil
	case "warn", "warning":
		return slog.LevelWarn, nil
	case "error", "err":
		return slog.LevelError, nil
	default:
		return 0, fmt.Errorf("unknown log level: %s (want debug|info|warn|error)", raw)
	}
}

func resolveRoot(explicit string) (string, error) {
	if explicit != "" {
		abs, err := filepath.Abs(explicit)
		if err != nil {
			return "", fmt.Errorf("resolve --root %q: %w", explicit, err)
		}
		if _, err := os.Stat(abs); err != nil {
			return "", fmt.Errorf("resolve --root %q: %w", explicit, err)
		}
		return abs, nil
	}
	cwd, err := os.Getwd()
	if err != nil {
		return "", fmt.Errorf("resolve cwd: %w", err)
	}
	dir := cwd
	for {
		if hasMemoryMarker(dir) {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", &exitError{code: exitUsage, err: errRootRequired}
		}
		dir = parent
	}
}

func hasMemoryMarker(dir string) bool {
	if _, err := os.Stat(filepath.Join(dir, "MEMORY.md")); err == nil {
		return true
	}
	if _, err := os.Stat(filepath.Join(dir, ".hugot-memory.yaml")); err == nil {
		return true
	}
	if _, err := os.Stat(filepath.Join(dir, "hugot-memory.yaml")); err == nil {
		return true
	}
	return false
}
