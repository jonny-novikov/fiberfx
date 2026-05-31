# 05 — Build and validate: the assembly pipeline and the nine Apollo gates

This document specifies `cms build [--page KEY | --all]`, `cms check FILES...`, and the
`internal/apollo` gate suite. `build` is the Go port of `build_page.py`'s assemble step:
read a hand-authored content fragment, substitute the shared head and generated data, append
the bootstrap script, write the page, then validate it through the nine Apollo gates. `check`
runs those same gates against already-built files.

> **Status.** `build` is **spec-complete but not yet runnable.** The content fragments it
> assembles (`content/*.html`, named by `manifest.Pages[*].Fragment`) are not committed to
> this repository. The fragment registry, the substitution set, the assembly order, and the
> gate suite are fully specified here; `cms build` runs once the fragments land. `cms check`
> is runnable now, against the built pages under `/elixir`.

## 1. Build inputs

- **The build registry** `manifest.Pages` (`docs/specs/01-manifest.md` §5): each `Page` carries
  `Key`, `Fragment` (the content path), `Out` (output filename), `Title`, `Desc`.
- **The shared head** — `_head.html`, the design-system `<head>` partial.
- **The content fragment** — `Page.Fragment`, a hand-authored HTML body fragment containing
  substitution placeholders.

All paths are resolved relative to the build root (the directory holding `_head.html`,
`content/`, and the output files — the analog of the Python `ROOT`, the kb directory). A
`--root`-style override may be provided; absent one, the build root defaults to the tool's
configured content-source directory.

## 2. The shared head: `_head.html`

The head partial is the design-system `<head>`: charset, viewport, `{{TITLE}}` and `{{DESC}}`
placeholders, the Google Fonts preconnect/stylesheet links (Cormorant Garamond, PT Serif,
Manrope, JetBrains Mono), and the full inline `<style>` carrying the `:root` design tokens
and the page CSS. Its content is the constant ported from `build_page.py`'s `HEAD_HTML`
(which embeds `HEAD_CSS`).

`build_page.py` exposes `extract-head` to write this partial to disk once. In the Go port the
head is a compiled-in constant (`apollo`/`build` embed it), and a `cms build` run reads it
from the constant rather than requiring a separate `extract-head` step. The partial is still
written to `_head.html` on first build for parity and for inspection, but the build does not
fail if the file is absent — it falls back to the constant. (This removes the Python "run
`extract-head` first" precondition.)

The two head placeholders are filled per page:

- `{{TITLE}}` → HTML-escaped `Page.Title`.
- `{{DESC}}` → HTML-escaped `Page.Desc`.

HTML-escaping is the equivalent of Python `html.escape(s, quote=True)`: `&`→`&amp;`, `<`→`&lt;`,
`>`→`&gt;`, `"`→`&quot;`, `'`→`&#x27;`. Use `html.EscapeString` from the Go standard library;
verify it produces the same five replacements (it escapes `&<>'"` ), so head/body escaping
matches the Python output.

## 3. Generated body substitutions

The content fragment carries placeholders that the build fills from the manifest and the
Snowflake minter. All five are global (the same generated values for every page in a run,
except the build id/timestamp which are minted per page):

| Placeholder | Source | Value |
|---|---|---|
| `{{CONTENTS}}` | `RenderContents()` | the full contents directory: every chapter with its module cards (links for linkable, `is-quiet` cards for placeholders), built from the manifest. |
| `{{CHAPTERS_JSON}}` | `ChaptersJSON()` | a JSON array of the F1–F6 chapters for the interactive arc (F0 excluded). |
| `{{BUILD_ID}}` | `snowflake.Mint("TSK")` | a freshly minted 14-char branded id, per page. |
| `{{BUILD_TS}}` | `decode(BUILD_ID).timestamp` | the UTC timestamp the build id decodes to, `YYYY-MM-DD HH:MM:SS UTC`. |
| `{{MODULE_COUNT}}` | `ModuleCount()` | `54` (the F1–F6 spine; `docs/specs/01-manifest.md` §6). |

### 3.1 `RenderContents()`

Port of `render_contents()` + `_module_card()` + `_pill()`. For each chapter, emit a
`<section class="chap reveal">` containing a `.chap-head` (chapter id, title, and either an
`Open chapter →` link when the chapter is linkable or a status pill otherwise, plus the
chapter one-liner), followed by a `.mods` grid of module cards. Each module card:

- classes: `mod`, plus `lab` when `Module.Lab`, plus `is-quiet` when the module is **not**
  linkable;
- inner: a `.top` row with the module number and a status pill, the title `<p class="t">`,
  the one-liner `<p class="o">`, and, when the module has `Dives`, a `<ul class="dives">` of
  dive rows;
- wrapper: `<a class="mod …" href="route">…</a>` when linkable, else `<div class="mod …">…</div>`.

All text is HTML-escaped. The pill is `<span class="pill <status>"><status></span>`. The
linkable test is `Module.Status.Linkable()` (`{live, built}`). This is the function that turns
a promotion (`docs/specs/04-readiness.md` §4) into a link: when a module's status flips to
`built`, its card switches from the `is-quiet` `<div>` to an `<a href>`.

### 3.2 `ChaptersJSON()`

Port of `chapters_json()`. A JSON array, one object per chapter **except F0** (the arc shows
the F1–F6 spine), each: `{id, name, route, live, modules, one, reuses}`, where `live` is the
chapter's linkability and `modules` is `len(Modules[id])`. Encode with the standard library;
match the Python `json.dumps(..., ensure_ascii=False)` — i.e. emit non-ASCII characters
literally (UTF-8), not as `\uXXXX`. Set the encoder so HTML-significant characters are **not**
escaped to `<` etc., to match `ensure_ascii=False` and keep the on-page JSON readable;
the value is injected into a `<script>`/data attribute context where the gate suite checks
well-formedness.

## 4. Assembly

Port of `_assemble()` + `_build_one()`. For a page key `K` → `Page P`:

1. Load the head partial (constant; or `_head.html` if present), fill `{{TITLE}}`/`{{DESC}}`
   with escaped `P.Title`/`P.Desc`.
2. Read the fragment file `P.Fragment`.
3. Mint `buildID := snowflake.Mint("TSK")`; `info := snowflake.DecodeBranded(buildID)`.
4. In the fragment, replace `{{CONTENTS}}`, `{{CHAPTERS_JSON}}`, `{{BUILD_ID}}` (= `buildID`),
   `{{BUILD_TS}}` (= `info.Timestamp`), `{{MODULE_COUNT}}` (= `ModuleCount()`).
5. Compose the final document:

   ```
   <!doctype html>
   <html lang="en">
   <head>…</head>
   <body>
   <fragment with substitutions>
   <BOOTSTRAP script>
   </body>
   </html>
   ```

   The exact wrapper string reproduces the Python `_assemble` return value, including the
   leading `<!doctype html>\n<html lang="en">\n`, the head, `\n<body>\n`, the fragment, `\n`,
   the bootstrap, `\n</body>\n</html>\n`.
6. Write the document to `P.Out` (UTF-8). Report `built <out> (<n> bytes) from <fragment>`.
7. Run the nine Apollo gates against the written bytes (§6) and print the per-gate report.
8. The page build succeeds iff all gates pass.

### 4.1 The bootstrap script

Port of `BOOTSTRAP`. A `<script>` appended at the end of `<body>` that (a) adds the `js` class
to `document.documentElement` and (b) on `DOMContentLoaded` reveals `.reveal` elements via an
`IntersectionObserver`, short-circuiting to "reveal all immediately" when
`prefers-reduced-motion: reduce` is set or `IntersectionObserver` is unavailable. The script
text is the exact constant from the Python source. Its presence and shape are what the
`degrade`/`motion` gates check (§6).

## 5. `cms build` — flags, behavior, exit codes

```
cms build [--page KEY] [--all]
```

- `--page KEY` (default `landing`): build the single registered page `KEY`. An unknown key is
  a usage error: print `unknown page 'KEY'. known: <comma-joined keys>` to stderr, exit `2`.
- `--all`: build every registered page, in `manifest.PageOrder` (registration order, for
  determinism). Overrides `--page`.
- For each built page, assemble (§4) and validate (§6). The command's overall result is the
  AND of every page's gate result.

Exit codes: `0` when every built page passes all gates; `1` when any page fails any gate;
`2` on an unknown `--page` key or other usage error.

Because the content fragments are not yet committed, `cms build` against this repository
fails to find `P.Fragment` and reports a clear `missing fragment: content/…` error per page;
this is expected until the fragments land. The command's logic, registry, substitutions, and
gate wiring are nonetheless complete and frozen by this spec.

## 6. The nine Apollo gates

`internal/apollo` ports the nine gates from `build_page.py` **exactly** — same names, same
order, same pass/fail semantics, same detail messages — so a page that passes the Python
`check` passes `cms check` and vice versa. The gate runner:

```go
type GateResult struct {
    Name   string // gate name
    OK     bool
    Detail string // human-readable detail (matches the Python message)
}

// Run executes the nine gates in order against the document bytes.
func Run(doc []byte) (passed bool, results []GateResult)
```

`passed` is the AND of every gate's `OK`. The nine gates, in order:

### 6.1 `containers` — balanced container tags

Port of `gate_containers`. Strip `<script>…</script>`, `<style>…</style>`, and `<svg>…</svg>`
regions first (case-insensitive, dot-all). Then scan tags with the regex
`<(/?)([a-zA-Z][\w-]*)([^>]*?)(/?)>`. Track only the container set
`{div, section, main, header, footer, nav, article, figure, aside}`. Push opening tags, pop on
the matching closing tag; a self-closing container tag is ignored. Fail on:

- a closing tag whose name does not match the top of the stack →
  `unbalanced </NAME> (open container was <TOP>)` (or `<—>` when the stack is empty);
- a non-empty stack at end → `unclosed <NAME> — check for a missing </div> in a section`.

Pass detail: `container tags balanced`.

### 6.2 `svg` — at least one well-formed SVG

Port of `gate_svg_wellformed`. Count `<svg\b` (open) and `</svg>` (close), case-insensitive.
Fail if zero opens (`no <svg> present — every page carries a seen argument`) or if opens ≠
closes (`svg open/close mismatch (O open, C close)`). Pass: `O svg block(s), well formed`.
The requirement is "≥ 1 SVG and balanced open/close counts."

### 6.3 `no-future` — no `/future` links

Port of `gate_no_future`. Fail if the substring `/future` appears anywhere in the document
(`found a link to /future`); pass otherwise (`no /future links`). A plain substring test over
the whole document, not hrefs alone.

### 6.4 `voice` — no hype/dismissive words

Port of `gate_forbidden`. Compute the **visible text**: strip `<script>`/`<style>`, then strip
`<svg>…</svg>`, then strip all remaining tags `<[^>]+>` → spaces, then HTML-unescape. Match the
forbidden set case-insensitively with word boundaries:
`revolutionary | blazing-fast | magical | simply | just | obviously | effortless`
(the `blazing-fast` alternative allows an optional space or hyphen between `blazing` and
`fast`: regex `blazing[\s-]?fast`). Fail listing the distinct lowercased hits
(`forbidden words: …`); pass `no hype / dismissive words`. The check is on visible text only,
so the words may legitimately appear inside `<script>`/`<style>`/`<svg>` or in attributes.

### 6.5 `storage` — no web storage APIs

Port of `gate_storage`. Fail if `localStorage` or `sessionStorage` appears anywhere
(word-boundary match), reporting `uses <api>`; pass `no web storage APIs`. The check is over
the whole document (these are JS identifiers, not visible text).

### 6.6 `motion` — honors `prefers-reduced-motion`

Port of `gate_reduced_motion`. Pass iff the substring `prefers-reduced-motion` is present
(`honours prefers-reduced-motion`); fail otherwise
(`missing prefers-reduced-motion handling`).

### 6.7 `degrade` — `.reveal` is JS-gated

Port of `gate_reveal_degrades`. If `.reveal` does not appear, pass with `no reveal animation`
(nothing to gate). Otherwise pass iff `html.js .reveal` or `.js .reveal` appears
(`reveal is JS-gated; content visible without JS`); fail otherwise
(`reveal hides content without a JS gate`). This enforces that any reveal animation is hidden
only when JS is on, so the content is visible without JavaScript.

### 6.8 `links` — internal links resolve to allowed routes

Port of `gate_links`. For every `href="([^"]+)"`, skip hrefs starting with
`#`, `http://`, `https://`, `mailto:`, `tel:`, or `//`. For each remaining (internal) href,
require membership in `manifest.AllowedRoutes()` (`docs/specs/01-manifest.md` §4). Fail listing
the sorted distinct offenders (`dangling internal links: …`); pass
`all internal links resolve to live/built routes`. This gate is the build-time analog of the
runtime link audit (`docs/specs/03-link-audit.md`): it checks a page's own hrefs against the
linkable set, where the audit checks the whole tree against the filesystem.

### 6.9 `pager` — a working pager block

Port of `gate_pager`. Fail if `class="pager"` is absent (`no .pager navigation block`).
Otherwise pass iff at least one `href` in the document is a member of
`manifest.AllowedRoutes()` (`pager links to a real route`); fail otherwise
(`pager has no link to a live/built route`). Every page must carry a pager with at least one
link to a linkable route.

### 6.10 Gate list and grade

```go
var Gates = []struct {
    Name string
    Fn   func(doc []byte) (ok bool, detail string)
}{
    {"containers", gateContainers},
    {"svg",        gateSVGWellformed},
    {"no-future",  gateNoFuture},
    {"voice",      gateForbidden},
    {"storage",    gateStorage},
    {"motion",     gateReducedMotion},
    {"degrade",    gateRevealDegrades},
    {"links",      gateLinks},
    {"pager",      gatePager},
}
```

A document earns grade **A+** iff all nine pass. The order is fixed and significant only for
report stability; `passed` is order-independent.

### 6.11 Regex/string parity notes

The gates use the same patterns as the Python source. Implementation notes for Go:

- Compile the forbidden-words and tag regexes with `(?i)` for case-insensitivity and `(?s)`
  (dot-all) for the strip regexes, matching Python's `re.I`/`re.S`.
- Go's `regexp` is RE2; the patterns here (alternation, character classes, bounded quantifiers,
  `\b`, `\w`, `[^>]`) are all RE2-expressible. `\b` is supported in RE2.
- Strip `<script>`/`<style>`/`<svg>` regions with non-greedy `.*?` under `(?s)` exactly as the
  Python `_strip_code`/`_visible_text` do, so the visible-text extraction matches.
- HTML-unescape for the `voice` gate uses `html.UnescapeString` (the inverse of the escaping
  in §2).

## 7. `cms check` — flags, output, exit codes

```
cms check FILE [FILE ...]
```

Port of `cmd_check` + `print_apollo`. For each file: read it, run `apollo.Run`, print:

```
Apollo · <path>
  [PASS] containers  container tags balanced
  [PASS] svg         3 svg block(s), well formed
  [PASS] no-future   no /future links
  [PASS] voice       no hype / dismissive words
  [PASS] storage     no web storage APIs
  [PASS] motion      honours prefers-reduced-motion
  [PASS] degrade     reveal is JS-gated; content visible without JS
  [PASS] links       all internal links resolve to live/built routes
  [PASS] pager       pager links to a real route
  grade: A+
STATUS: PASS
```

- `[PASS]`/`[FAIL]` per gate, the name left-padded to 11, then the detail.
- `grade:` is `A+` when all pass, `—` otherwise.
- `STATUS:` is `PASS`/`FAIL` per file.

The command's exit code is `0` iff **every** file passes **every** gate; `1` if any file fails
any gate; `2` if a file cannot be read. `cms check` is the gate runner used by `readiness`
(`docs/specs/04-readiness.md` §5) and by `build` step 7; the three share `apollo.Run`.
