// Command sitemap generates sitemap.xml (and robots.txt) for the jonnify static
// site by walking the served content directories and reproducing the clean-URL
// scheme that main.go implements:
//
//   - singletons:      index.html -> "/",  game.html -> "/game"
//   - flat sections:   <section>/<name>.html -> "/<section>/<name>"; the bare
//     "/<section>" URL stands for that section's DEFAULT page (ege/edu/school/
//     future/map use index, EXCEPT edu whose default is "finances"), so the
//     default's named URL is omitted to avoid duplicate-content entries.
//   - elixir (folder-routed): a directory holding index.html -> the directory
//     URL ("/elixir", "/elixir/algebra", …); any other <name>.html -> the clean
//     leaf URL ("/elixir/course", "/elixir/algebra/f1-01-functions").
//
// It is a BUILD-TIME tool: it is not part of the server binary (the Dockerfile
// compiles only the root package) and is run via `make sitemap`. Output is
// deterministic (URLs sorted), so re-running produces a minimal diff.
//
// Usage:
//
//	GOWORK=off go run ./cmd/sitemap -base https://jonnify.fly.dev -root . \
//	    -out sitemap.xml -robots robots.txt
package main

import (
	"encoding/xml"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// urlEntry is one <url> element. omitempty keeps optional tags out when unset.
type urlEntry struct {
	Loc        string `xml:"loc"`
	LastMod    string `xml:"lastmod,omitempty"`
	ChangeFreq string `xml:"changefreq,omitempty"`
	Priority   string `xml:"priority,omitempty"`
}

type urlSet struct {
	XMLName xml.Name   `xml:"urlset"`
	Xmlns   string     `xml:"xmlns,attr"`
	URLs    []urlEntry `xml:"url"`
}

func main() {
	base := flag.String("base", "https://jonnify.fly.dev", "site base URL (no trailing slash)")
	root := flag.String("root", ".", "content root (dir holding index.html, edu/, school/, …)")
	out := flag.String("out", "sitemap.xml", "output sitemap path")
	robots := flag.String("robots", "robots.txt", "output robots.txt path (empty string to skip)")
	flag.Parse()

	b := strings.TrimRight(*base, "/")

	var entries []urlEntry
	seen := map[string]bool{}
	// add records one URL. path is the backing file (for <lastmod> from mtime);
	// loc is the absolute clean path. Duplicate locs are ignored.
	add := func(path, loc, changefreq, priority string) {
		if seen[loc] {
			return
		}
		seen[loc] = true
		lastmod := ""
		if fi, err := os.Stat(path); err == nil {
			lastmod = fi.ModTime().UTC().Format("2006-01-02")
		}
		entries = append(entries, urlEntry{
			Loc:        b + loc,
			LastMod:    lastmod,
			ChangeFreq: changefreq,
			Priority:   priority,
		})
	}

	// Singletons.
	add(filepath.Join(*root, "index.html"), "/", "weekly", "1.0")
	add(filepath.Join(*root, "game.html"), "/game", "yearly", "0.3")

	// Flat sections: bare "/<section>" = default page; "/<section>/<name>" for
	// every other top-level *.html (the :name route only serves one level deep).
	flat := []struct{ dir, def string }{
		{"ege", "index"},
		{"edu", "finances"},
		{"school", "index"},
		{"future", "index"},
		{"map", "index"},
	}
	for _, s := range flat {
		dirPath := filepath.Join(*root, s.dir)
		ents, err := os.ReadDir(dirPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "warn: skip section %q: %v\n", s.dir, err)
			continue
		}
		if defPath := filepath.Join(dirPath, s.def+".html"); fileExists(defPath) {
			add(defPath, "/"+s.dir, "weekly", "0.8")
		}
		for _, e := range ents {
			if e.IsDir() || !strings.HasSuffix(e.Name(), ".html") {
				continue
			}
			name := strings.TrimSuffix(e.Name(), ".html")
			if name == s.def {
				continue // already covered by the bare "/<section>" URL
			}
			add(filepath.Join(dirPath, e.Name()), "/"+s.dir+"/"+name, "monthly", "0.6")
		}
	}

	// Folder-routed sections (elixir, health, logic, law, physics, ai-rabota): recurse
	// — the on-disk tree mirrors the URL tree. A dir with index.html -> the directory
	// URL; any other <name>.html -> the clean leaf URL.
	for _, sec := range []string{"elixir", "health", "logic", "law", "physics", "ai-rabota"} {
		secRoot := filepath.Join(*root, sec)
		_ = filepath.WalkDir(secRoot, func(p string, d os.DirEntry, err error) error {
			if err != nil || d.IsDir() || !strings.HasSuffix(d.Name(), ".html") {
				return nil
			}
			rel, relErr := filepath.Rel(secRoot, p)
			if relErr != nil {
				return nil
			}
			rel = filepath.ToSlash(rel)
			if d.Name() == "index.html" {
				sub := strings.Trim(strings.TrimSuffix(rel, "index.html"), "/")
				loc, prio := "/"+sec, "0.8"
				if sub != "" {
					loc, prio = "/"+sec+"/"+sub, "0.7"
				}
				add(p, loc, "monthly", prio)
			} else {
				add(p, "/"+sec+"/"+strings.TrimSuffix(rel, ".html"), "monthly", "0.6")
			}
			return nil
		})
	}

	sort.Slice(entries, func(i, j int) bool { return entries[i].Loc < entries[j].Loc })

	body, err := xml.MarshalIndent(urlSet{
		Xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9",
		URLs:  entries,
	}, "", "  ")
	if err != nil {
		fmt.Fprintln(os.Stderr, "marshal:", err)
		os.Exit(1)
	}
	if err := os.WriteFile(*out, []byte(xml.Header+string(body)+"\n"), 0o644); err != nil {
		fmt.Fprintln(os.Stderr, "write sitemap:", err)
		os.Exit(1)
	}
	fmt.Printf("wrote %s (%d urls)\n", *out, len(entries))

	if *robots != "" {
		txt := "# https://www.robotstxt.org/\nUser-agent: *\nAllow: /\n\nSitemap: " + b + "/sitemap.xml\n"
		if err := os.WriteFile(*robots, []byte(txt), 0o644); err != nil {
			fmt.Fprintln(os.Stderr, "write robots:", err)
			os.Exit(1)
		}
		fmt.Printf("wrote %s\n", *robots)
	}
}

func fileExists(p string) bool {
	fi, err := os.Stat(p)
	return err == nil && !fi.IsDir()
}
