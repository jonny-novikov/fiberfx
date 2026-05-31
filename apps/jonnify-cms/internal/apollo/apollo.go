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

// gate is a named check.
type gate struct {
	name string
	fn   func(doc string) (bool, string)
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

// Run executes every gate over the document and reports whether all passed.
func Run(doc string) ([]Result, bool) {
	out := make([]Result, 0, len(gates))
	all := true
	for _, g := range gates {
		ok, detail := g.fn(doc)
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

func gateContainers(doc string) (bool, string) {
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

func gateSVG(doc string) (bool, string) {
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

func gateNoFuture(doc string) (bool, string) {
	if strings.Contains(doc, "/future") {
		return false, "found a link to /future"
	}
	return true, "no /future links"
}

func gateVoice(doc string) (bool, string) {
	set := map[string]bool{}
	for _, m := range forbiddenRE.FindAllString(visibleText(doc), -1) {
		set[strings.ToLower(m)] = true
	}
	if len(set) > 0 {
		return false, "forbidden words: " + strings.Join(sortedKeys(set), ", ")
	}
	return true, "no hype / dismissive words"
}

func gateStorage(doc string) (bool, string) {
	if m := storageRE.FindString(doc); m != "" {
		return false, "uses <" + m + ">"
	}
	return true, "no web storage APIs"
}

func gateMotion(doc string) (bool, string) {
	if !strings.Contains(doc, "prefers-reduced-motion") {
		return false, "missing prefers-reduced-motion handling"
	}
	return true, "honours prefers-reduced-motion"
}

func gateDegrade(doc string) (bool, string) {
	if !strings.Contains(doc, ".reveal") {
		return true, "no reveal animation"
	}
	if strings.Contains(doc, "html.js .reveal") || strings.Contains(doc, ".js .reveal") {
		return true, "reveal is JS-gated; content visible without JS"
	}
	return false, "reveal hides content without a JS gate"
}

func gateLinks(doc string) (bool, string) {
	allowed := manifest.AllowedRoutes()
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

func gatePager(doc string) (bool, string) {
	if !strings.Contains(doc, `class="pager"`) {
		return false, "no .pager navigation block"
	}
	allowed := manifest.AllowedRoutes()
	for _, m := range hrefRE.FindAllStringSubmatch(doc, -1) {
		if allowed[m[1]] {
			return true, "pager links to a real route"
		}
	}
	return false, "pager has no link to a live/built route"
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
