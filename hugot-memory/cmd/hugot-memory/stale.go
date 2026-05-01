package main

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"

	"github.com/fiberfx/hugot-memory/internal/config"
	"github.com/fiberfx/hugot-memory/internal/render"
	"github.com/fiberfx/hugot-memory/internal/stale"
)

func newStaleCmd(cfg *rootConfig, flags *globalFlags) *cobra.Command {
	var format string
	var rules string
	var severity string
	cmd := &cobra.Command{
		Use:          "stale",
		Short:        "Run stale-detection rules; emit findings.",
		Long:         "Loads the memory graph, applies the configured stale-detection rules, and emits Finding[] in NDJSON or pretty form. --severity filters output to findings at or above the named threshold.",
		Args:         cobra.NoArgs,
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, _ []string) error {
			format = normalizeFormat(format)
			if err := validateStaleFormat(format); err != nil {
				return err
			}
			if err := validateSeverity(severity); err != nil {
				return err
			}
			root, err := resolveRoot(flags.Root)
			if err != nil {
				return err
			}
			conf, _, err := config.Resolve(flags.Config, root)
			if err != nil {
				return &exitError{code: exitGeneric, err: err}
			}
			g, src, err := loadCorpus(root)
			if err != nil {
				return &exitError{code: exitGeneric, err: err}
			}
			ruleNames := parseRulesList(rules)
			findings := stale.Run(g, conf, src, ruleNames)
			filtered := findings.FilterBySeverity(severity)
			switch format {
			case "ndjson":
				return render.NDJSONFindings(cfg.Stdout, filtered)
			default:
				return render.PrettyFindings(cfg.Stdout, filtered)
			}
		},
	}
	cmd.Flags().StringVar(&format, "format", "ndjson", "Output format: pretty | ndjson")
	cmd.Flags().StringVar(&rules, "rules", "all", "Comma-separated rule names to run (default all)")
	cmd.Flags().StringVar(&severity, "severity", "warn", "Minimum severity: error | warn | info")
	return cmd
}

func validateStaleFormat(f string) error {
	switch f {
	case "pretty", "ndjson":
		return nil
	default:
		return &exitError{code: exitUsage, err: fmt.Errorf("%q: %w", f, errInvalidFormat)}
	}
}

func validateSeverity(s string) error {
	switch s {
	case "error", "warn", "info":
		return nil
	default:
		return &exitError{code: exitUsage, err: fmt.Errorf("%q: %w", s, errInvalidSeverity)}
	}
}

func parseRulesList(s string) []string {
	s = strings.TrimSpace(s)
	if s == "" || strings.EqualFold(s, "all") {
		return []string{"all"}
	}
	parts := strings.Split(s, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}
