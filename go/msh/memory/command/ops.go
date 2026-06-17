package command

import (
	"bytes"
	"fmt"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
	"github.com/jonny-novikov/msh/memory/internal/render"
	"github.com/jonny-novikov/msh/memory/internal/stale"
)

// The Ops below are string-returning facades over the same corpus/graph/stale
// pipeline the cobra commands drive. They exist so a host (apps/msh's MCP tool
// registrator) can invoke a memory operation programmatically and forward the
// rendered output, without shelling out or re-implementing the pipeline.

// Scan walks the memory root and returns per-node metadata.
// format: "ndjson" (default) | "pretty".
func Scan(root, format string) (string, error) {
	root, err := resolveRoot(root)
	if err != nil {
		return "", err
	}
	if format == "" {
		format = "ndjson"
	}
	g, _, err := loadCorpus(root)
	if err != nil {
		return "", err
	}
	var buf bytes.Buffer
	nodes := g.Nodes()
	switch format {
	case "ndjson":
		err = render.NDJSONNodes(&buf, nodes)
	case "pretty":
		err = render.PrettyScan(&buf, nodes)
	default:
		return "", fmt.Errorf("scan: invalid format %q (want ndjson|pretty)", format)
	}
	if err != nil {
		return "", err
	}
	return buf.String(), nil
}

// Graph builds the cross-reference graph and renders it.
// format: "json" (default) | "dot".
func Graph(root, format string, includeExternal bool) (string, error) {
	root, err := resolveRoot(root)
	if err != nil {
		return "", err
	}
	if format == "" {
		format = "json"
	}
	g, _, err := loadCorpus(root)
	if err != nil {
		return "", err
	}
	var buf bytes.Buffer
	switch format {
	case "json":
		err = graph.RenderJSON(&buf, g, includeExternal)
	case "dot":
		err = graph.RenderDOT(&buf, g, includeExternal)
	default:
		return "", fmt.Errorf("graph: invalid format %q (want json|dot)", format)
	}
	if err != nil {
		return "", err
	}
	return buf.String(), nil
}

// Stale runs stale-detection rules and renders the findings.
// rules: comma-separated names or "all" (default); severity: "warn" (default) |
// "error" | "info"; format: "ndjson" (default) | "pretty".
func Stale(root, configPath, rules, severity, format string) (string, error) {
	root, err := resolveRoot(root)
	if err != nil {
		return "", err
	}
	if format == "" {
		format = "ndjson"
	}
	if severity == "" {
		severity = "warn"
	}
	conf, _, err := config.Resolve(configPath, root)
	if err != nil {
		return "", err
	}
	g, src, err := loadCorpus(root)
	if err != nil {
		return "", err
	}
	findings := stale.Run(g, conf, src, parseRulesList(rules))
	filtered := findings.FilterBySeverity(severity)
	var buf bytes.Buffer
	switch format {
	case "ndjson":
		err = render.NDJSONFindings(&buf, filtered)
	case "pretty":
		err = render.PrettyFindings(&buf, filtered)
	default:
		return "", fmt.Errorf("stale: invalid format %q (want ndjson|pretty)", format)
	}
	if err != nil {
		return "", err
	}
	return buf.String(), nil
}

// Audit runs the composite scan+stale summary (all rules) and returns the
// pretty summary followed by warn-and-above findings.
func Audit(root, configPath string) (string, error) {
	root, err := resolveRoot(root)
	if err != nil {
		return "", err
	}
	conf, _, err := config.Resolve(configPath, root)
	if err != nil {
		return "", err
	}
	g, src, err := loadCorpus(root)
	if err != nil {
		return "", err
	}
	findings := stale.Run(g, conf, src, []string{"all"})
	var buf bytes.Buffer
	if err := render.PrettyAuditSummary(&buf, findings.Counts(), g.NodeCount()); err != nil {
		return "", err
	}
	if err := render.PrettyFindings(&buf, findings.FilterBySeverity(stale.SeverityWarn)); err != nil {
		return "", err
	}
	return buf.String(), nil
}
