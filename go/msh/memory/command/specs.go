package command

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"

	"github.com/jonny-novikov/msh/memory/internal/render"
	"github.com/jonny-novikov/msh/memory/internal/speclint"
)

// SpecsLinks checks a docs/specs tree for stale (broken) markdown links and
// missing heading anchors, and renders the findings. It is the shared facade
// behind both the `msh specs` CLI command and the mcp__msh__specs tool — one
// implementation, two surfaces, mirroring Stale/Audit above.
//
// area selects the tree: an existing path (absolute or cwd-relative directory)
// is used as-is; otherwise area is an area NAME resolved to <repo>/<base>/<area>
// (base defaults to "docs"), where <repo> is the directory holding
// .msh-memory.json, else the nearest .git, else the cwd. An empty area falls
// back to the active project's name in .msh-memory.json (e.g. "echo_mq").
//
// format: "ndjson" (default) | "pretty" | "audit"; severity: "error" | "warn"
// (default) | "info" — the minimum severity reported.
func SpecsLinks(area, base, format, severity string) (string, error) {
	dir, repoRoot, err := resolveSpecsDir(area, base)
	if err != nil {
		return "", err
	}
	if format == "" {
		format = "ndjson"
	}
	if severity == "" {
		severity = "warn"
	}

	res, err := speclint.Check(dir, repoRoot)
	if err != nil {
		return "", &exitError{code: exitGeneric, err: err}
	}
	filtered := res.Findings.FilterBySeverity(severity)

	var buf bytes.Buffer
	switch format {
	case "ndjson":
		err = render.NDJSONFindings(&buf, filtered)
	case "pretty":
		err = render.PrettyFindings(&buf, filtered)
	case "audit":
		if e := render.PrettyAuditSummary(&buf, res.Findings.Counts(), res.Files); e != nil {
			return "", e
		}
		err = render.PrettyFindings(&buf, filtered)
	default:
		return "", &exitError{code: exitUsage, err: fmt.Errorf("specs: invalid format %q (want ndjson|pretty|audit)", format)}
	}
	if err != nil {
		return "", err
	}
	return buf.String(), nil
}

// resolveSpecsDir resolves area to an absolute specs directory and also returns
// the repo root used to display finding paths relative to it.
func resolveSpecsDir(area, base string) (dir, repoRoot string, err error) {
	repoRoot = resolveRepoRoot()

	// An explicit existing directory path wins (absolute or cwd-relative).
	if area != "" {
		if abs, e := filepath.Abs(area); e == nil {
			if fi, e := os.Stat(abs); e == nil && fi.IsDir() {
				return abs, repoRoot, nil
			}
		}
	}

	// Otherwise treat area as a name under <repo>/<base>; empty falls back to
	// the active project's name from .msh-memory.json.
	name := area
	if name == "" {
		if mc, _ := LoadMemoryConfig(""); mc != nil {
			name = mc.Project.Name
		}
	}
	if name == "" {
		return "", "", &exitError{code: exitUsage, err: fmt.Errorf("specs: area required (e.g. `msh specs echo_mq`)")}
	}
	if base == "" {
		base = "docs"
	}
	dir = filepath.Join(repoRoot, base, name)
	if fi, e := os.Stat(dir); e != nil || !fi.IsDir() {
		return "", "", &exitError{code: exitUsage, err: fmt.Errorf("specs: area %q not found (looked in %s)", name, dir)}
	}
	return dir, repoRoot, nil
}

// resolveRepoRoot finds the repo root: the directory holding .msh-memory.json,
// else the nearest ancestor with a .git, else the cwd.
func resolveRepoRoot() string {
	if mc, _ := LoadMemoryConfig(""); mc != nil && mc.Source != "" {
		return filepath.Dir(mc.Source)
	}
	wd, err := os.Getwd()
	if err != nil {
		return "."
	}
	for dir := wd; ; {
		if _, err := os.Stat(filepath.Join(dir, ".git")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return wd
		}
		dir = parent
	}
}
