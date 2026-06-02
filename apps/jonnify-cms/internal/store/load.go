package store

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"html"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/jonny-novikov/jonnify-cms/internal/tmpl"
)

// Skipped records a file that did not conform to the decomposition, with the
// reason it was left out of the store.
type Skipped struct {
	Path   string
	Reason string
}

// LoadReport summarizes a LoadFromTree run: how many pages were inserted, how
// many distinct head templates they dedup into, and which files were skipped.
type LoadReport struct {
	Pages         int
	DistinctHeads int
	Skips         []Skipped
}

var (
	reTitle = regexp.MustCompile(`(?s)<title>(.*?)</title>`)
	reDesc  = regexp.MustCompile(`(?s)<meta name="description" content="(.*?)">`)
	reBID   = regexp.MustCompile(`id="stampId">([^<]*)<`)
	reBTS   = regexp.MustCompile(`id="st-ts">([^<]*)<`)
)

// LoadFromTree walks elixirRoot for *.html files, decomposes each conforming
// page, and inserts a row per page (deduplicating head templates by sha256).
// Non-conforming files are skipped and reported, not inserted. Pages are
// processed in sorted path order for deterministic head ids.
func (s *Store) LoadFromTree(elixirRoot string) (LoadReport, error) {
	var rep LoadReport

	var files []string
	err := filepath.WalkDir(elixirRoot, func(p string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if strings.EqualFold(filepath.Ext(p), ".html") {
			files = append(files, p)
		}
		return nil
	})
	if err != nil {
		return rep, err
	}
	sort.Strings(files)

	tx, err := s.db.Begin()
	if err != nil {
		return rep, err
	}
	defer tx.Rollback()

	headIDs := map[string]int64{} // sha256 hex -> head row id
	for _, p := range files {
		raw, err := os.ReadFile(p)
		if err != nil {
			return rep, err
		}
		page, headTpl, reason := decompose(string(raw), elixirRoot, p)
		if reason != "" {
			rep.Skips = append(rep.Skips, Skipped{Path: p, Reason: reason})
			continue
		}

		sum := sha256.Sum256([]byte(headTpl))
		key := hex.EncodeToString(sum[:])
		hid, ok := headIDs[key]
		if !ok {
			res, err := tx.Exec(`INSERT INTO head (sha256, bytes) VALUES (?, ?)`, key, []byte(headTpl))
			if err != nil {
				return rep, fmt.Errorf("insert head for %s: %w", p, err)
			}
			hid, err = res.LastInsertId()
			if err != nil {
				return rep, err
			}
			headIDs[key] = hid
		}

		if _, err := tx.Exec(
			`INSERT INTO page (route, output_path, title, descr, head_id, fragment, build_id, build_ts, byte_len)
			 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
			page.Route, page.OutputPath, page.Title, page.Descr, hid,
			page.Fragment, page.BuildID, page.BuildTS, page.ByteLen,
		); err != nil {
			return rep, fmt.Errorf("insert page %s: %w", page.Route, err)
		}
		rep.Pages++
	}

	if err := tx.Commit(); err != nil {
		return rep, err
	}
	rep.DistinctHeads = len(headIDs)
	return rep, nil
}

// decompose splits one published page into its head template, body-fragment
// template, and per-page data, following the exact lossless algorithm in
// docs/specs/07-content-store.md. A non-empty reason means the file did not
// conform and must be skipped; page and headTpl are then unset.
func decompose(p, elixirRoot, path string) (page Page, headTpl string, reason string) {
	if !strings.HasPrefix(p, tmpl.DOCTYPE) {
		return Page{}, "", "does not start with the standard doctype/html preamble"
	}
	i := strings.Index(p, tmpl.BodySep)
	if i < 0 {
		return Page{}, "", `missing the "\n<body>\n" head/body separator`
	}
	headFilled := p[len(tmpl.DOCTYPE):i]
	after := p[i+len(tmpl.BodySep):]
	if !strings.HasSuffix(after, tmpl.Suffix) {
		return Page{}, "", "does not end with the standard bootstrap/body/html tail"
	}
	fragmentFilled := after[:len(after)-len(tmpl.Suffix)]

	// Head template + title/description data.
	mt := reTitle.FindStringSubmatchIndex(headFilled)
	if mt == nil {
		return Page{}, "", "no <title> in head"
	}
	md := reDesc.FindStringSubmatchIndex(headFilled)
	if md == nil {
		return Page{}, "", `no <meta name="description"> in head`
	}
	titleEsc := headFilled[mt[2]:mt[3]]
	descEsc := headFilled[md[2]:md[3]]
	// Re-placehold by splicing the captured value spans (highest offset first so
	// the lower span's indices stay valid).
	headTpl = spliceSpans(headFilled,
		span{mt[2], mt[3], tmpl.PhTitle},
		span{md[2], md[3], tmpl.PhDesc},
	)
	title := html.UnescapeString(titleEsc)
	descr := html.UnescapeString(descEsc)

	// Round-trip requirement: the page's escaping must match the esc this tool
	// reproduces, else the recomposed bytes would diverge.
	if got := tmpl.Esc(title); got != titleEsc {
		return Page{}, "", fmt.Sprintf("title escaping differs from esc: stored %q, esc(title)=%q", titleEsc, got)
	}
	if got := tmpl.Esc(descr); got != descEsc {
		return Page{}, "", fmt.Sprintf("description escaping differs from esc: stored %q, esc(descr)=%q", descEsc, got)
	}

	// Fragment template + build stamp. The stamp is optional; absent, the
	// template equals the fragment and the ids stay empty.
	var buildID, buildTS string
	var spans []span
	if m := reBID.FindStringSubmatchIndex(fragmentFilled); m != nil {
		buildID = fragmentFilled[m[2]:m[3]]
		spans = append(spans, span{m[2], m[3], tmpl.PhBuildID})
	}
	if m := reBTS.FindStringSubmatchIndex(fragmentFilled); m != nil {
		buildTS = fragmentFilled[m[2]:m[3]]
		spans = append(spans, span{m[2], m[3], tmpl.PhBuildTS})
	}
	fragmentTpl := spliceSpans(fragmentFilled, spans...)

	route, out, rerr := routeAndOut(elixirRoot, path)
	if rerr != "" {
		return Page{}, "", rerr
	}

	return Page{
		Route:      route,
		OutputPath: out,
		Title:      title,
		Descr:      descr,
		Fragment:   []byte(fragmentTpl),
		BuildID:    buildID,
		BuildTS:    buildTS,
		ByteLen:    int64(len(p)),
	}, headTpl, ""
}

// span marks a [start,end) byte range in a source string and the text to put in
// its place.
type span struct {
	start, end int
	with       string
}

// spliceSpans replaces each span's byte range in s with its replacement text.
// Spans are applied from the highest start offset down so that each splice does
// not shift the offsets of spans not yet applied. Spans must not overlap.
func spliceSpans(s string, spans ...span) string {
	if len(spans) == 0 {
		return s
	}
	ss := append([]span(nil), spans...)
	sort.Slice(ss, func(a, b int) bool { return ss[a].start > ss[b].start })
	out := s
	for _, sp := range ss {
		out = out[:sp.start] + sp.with + out[sp.end:]
	}
	return out
}

// routeAndOut derives a page's clean /elixir route and its output path (relative
// to elixirRoot) from its file path, inverting internal/site's resolution: a
// .../index.html is a directory route, the root index.html is /elixir, and any
// other .../x.html is the leaf route /elixir/.../x.
func routeAndOut(elixirRoot, path string) (route, out, reason string) {
	rel, err := filepath.Rel(elixirRoot, path)
	if err != nil {
		return "", "", "path is not under the elixir root"
	}
	rel = filepath.ToSlash(rel)
	out = rel

	const idx = "index.html"
	switch {
	case rel == idx:
		return "/elixir", out, ""
	case strings.HasSuffix(rel, "/"+idx):
		dir := strings.TrimSuffix(rel, "/"+idx)
		return "/elixir/" + dir, out, ""
	case strings.HasSuffix(rel, ".html"):
		leaf := strings.TrimSuffix(rel, ".html")
		return "/elixir/" + leaf, out, ""
	default:
		return "", "", "not an .html file"
	}
}
