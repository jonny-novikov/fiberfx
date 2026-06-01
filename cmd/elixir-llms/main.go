// Command elixir-llms generates a per-chapter llms.txt for every subfolder of
// elixir/, plus a course-root elixir/llms.txt index. Each file is the llmstxt.org
// convention scoped to one chapter: an H1 + blockquote summary (taken from the
// chapter hub's own <title>/<meta description>) followed by the chapter's full
// lesson tree as clean root-relative links, in pedagogical order (read from the
// hub link order). Lesson labels/descriptions come from each page's real
// <title> + <meta name="description"> — nothing is hand-written here, so re-running
// after adding/renaming lessons keeps the maps accurate.
//
// Served by main.go's serveDirTree (the "exact co-located file" branch) as
// text/plain at /elixir/<chapter>/llms.txt; shipped by the whole-dir COPY elixir/.
// Like cmd/sitemap this is a BUILD-TIME tool, NOT part of the server binary; run it
// via `make elixir-llms` after changing the course structure.
//
// Usage:
//
//	GOWORK=off go run ./cmd/elixir-llms -root .
package main

import (
	"flag"
	"fmt"
	"html"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// CHAPTERS is the fixed course order — also the order of the root index. A chapter
// dir absent on disk is skipped (so a not-yet-started chapter is simply omitted).
var chapters = []string{"course", "algebra", "functional", "language", "algorithms", "pragmatic", "phoenix"}

var (
	hrefRe   = regexp.MustCompile(`href="(/elixir/[^"#?]*)"`)
	titleRe  = regexp.MustCompile(`(?is)<title>(.*?)</title>`)
	descRe   = regexp.MustCompile(`(?is)<meta\s+name="description"\s+content="(.*?)"`)
	wsRe     = regexp.MustCompile(`\s+`)
	jonnixRe = regexp.MustCompile(`\s*[·—–\-]\s*jonnify\s*$`)
)

var root = "."

func main() {
	flag.StringVar(&root, "root", ".", "content root (dir holding elixir/)")
	flag.Parse()

	elixir := filepath.Join(root, "elixir")
	if fi, err := os.Stat(elixir); err != nil || !fi.IsDir() {
		fmt.Fprintf(os.Stderr, "no elixir/ under %q\n", root)
		os.Exit(1)
	}

	type summary struct{ title, desc string }
	summaries := map[string]summary{}
	var order []string

	for _, ch := range chapters {
		if fi, err := os.Stat(filepath.Join(elixir, ch)); err != nil || !fi.IsDir() {
			continue
		}
		ctitle, cdesc, n := buildChapter(ch)
		summaries[ch] = summary{ctitle, cdesc}
		order = append(order, ch)
		fmt.Printf("  %-42s %3d lessons  (%s)\n", filepath.Join("elixir", ch, "llms.txt"), n, ctitle)
	}

	// Course-root index.
	idxTitle, idxDesc := meta(filepath.Join(elixir, "index.html"))
	var b strings.Builder
	fmt.Fprintf(&b, "# %s — course map (/elixir)\n\n", idxTitle)
	if idxDesc != "" {
		fmt.Fprintf(&b, "> %s\n\n", idxDesc)
	}
	b.WriteString("Per-chapter maps for LLMs/agents. Each chapter has its own llms.txt listing " +
		"every lesson; this index links the chapters in course order.\n\n## Chapters\n\n")
	for _, ch := range order {
		s := summaries[ch]
		line := fmt.Sprintf("- [%s](/elixir/%s) — map: [/elixir/%s/llms.txt](/elixir/%s/llms.txt)", s.title, ch, ch, ch)
		if s.desc != "" {
			line += ": " + shorten(s.desc, 150)
		}
		b.WriteString(line + "\n")
	}
	writeFile(filepath.Join(elixir, "llms.txt"), b.String())
	fmt.Printf("  %-42s  (course-root index)\n", filepath.Join("elixir", "llms.txt"))
}

// buildChapter writes elixir/<chapter>/llms.txt and returns (title, desc, lessonCount).
func buildChapter(chapter string) (string, string, int) {
	elixir := filepath.Join(root, "elixir")
	cidx := filepath.Join(elixir, chapter, "index.html")
	ctitle, cdesc := meta(cidx)
	chub := read(cidx)

	remaining := allHTMLURLs(chapter)     // every clean URL under the chapter
	delete(remaining, "/elixir/"+chapter) // minus the hub itself

	var b strings.Builder
	fmt.Fprintf(&b, "# %s\n\n", ctitle)
	if cdesc != "" {
		fmt.Fprintf(&b, "> %s\n\n", cdesc)
	}
	fmt.Fprintf(&b, "Chapter map for LLMs/agents. Hub: [/elixir/%s](/elixir/%s). "+
		"Links are clean root-relative URLs; this file lists every lesson in the chapter in course order.\n\n## Lessons\n\n",
		chapter, chapter)

	lessons := 0
	emit := func(indent, title, url, desc string) {
		lessons++
		if desc != "" {
			fmt.Fprintf(&b, "%s- [%s](%s): %s\n", indent, title, url, shorten(desc, 170))
		} else {
			fmt.Fprintf(&b, "%s- [%s](%s)\n", indent, title, url)
		}
	}

	// Top-level chapter items in hub order, then any chapter-level URL the hub
	// didn't link (so nothing is dropped).
	top := hubOrder(chub, chapter, 2)
	for _, u := range sortedKeys(remaining) {
		if len(strings.Split(strings.Trim(u, "/"), "/")) == 3 && !contains(top, u) {
			top = append(top, u)
		}
	}

	for _, item := range top {
		f := urlToFile(item)
		isDir := dirExists(filepath.Join(elixir, strings.TrimPrefix(item, "/elixir/")))
		if f == "" || (!remaining[item] && !isDir) {
			continue
		}
		title, desc := meta(f)
		delete(remaining, item)
		if isDir {
			emit("", title, item, desc)
			// Section children, in section-hub order, then leftovers under it.
			child := hubOrder(read(f), chapter, 3)
			var kids []string
			for _, c := range child {
				if strings.HasPrefix(c, item+"/") {
					kids = append(kids, c)
				}
			}
			for _, u := range sortedKeys(remaining) {
				if strings.HasPrefix(u, item+"/") && !contains(kids, u) {
					kids = append(kids, u)
				}
			}
			for _, ch := range kids {
				cf := urlToFile(ch)
				if cf == "" {
					continue
				}
				delete(remaining, ch)
				ct, cd := meta(cf)
				emit("  ", ct, ch, cd)
			}
		} else {
			emit("", title, item, desc)
		}
	}

	// Any deeply-nested orphan still unconsumed — append flat so nothing is lost.
	for _, u := range sortedKeys(remaining) {
		f := urlToFile(u)
		if f == "" {
			continue
		}
		t, d := meta(f)
		emit("", t, u, d)
	}

	writeFile(filepath.Join(elixir, chapter, "llms.txt"), b.String())
	return ctitle, cdesc, lessons
}

// meta returns a page's cleaned (title, description) from its head.
func meta(path string) (string, string) {
	src := read(path)
	title := filepath.Base(path)
	if m := titleRe.FindStringSubmatch(src); m != nil {
		title = html.UnescapeString(strings.TrimSpace(m[1]))
	}
	desc := ""
	if m := descRe.FindStringSubmatch(src); m != nil {
		desc = html.UnescapeString(strings.TrimSpace(m[1]))
	}
	// Strip the site/course suffixes (the separator before "jonnify" varies: · or —).
	title = jonnixRe.ReplaceAllString(title, "")
	title = strings.ReplaceAll(title, " · Functional Programming in Elixir", "")
	title = strings.ReplaceAll(title, " — a jonnify course", "")
	return collapse(title), collapse(desc)
}

// shorten truncates desc to limit runes at a word boundary with an ellipsis.
func shorten(desc string, limit int) string {
	r := []rune(desc)
	if len(r) <= limit {
		return desc
	}
	cut := string(r[:limit])
	if i := strings.LastIndex(cut, " "); i >= 0 {
		cut = cut[:i]
	}
	cut = strings.TrimRight(cut, ",;:—- ")
	return cut + "…"
}

// urlToFile maps a clean /elixir/... URL to its backing .html file (dir→index.html),
// or "" if absent.
func urlToFile(url string) string {
	rel := strings.Trim(strings.TrimPrefix(url, "/elixir/"), "/")
	d := filepath.Join(root, "elixir", rel)
	if dirExists(d) {
		idx := filepath.Join(d, "index.html")
		if fileExists(idx) {
			return idx
		}
		return ""
	}
	f := filepath.Join(root, "elixir", rel+".html")
	if fileExists(f) {
		return f
	}
	return ""
}

// hubOrder returns ordered, de-duped first-segment items under a hub at the given
// depth below /elixir (depth 2 → chapter children; depth 3 → section children),
// keeping only this chapter's links and skipping shallower breadcrumb links.
func hubOrder(hubHTML, chapter string, depth int) []string {
	var out []string
	seen := map[string]bool{}
	for _, m := range hrefRe.FindAllStringSubmatch(hubHTML, -1) {
		parts := strings.Split(strings.Trim(m[1], "/"), "/") // ["elixir","functional","recursion",...]
		if len(parts) <= depth || parts[1] != chapter {
			continue
		}
		item := "/" + strings.Join(parts[:depth+1], "/")
		if !seen[item] {
			seen[item] = true
			out = append(out, item)
		}
	}
	return out
}

// allHTMLURLs returns the set of every clean URL under a chapter (index.html →
// directory URL), so a lesson the hub forgot to link is still listed.
func allHTMLURLs(chapter string) map[string]bool {
	base := filepath.Join(root, "elixir", chapter)
	urls := map[string]bool{}
	_ = filepath.WalkDir(base, func(p string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(d.Name(), ".html") {
			return nil
		}
		rel, e := filepath.Rel(filepath.Join(root, "elixir"), p)
		if e != nil {
			return nil
		}
		rel = filepath.ToSlash(rel)
		if d.Name() == "index.html" {
			rel = strings.TrimSuffix(rel, "/index.html")
		} else {
			rel = strings.TrimSuffix(rel, ".html")
		}
		urls["/elixir/"+rel] = true
		return nil
	})
	return urls
}

func read(path string) string {
	b, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	return string(b)
}

func writeFile(path, body string) {
	body = strings.TrimRight(body, "\n") + "\n"
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		fmt.Fprintln(os.Stderr, "write:", err)
		os.Exit(1)
	}
}

func collapse(s string) string { return strings.TrimSpace(wsRe.ReplaceAllString(s, " ")) }
func fileExists(p string) bool { fi, err := os.Stat(p); return err == nil && !fi.IsDir() }
func dirExists(p string) bool  { fi, err := os.Stat(p); return err == nil && fi.IsDir() }

func sortedKeys(m map[string]bool) []string {
	ks := make([]string, 0, len(m))
	for k := range m {
		ks = append(ks, k)
	}
	sort.Strings(ks)
	return ks
}

func contains(s []string, v string) bool {
	for _, x := range s {
		if x == v {
			return true
		}
	}
	return false
}
