// Package apollo ports the nine "Apollo A+" quality gates from
// docs/elixir/kb/build_page.py. Each gate inspects a finished HTML document and
// returns a pass/fail plus a one-line detail. A page ships only when all nine
// pass. The checks mirror the Python regexes and string logic exactly.
package apollo

import (
	"fmt"
	"html"
	"regexp"
	"sort"
	"strings"

	"github.com/jonny-novikov/jonnify-cms/internal/manifest"
)

var (
	tagRE       = regexp.MustCompile(`<(/?)([a-zA-Z][\w-]*)([^>]*?)(/?)>`)
	scriptRE    = regexp.MustCompile(`(?is)<script.*?</script>`)
	styleRE     = regexp.MustCompile(`(?is)<style.*?</style>`)
	svgRE       = regexp.MustCompile(`(?is)<svg.*?</svg>`)
	anyTagRE    = regexp.MustCompile(`(?s)<[^>]+>`)
	forbiddenRE = regexp.MustCompile(`(?i)\b(revolutionary|blazing[\s-]?fast|magical|simply|just|obviously|effortless)\b`)
	storageRE   = regexp.MustCompile(`\b(localStorage|sessionStorage)\b`)
	hrefRE      = regexp.MustCompile(`href="([^"]+)"`)
	svgOpenRE   = regexp.MustCompile(`(?i)<svg\b`)
	svgCloseRE  = regexp.MustCompile(`(?i)</svg>`)
)

var containerTags = map[string]bool{
	"div": true, "section": true, "main": true, "header": true, "footer": true,
	"nav": true, "article": true, "figure": true, "aside": true,
}

// Result is one gate's verdict.
type Result struct {
	Name   string `json:"name"`
	OK     bool   `json:"ok"`
	Detail string `json:"detail"`
}

// gate is a named check. allowed is the set of internal routes that count as
// resolvable; route-free gates ignore it.
type gate struct {
	name string
	fn   func(doc string, allowed map[string]bool) (bool, string)
}

// Gates is the ordered gate list (names match build_page.py).
var gates = []gate{
	{"containers", gateContainers},
	{"svg", gateSVG},
	{"no-future", gateNoFuture},
	{"voice", gateVoice},
	{"storage", gateStorage},
	{"motion", gateMotion},
	{"degrade", gateDegrade},
	{"links", gateLinks},
	{"pager", gatePager},
}

// Run executes every gate over the document against the elixir manifest routes
// and reports whether all passed.
func Run(doc string) ([]Result, bool) {
	return RunWith(doc, nil)
}

// RunWith is Run with extra resolvable routes unioned onto the elixir manifest —
// the filesystem-derived routes of a folder-routed section (see
// site.SectionRoutes), so a page that links to its real hub resolves the link
// and pager gates even though the manifest never declares that section.
func RunWith(doc string, extra map[string]bool) ([]Result, bool) {
	return RunWithOpts(doc, extra, Opts{})
}

// Opts toggles the optional, opt-in gates. The nine core gates always run; an
// optional gate runs only for a section that asks for it, so enabling one cannot
// retroactively fail an elixir page that never adopted the convention.
type Opts struct {
	RequireRefs bool // require a References section (the agile-agent-workflow mandate)
}

// RunWithOpts is RunWith plus the opt-in gates selected by opts.
func RunWithOpts(doc string, extra map[string]bool, opts Opts) ([]Result, bool) {
	allowed := manifest.AllowedRoutes() // a fresh map per call — safe to extend
	for r := range extra {
		allowed[r] = true
	}
	active := gates
	if opts.RequireRefs {
		active = append(append([]gate{}, gates...), gate{"refs", gateRefs})
	}
	out := make([]Result, 0, len(active))
	all := true
	for _, g := range active {
		ok, detail := g.fn(doc, allowed)
		out = append(out, Result{g.name, ok, detail})
		if !ok {
			all = false
		}
	}
	return out, all
}

func stripCode(s string) string {
	s = scriptRE.ReplaceAllString(s, "")
	s = styleRE.ReplaceAllString(s, "")
	return s
}

func visibleText(s string) string {
	s = stripCode(s)
	s = svgRE.ReplaceAllString(s, "")
	s = anyTagRE.ReplaceAllString(s, "")
	return html.UnescapeString(s)
}

func gateContainers(doc string, _ map[string]bool) (bool, string) {
	s := svgRE.ReplaceAllString(stripCode(doc), "")
	var stack []string
	for _, m := range tagRE.FindAllStringSubmatch(s, -1) {
		closing, name, selfClose := m[1], strings.ToLower(m[2]), m[4]
		if !containerTags[name] {
			continue
		}
		if selfClose == "/" {
			continue
		}
		if closing == "/" {
			top := "—"
			if len(stack) > 0 {
				top = stack[len(stack)-1]
			}
			if len(stack) == 0 || top != name {
				return false, fmt.Sprintf("unbalanced </%s> (open container was <%s>)", name, top)
			}
			stack = stack[:len(stack)-1]
		} else {
			stack = append(stack, name)
		}
	}
	if len(stack) > 0 {
		return false, fmt.Sprintf("unclosed <%s> — check for a missing </div> in a section", stack[len(stack)-1])
	}
	return true, "container tags balanced"
}

func gateSVG(doc string, _ map[string]bool) (bool, string) {
	o := len(svgOpenRE.FindAllString(doc, -1))
	c := len(svgCloseRE.FindAllString(doc, -1))
	if o == 0 {
		return false, "no <svg> present — every page carries a seen argument"
	}
	if o != c {
		return false, fmt.Sprintf("svg open/close mismatch (%d open, %d close)", o, c)
	}
	return true, fmt.Sprintf("%d svg block(s), well formed", o)
}

func gateNoFuture(doc string, _ map[string]bool) (bool, string) {
	if strings.Contains(doc, "/future") {
		return false, "found a link to /future"
	}
	return true, "no /future links"
}

func gateVoice(doc string, _ map[string]bool) (bool, string) {
	set := map[string]bool{}
	for _, m := range forbiddenRE.FindAllString(visibleText(doc), -1) {
		set[strings.ToLower(m)] = true
	}
	if len(set) > 0 {
		return false, "forbidden words: " + strings.Join(sortedKeys(set), ", ")
	}
	return true, "no hype / dismissive words"
}

func gateStorage(doc string, _ map[string]bool) (bool, string) {
	if m := storageRE.FindString(doc); m != "" {
		return false, "uses <" + m + ">"
	}
	return true, "no web storage APIs"
}

func gateMotion(doc string, _ map[string]bool) (bool, string) {
	if !strings.Contains(doc, "prefers-reduced-motion") {
		return false, "missing prefers-reduced-motion handling"
	}
	return true, "honours prefers-reduced-motion"
}

func gateDegrade(doc string, _ map[string]bool) (bool, string) {
	if !strings.Contains(doc, ".reveal") {
		return true, "no reveal animation"
	}
	if strings.Contains(doc, "html.js .reveal") || strings.Contains(doc, ".js .reveal") {
		return true, "reveal is JS-gated; content visible without JS"
	}
	return false, "reveal hides content without a JS gate"
}

func gateLinks(doc string, allowed map[string]bool) (bool, string) {
	set := map[string]bool{}
	for _, m := range hrefRE.FindAllStringSubmatch(doc, -1) {
		h := m[1]
		if hasAnyPrefix(h, "#", "http://", "https://", "mailto:", "tel:", "//") {
			continue
		}
		if allowed[h] {
			continue
		}
		set[h] = true
	}
	if len(set) > 0 {
		return false, "dangling internal links: " + strings.Join(sortedKeys(set), ", ")
	}
	return true, "all internal links resolve to live/built routes"
}

func gatePager(doc string, allowed map[string]bool) (bool, string) {
	if !strings.Contains(doc, `class="pager"`) {
		return false, "no .pager navigation block"
	}
	for _, m := range hrefRE.FindAllStringSubmatch(doc, -1) {
		if allowed[m[1]] {
			return true, "pager links to a real route"
		}
	}
	return false, "pager has no link to a live/built route"
}

// gateRefs requires the page to carry a References section — the .refs block
// that lists the page's sources and its in-course links. Opt-in (see Opts): the
// agile-agent-workflow course mandates a References section on every page. The
// literal class="refs" attribute is the structural signature; the CSS selector
// (.refs{…}) in <style> does not match it, so a styled-but-absent section fails.
func gateRefs(doc string, _ map[string]bool) (bool, string) {
	if !strings.Contains(doc, `class="refs"`) {
		return false, "no References section (missing a .refs block)"
	}
	return true, "References section present"
}

func hasAnyPrefix(s string, prefixes ...string) bool {
	for _, p := range prefixes {
		if strings.HasPrefix(s, p) {
			return true
		}
	}
	return false
}

func sortedKeys(m map[string]bool) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}
