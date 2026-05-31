# 03 — Link audit and repoint

This document specifies `internal/audit` and the `cms audit [--root DIR] [--fix]` command.
The audit walks the built `/elixir` tree, extracts every internal link, and separates **true
broken links** from **deliberate placeholders**. `--fix` repairs the one class of true
breakage that exists today — orphan files whose name does not match the clean route that
references them — by renaming each file to its canonical clean-URL filename.

The audit reconciles the **filesystem** against the **manifest's allowed-routes set**
(`docs/specs/00-overview.md` §2, `docs/specs/01-manifest.md` §4). It is read-only without
`--fix`.

## 1. Inputs and link extraction

- **Root.** `--root DIR` (default `./elixir`) is the directory served at `/elixir`. The
  audit walks it recursively for `*.html` files, in sorted path order for determinism.
- **Allowed routes.** `manifest.AllowedRoutes()` — the linkable routes
  (`docs/specs/01-manifest.md` §4). A live/built route resolves to a real backing file; a
  `planned`/`soon` route does not, by construction.

For each HTML file, extract every `href="..."` value (the same scan the `links` Apollo gate
uses: `href="([^"]+)"`). For each href, classify it:

- **External / in-page** — starts with `#`, `http://`, `https://`, `mailto:`, `tel:`, or
  `//`. Ignored.
- **Internal** — everything else. An internal href is expected to be an absolute clean route
  beginning `/elixir`. Internal hrefs are the audit's subject.

The audit records, per internal href: the target route, the referencing file, and the byte
offset (for `--fix` reporting). Counts are tallied as **occurrences** (every `href` match)
and as **referencing files** (distinct files containing the href); both are reported, because
a route can be referenced several times within one page.

## 2. The broken-vs-placeholder distinction

This distinction is the core of the audit. A non-linkable target is **not** automatically a
broken link.

- **Deliberate placeholder** — a `planned`/`soon` module/subpage. The contents directory and
  the page bodies render these as **non-linking cards** (`<div class="mod is-quiet">`),
  definition-list terms (`<dt>`), or plain prose — never as an `<a href>`. A placeholder is
  the intended state for unbuilt content and is **not an error**. Confirmed properties of the
  current tree: there are **zero** `href="#"` placeholders and **zero** Cyrillic "скоро"
  strings; absence of a backing page is expressed by *not emitting a link*, not by a dead
  href. The audit therefore never flags a `planned`/`soon` route merely because it lacks a
  file — only a real `href` to a route with no backing file counts.

- **True broken link** — an `href="/elixir/..."` (an actual anchor) whose target route has
  **no backing file** under the root. The reader can click it and land on a 404. These are
  the audit's findings.

Classification algorithm for each internal href `H` found inside file `F`:

1. If `H` resolves to an existing file via the §3 resolver → **OK** (live link).
2. Else if `H` is in `manifest.AllowedRoutes()` but resolves to no file → **dangling
   manifest route** (the manifest promises a linkable route the build has not produced yet;
   reported as a true broken link, kind `missing-build`).
3. Else (`H` resolves to no file and is not an allowed route) → **true broken link**, kind
   `orphan-slug` when a sibling file backs the *intended* page under a different name (§4),
   otherwise kind `unknown`.

> The audit classifies by what is *linked*, not by what is *declared*. A `planned` route that
> nothing links to never appears in the audit at all; a route that a page actually links to
> but cannot reach is a finding regardless of its manifest status.

## 3. Route → file resolution

The audit uses the shared resolver (`docs/specs/00-overview.md` §3, `docs/specs/02-nav-graph.md`
§3): for `/elixir/<path>`, check `R/<path>.html` then `R/<path>/index.html`; the root maps to
`R/index.html`. An href "resolves" iff one of those candidates exists on disk.

## 4. The two known true broken links

Exactly two true broken links exist in the current tree, both **slug mismatches**: a clean
route that points at a page whose built file was named differently from the route's leaf.
Each is a finding of kind `orphan-slug`.

| # | Linked route (broken) | Backing orphan file | Canonical target filename | Referenced by |
|---|---|---|---|---|
| 1 | `/elixir/functional/higher-order` | `functional/higher-order-functions.html` | `functional/higher-order.html` | `elixir/index.html`, `functional/index.html`, `functional/recursion/index.html` |
| 2 | `/elixir/functional/composition` | `functional/composition/functional.html` | `functional/composition/index.html` | `functional/composition/compose.html`, `functional/composition/pipe.html`, `functional/composition/pipeline.html` |

Each broken route is referenced **5×** across the built pages (the canonical figure from the
project brief). The audit reports the live occurrence count it computes from the tree
alongside the distinct referencing-file list; small differences between the brief's figure
and a given snapshot are expected as content is edited, so the count is computed, never
hard-coded. (At the time of writing the snapshot shows 4 occurrences for route 1 and 5 for
route 2; the audit reports whatever it counts.)

Why these are `orphan-slug` and safely fixable: **the orphan file's own header already
advertises the canonical clean route.** Each orphan carries, in its `.crumbs`/`route-tag`
header, the exact route that the other pages link to:

- `functional/higher-order-functions.html` advertises `route-tag = /elixir/functional/higher-order`
  and `here = F2.03`.
- `functional/composition/functional.html` advertises
  `route-tag = /elixir/functional/composition` and `here = F2.08`.

So the page intends to live at the clean route; only its filename is wrong. The repair is to
rename the file to the filename that the clean route resolves to:

- `functional/higher-order-functions.html` → `functional/higher-order.html`
  (so `/elixir/functional/higher-order` resolves to a leaf file).
- `functional/composition/functional.html` → `functional/composition/index.html`
  (so `/elixir/functional/composition` resolves to the directory hub).

Both target filenames are currently free (no `functional/higher-order.html` and no
`functional/composition/index.html` exist), so the renames are non-destructive.

These two findings correspond to the manifest's `PAGES` registry, where the same divergence
is declared at build time: key `f2-3` builds output `higher-order-functions.html`, and the
F2.08 composition fragment builds `composition/functional.html`. The repoint here, and a
later alignment of the `PAGES` `Out` filenames, are two views of the same slug-vs-filename
gap (`docs/specs/01-manifest.md` §5).

## 5. The known-fix table and `--fix` semantics

The repair set is data, not ad-hoc logic, so it is auditable and extensible:

```go
// A KnownFix renames an orphan file to the canonical filename that its
// advertised clean route resolves to.
type KnownFix struct {
    Route    string // the clean route the pages link to (broken target)
    FromFile string // current orphan filename, relative to root
    ToFile   string // canonical filename the route resolves to, relative to root
}

var KnownFixes = []KnownFix{
    {Route: "/elixir/functional/higher-order",
     FromFile: "functional/higher-order-functions.html",
     ToFile:   "functional/higher-order.html"},
    {Route: "/elixir/functional/composition",
     FromFile: "functional/composition/functional.html",
     ToFile:   "functional/composition/index.html"},
}
```

`cms audit --fix` does the following, in order, deterministically:

1. Run the read-only audit (§1–§4) and print the findings report (§7).
2. For each true broken link of kind `orphan-slug`, look up its route in `KnownFixes`.
3. For a match, verify the preconditions:
   - `FromFile` exists under the root;
   - `ToFile` does **not** exist under the root (never overwrite);
   - the orphan file's header advertises `Route` (re-read the `route-tag`/`.crumbs here`
     value and confirm it equals the fix's `Route`) — a guard so `--fix` repoints only files
     that already claim the canonical route.
4. If all preconditions hold, rename `FromFile` → `ToFile` (`os.Rename`, creating the parent
   directory of `ToFile` if needed). Renaming the file makes the clean route resolve, so all
   five+ existing links to that route go live unchanged. The referencing pages are **not
   edited** — they already use the canonical route; only the file moves.
5. If a precondition fails (target occupied, source missing, header does not advertise the
   route), skip the fix and report it as `skipped` with the reason. `--fix` never overwrites
   and never edits page bodies.
6. A true broken link of kind `missing-build` (an allowed route with no file, no sibling
   orphan) is **not** auto-fixable — the page has to be built — so `--fix` reports it as
   `unfixable: build the page` and leaves it.

`--fix` moves files but does not rewrite any `href`. The repair is a rename precisely because
the references are already canonical; the only thing out of place is the file's name.

## 6. Path-traversal guard

Because audit resolves hrefs *scraped from page bytes* (not trusted manifest routes), it
guards against traversal before touching the filesystem. A resolved candidate path is
accepted only if, after `filepath.Clean`, it remains within the content root (equal to the
root or under it with a separator boundary). Any href whose path component contains a raw
`..` segment, or that resolves outside the root, is reported as kind `unsafe` and never
opened. This mirrors the server's `resolveUnder` guard. `--fix` applies the same containment
check to both `FromFile` and `ToFile` before renaming; a fix that would move a file outside
the root is refused.

## 7. Report format and exit codes

`cms audit` prints a grouped report. Default (no `--fix`):

```
Link audit · root=../../elixir
  scanned: 39 pages, 312 internal links

TRUE BROKEN (2 routes)
  /elixir/functional/higher-order        orphan-slug   occurrences=4  files=3
      backing orphan: functional/higher-order-functions.html
      fix on --fix:   -> functional/higher-order.html
      referenced by:  elixir/index.html, functional/index.html,
                      functional/recursion/index.html
  /elixir/functional/composition         orphan-slug   occurrences=5  files=3
      backing orphan: functional/composition/functional.html
      fix on --fix:   -> functional/composition/index.html
      referenced by:  functional/composition/compose.html,
                      functional/composition/pipe.html,
                      functional/composition/pipeline.html

PLACEHOLDERS (informational, not errors)
  planned/soon routes rendered as non-linking cards: 0 dead href, 0 "скоро"
  (placeholders are intentional and are not counted as broken)

STATUS: 2 broken route(s)
```

With `--fix`, the same report is followed by an actions block:

```
REPOINT
  renamed functional/higher-order-functions.html -> functional/higher-order.html
  renamed functional/composition/functional.html -> functional/composition/index.html

STATUS: 2 fixed, 0 skipped
```

Output ordering is deterministic: findings sorted by route; referencing files sorted by path;
fixes applied in `KnownFixes` order.

Exit codes:

| Invocation | Outcome | Exit |
|---|---|---|
| `cms audit` | no true broken links | `0` |
| `cms audit` | ≥1 true broken link | `1` |
| `cms audit --fix` | all true broken links fixed (or only placeholders) | `0` |
| `cms audit --fix` | ≥1 true broken link remained (skipped/unfixable) | `1` |
| any | bad/unreadable root, bad flag | `2` |

After a successful `cms audit --fix`, a subsequent `cms audit` reports `0` broken routes,
because the renamed files now back their canonical routes.
