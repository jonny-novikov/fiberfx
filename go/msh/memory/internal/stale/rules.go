package stale

import (
	"sort"
	"strings"
	"time"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
)

type Source interface {
	Body(path string) ([]byte, error)
	HeadingSlugs(path string) ([]string, error)
	Exists(repoRelPath string) bool
}

type Rule struct {
	Name  string
	Apply func(g *graph.Graph, cfg *config.Config, src Source) Findings
}

const (
	RuleDeadTarget     = "DEAD-TARGET"
	RuleDeletedPath    = "DELETED-PATH"
	RuleRemovedTool    = "REMOVED-TOOL"
	RuleBrokenAnchor   = "BROKEN-ANCHOR"
	RuleOrphan         = "ORPHAN"
	RuleSupersedeCycle = "SUPERSEDE-CYCLE"
	RuleStaleExternal  = "STALE-EXTERNAL"
	RuleReviewDue      = "REVIEW-DUE"
)

// AllRules returns the rule registry. ref is the injected REVIEW-DUE reference
// date (msh2.2 §3.5, design §4.3): no rule reads the wall clock — the seven
// link/path rules ignore ref, and the review-due entry closes over it.
func AllRules(ref time.Time) []Rule {
	return []Rule{
		{Name: RuleDeadTarget, Apply: ruleDeadTarget},
		{Name: RuleDeletedPath, Apply: ruleDeletedPath},
		{Name: RuleRemovedTool, Apply: ruleRemovedTool},
		{Name: RuleBrokenAnchor, Apply: ruleBrokenAnchor},
		{Name: RuleOrphan, Apply: ruleOrphan},
		{Name: RuleSupersedeCycle, Apply: ruleSupersedeCycle},
		{Name: RuleStaleExternal, Apply: ruleStaleExternal},
		{Name: RuleReviewDue, Apply: func(g *graph.Graph, cfg *config.Config, src Source) Findings {
			return ruleReviewDue(g, cfg, src, ref)
		}},
	}
}

// Run applies the selected rules over the full graph. ref is the REVIEW-DUE
// reference date — production callers pass the current UTC day, computed once
// per invocation; tests and goldens inject a fixed date (same corpus + same
// query + same ref → byte-identical findings, msh2.2 §3.5).
func Run(g *graph.Graph, cfg *config.Config, src Source, names []string, ref time.Time) Findings {
	rules := AllRules(ref)
	var selected []Rule
	if len(names) == 0 || (len(names) == 1 && strings.EqualFold(names[0], "all")) {
		selected = rules
	} else {
		want := make(map[string]bool, len(names))
		for _, n := range names {
			want[strings.ToUpper(strings.TrimSpace(n))] = true
		}
		for _, r := range rules {
			if want[r.Name] {
				selected = append(selected, r)
			}
		}
	}
	var all Findings
	for _, r := range selected {
		all = append(all, r.Apply(g, cfg, src)...)
	}
	sortFindings(all)
	return all
}

func sortFindings(f Findings) {
	sort.SliceStable(f, func(i, j int) bool {
		if f[i].File != f[j].File {
			return f[i].File < f[j].File
		}
		if f[i].Line != f[j].Line {
			return f[i].Line < f[j].Line
		}
		if f[i].Rule != f[j].Rule {
			return f[i].Rule < f[j].Rule
		}
		return f[i].Target < f[j].Target
	})
}
