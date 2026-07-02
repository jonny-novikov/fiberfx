package command

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

// mshMemoryFile is the per-project anchor: it pins the corpus root and carries
// the active-program development context.
const mshMemoryFile = ".msh-memory.json"

// ProjectState is the active program's status in .msh-memory.json.
type ProjectState struct {
	Status      string `json:"status,omitempty"`
	CurrentRung string `json:"current_rung,omitempty"`
}

// Project is the development context carried in .msh-memory.json — it orients a
// tool (or an agent) to what is being built.
type Project struct {
	Name    string       `json:"name,omitempty"`
	Code    string       `json:"code,omitempty"`
	Roadmap string       `json:"roadmap,omitempty"`
	State   ProjectState `json:"state,omitempty"`
}

// MemoryConfig is the parsed .msh-memory.json: the corpus root, the optional
// docs tree (schema v1.1), plus the active project context. Source is the path
// it was loaded from (excluded from JSON).
type MemoryConfig struct {
	Root     string  `json:"root,omitempty"`
	DocsRoot string  `json:"docs_root,omitempty"`
	Project  Project `json:"project,omitempty"`

	Source string `json:"-"`
}

// LoadMemoryConfig walks up from startDir (cwd when "") looking for
// .msh-memory.json and parses it. Returns (nil, nil) when none is found. A
// relative `root` or `docs_root` is resolved against the file's own directory.
func LoadMemoryConfig(startDir string) (*MemoryConfig, error) {
	dir := startDir
	if dir == "" {
		wd, err := os.Getwd()
		if err != nil {
			return nil, fmt.Errorf("resolve cwd: %w", err)
		}
		dir = wd
	}
	for {
		path := filepath.Join(dir, mshMemoryFile)
		if data, err := os.ReadFile(path); err == nil {
			var mc MemoryConfig
			if err := json.Unmarshal(data, &mc); err != nil {
				return nil, fmt.Errorf("%s: %w", path, err)
			}
			mc.Source = path
			if mc.Root != "" && !filepath.IsAbs(mc.Root) {
				mc.Root = filepath.Join(dir, mc.Root)
			}
			if mc.DocsRoot != "" && !filepath.IsAbs(mc.DocsRoot) {
				mc.DocsRoot = filepath.Join(dir, mc.DocsRoot)
			}
			return &mc, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return nil, nil
		}
		dir = parent
	}
}

// Project renders the active project context (from .msh-memory.json) — the
// programmatic facade behind both `msh memory project` and the
// mcp__msh__memory_project tool. format: "text" (default) | "json".
func ProjectInfo(format string) (string, error) {
	mc, err := LoadMemoryConfig("")
	if err != nil {
		return "", err
	}
	return renderProject(mc, format)
}

func renderProject(mc *MemoryConfig, format string) (string, error) {
	switch strings.ToLower(strings.TrimSpace(format)) {
	case "", "text", "pretty":
		if mc == nil {
			return "no .msh-memory.json found (walk-up from cwd)\n", nil
		}
		var b strings.Builder
		fmt.Fprintf(&b, "project: %s (%s)\n", orDash(mc.Project.Name), orDash(mc.Project.Code))
		fmt.Fprintf(&b, "status:  %s\n", orDash(mc.Project.State.Status))
		fmt.Fprintf(&b, "rung:    %s\n", orDash(mc.Project.State.CurrentRung))
		fmt.Fprintf(&b, "roadmap: %s\n", orDash(mc.Project.Roadmap))
		fmt.Fprintf(&b, "root:    %s\n", orDash(mc.Root))
		fmt.Fprintf(&b, "docs:    %s\n", orDash(mc.DocsRoot))
		fmt.Fprintf(&b, "config:  %s\n", orDash(mc.Source))
		return b.String(), nil
	case "json":
		if mc == nil {
			return "null\n", nil
		}
		out, err := json.MarshalIndent(mc, "", "  ")
		if err != nil {
			return "", err
		}
		return string(out) + "\n", nil
	default:
		return "", fmt.Errorf("project: invalid format %q (want text|json)", format)
	}
}

func orDash(s string) string {
	if s == "" {
		return "-"
	}
	return s
}

func newProjectCmd(cfg *rootConfig) *cobra.Command {
	var format string
	cmd := &cobra.Command{
		Use:          "project",
		Short:        "Show the active project context from .msh-memory.json (name/code/roadmap/rung/root/docs_root).",
		Long:         "Reads the nearest .msh-memory.json (walk-up from cwd) and prints the active program's name, code, roadmap, status, current rung, the resolved corpus root, and the optional docs_root (anchor v1.1).",
		Args:         cobra.NoArgs,
		SilenceUsage: true,
		RunE: func(_ *cobra.Command, _ []string) error {
			out, err := ProjectInfo(format)
			if err != nil {
				return &exitError{code: exitGeneric, err: err}
			}
			_, err = fmt.Fprint(cfg.Stdout, out)
			return err
		},
	}
	cmd.Flags().StringVar(&format, "format", "text", "Output format: text | json")
	return cmd
}
