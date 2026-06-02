# 07 — Content store: the filesystem-mirrored SQLite store and byte-parity builder

This document specifies the SQLite **content store** (`internal/store`) and the
store-backed **assembler** (`internal/builder`) that together decompose every published
`/elixir` page into normalized templates plus per-page data and recompose **byte-identical**
output. It supersedes the assembly model of `docs/specs/05-build-validate.md` for the build
path actually shipped, and it extends the storage scope recorded in
`docs/specs/90-deferred-auth.md`.

## 1. Why this supersedes the spec-05 shared-head model

Spec 05 §2–§4 ports `build_page.py`'s assembly: a **single shared `_head.html`** filled with
per-page title/description, plus a hand-authored body fragment, plus the bootstrap. That model
assumes one head reproduces every page's `<head>`. An empirical probe of the live pages
(`/tmp/parity_probe.py`, run against `build_page.py`'s own `_assemble`) disproves that
assumption for this repository: the shared `_head.html` does **not** reproduce the published
heads. Two causes:

- **Per-page accent.** Each chapter carries an accent (`manifest.Chapter.Accent`), and the head
  CSS differs accordingly, so heads are not identical across pages.
- **Drift since extraction.** The published heads have moved on from the single `_head.html`
  snapshot; recent edits landed in pages without re-extracting the shared partial.

Reproducing the published bytes from one shared head is therefore not possible. The content
store resolves this by storing **each page's own head template** (deduplicated by content hash),
not one shared head. The 204 published pages dedup into 66 distinct head templates.

The body side also differs from spec 05: this repository commits the **already-built** pages,
not the hand-authored `content/*.html` fragments `build_page.py` consumes. The store therefore
holds each page's **rendered body fragment** verbatim (with only the build stamp re-placeholded),
not a pre-substitution fragment. Consequently the two generated-from-manifest substitutions of
spec 05 §3 (`{{CONTENTS}}`, `{{CHAPTERS_JSON}}`, and `{{MODULE_COUNT}}`) are **already expanded**
in the stored bytes; round-trip parity replays them rather than regenerating them.

This is a deliberate model change for the shipped build path, decided by the repository owner.
Spec 05 remains the reference for the gate suite (`cms check`) and for the Python-parity
semantics; this document governs `cms build`.

> **TODO (future capability, not this cycle).** Regenerating the two index pages
> (`/elixir` and `/elixir/course`) *from the manifest* — i.e. expanding `{{CONTENTS}}`,
> `{{CHAPTERS_JSON}}`, `{{MODULE_COUNT}}` via `RenderContents()`/`ChaptersJSON()`/`ModuleCount()`
> as spec 05 §3 describes — is a separate capability. The current store round-trips those two
> pages by replaying their stored bytes like any other page; it does not synthesize them from
> the manifest. From-manifest generation can be added later without changing the store schema.

## 2. The byte-contract (ground truth)

The page envelope is `build_page.py`'s `_assemble` return value, copied byte-for-byte into
`internal/tmpl`:

```
<!doctype html>\n<html lang="en">\n   ← DOCTYPE
<filled head>                          ← head template with {{TITLE}}/{{DESC}} filled
\n<body>\n                             ← BodySep
<filled fragment>                      ← body fragment with {{BUILD_ID}}/{{BUILD_TS}} filled
\n                                     ┐
<BOOTSTRAP script>                     │ Suffix
\n</body>\n</html>\n                   ┘
```

`DOCTYPE`, `BodySep`, `BOOTSTRAP`, and `Suffix` (= `"\n" + BOOTSTRAP + "\n</body>\n</html>\n"`)
are constants in `internal/tmpl`, copied verbatim from the Python source.

### 2.1 `Esc` — the HTML escaper

`tmpl.Esc` reproduces Python `html.escape(s, quote=True)`: the five replacements `&`→`&amp;`,
`<`→`&lt;`, `>`→`&gt;`, `"`→`&quot;`, `'`→`&#x27;`, with `&` applied first. The apostrophe form
is the **Python** `&#x27;`, **not** the `&#39;` that Go's `html.EscapeString` emits. This matters
for parity: the published pages carry `&#x27;` (confirmed against
`elixir/phoenix/blueprint.html`, whose `<title>` is `What we&#x27;re building — F6.0.2 · jonnify`).
`Esc` is therefore implemented directly as a `strings.NewReplacer`, which scans the input once
and does not re-escape its own output, so the leading `&` rule does not double-encode the `&` in
the later entities.

## 3. Schema (`internal/store`)

Opened through `database/sql` with the pure-Go driver registered as `sqlite`
(`modernc.org/sqlite`), keeping the module CGO-free.

```sql
CREATE TABLE head (
  id     INTEGER PRIMARY KEY,
  sha256 TEXT NOT NULL UNIQUE,   -- of the head TEMPLATE bytes (title/desc re-placeholded)
  bytes  BLOB NOT NULL
);
CREATE TABLE page (
  route       TEXT PRIMARY KEY,   -- clean route, e.g. /elixir/algebra/functions ; /elixir for root
  output_path TEXT NOT NULL,      -- path relative to the /elixir root, e.g. algebra/functions.html
  title       TEXT NOT NULL,      -- UNescaped
  descr       TEXT NOT NULL,      -- UNescaped
  head_id     INTEGER NOT NULL REFERENCES head(id),
  fragment    BLOB NOT NULL,      -- body fragment TEMPLATE, stamp re-placeholded
  build_id    TEXT NOT NULL,      -- the page's pinned stamp (may be "")
  build_ts    TEXT NOT NULL,      -- "YYYY-MM-DD HH:MM:SS UTC" (may be "")
  byte_len    INTEGER NOT NULL    -- published page length, sanity
);
```

`title`/`descr` are stored **unescaped**; the builder re-escapes them with `tmpl.Esc` on
assembly, so the round-trip is `unescape(published) → Esc → published`. The head row is the head
**template** (placeholders, not the filled head), deduplicated by the sha256 of those template
bytes.

API:

- `Open(path) (*Store, error)` — `path` may be `:memory:` or a file; the schema is created if
  absent.
- `LoadFromTree(elixirRoot) (LoadReport, error)` — walks `elixirRoot/**/*.html`, decomposes each
  conforming page (§4), and inserts a row per page, deduplicating heads. `LoadReport` carries
  `Pages`, `DistinctHeads`, and `Skips` (each `{Path, Reason}` for a non-conforming file). Files
  are processed in sorted path order so head ids are deterministic.
- `Get(route) (Page, headBytes, error)` — the page row plus its head template bytes.
- `Routes() ([]string, error)` — every stored route, ascending.

## 4. Decomposition (the loader) — lossless

For each published file `P` (bytes) under `elixirRoot`:

1. `P` must start with `DOCTYPE`; else **skip + report**.
2. `i = index(P, "\n<body>\n")`; absent → **skip + report**.
3. `HEAD = P[len(DOCTYPE):i]` (the filled `<head>…</head>`).
4. `AFTER = P[i+len("\n<body>\n"):]`; `AFTER` must end with `Suffix`; else **skip + report** (a
   non-standard bootstrap/tail). `FRAGMENT = AFTER[:len(AFTER)-len(Suffix)]`.
5. **Head template + data.** In `HEAD`, capture `<title>(.*?)</title>` → `titleEsc` and
   `<meta name="description" content="(.*?)">` → `descEsc` (both dot-all, non-greedy). The head
   **template** is `HEAD` with each captured **value span** spliced to `{{TITLE}}` / `{{DESC}}`
   (the splice replaces exactly the matched value at its byte offset, preserving the surrounding
   `<title>…</title>` and `content="…"` literals). Store `title = unescape(titleEsc)`,
   `descr = unescape(descEsc)` (`html.UnescapeString`).
   - **Round-trip assertion.** `Esc(title) == titleEsc` and `Esc(descr) == descEsc`. A page whose
     escaping differs from `Esc` is **skipped + reported** rather than stored, because the builder
     could not reproduce its bytes.
6. **Fragment template + stamp.** In `FRAGMENT`, capture `id="stampId">([^<]*)<` → `buildID` and
   `id="st-ts">([^<]*)<` → `buildTS` (each optional). The fragment **template** is `FRAGMENT`
   with those captured values spliced to `{{BUILD_ID}}` / `{{BUILD_TS}}`. Absent captures leave
   the value `""` and the template equal to the fragment.
7. **Route + output path.** Inverting `internal/site` resolution: `elixirRoot/index.html` →
   `/elixir`; `elixirRoot/<dir>/index.html` → `/elixir/<dir>`; any other `elixirRoot/<p>.html`
   → `/elixir/<p>`. `output_path` is the path relative to `elixirRoot`.
8. **Head dedup.** Heads are keyed by the sha256 of the head template; identical templates share
   one row.

The splice in steps 5–6 operates on the regex capture's byte offsets (highest offset first so
earlier offsets stay valid), so it re-placeholds exactly the matched substring and cannot collide
with an identical literal elsewhere in the document.

## 5. Assembly (`internal/builder`)

- `Assemble(headTemplate, p store.Page) []byte` returns exactly
  `DOCTYPE + fillHead(headTemplate, p.Title, p.Descr) + BodySep + fillStamp(p.Fragment, p.BuildID, p.BuildTS) + Suffix`,
  where `fillHead` replaces `{{TITLE}}`→`Esc(title)` then `{{DESC}}`→`Esc(descr)` (each once,
  matching `_assemble`'s two `.replace` calls), and `fillStamp` replaces `{{BUILD_ID}}`→`buildID`
  then `{{BUILD_TS}}`→`buildTS` (verbatim; the stamp values are base62 / digits and are not
  escaped).
- `BuildFromStore(s, route) ([]byte, error)` reads the page and head from the store and calls
  `Assemble`.

## 6. `cms build` (`cmd/build.go`)

Three mutually exclusive modes; content root from `--root`, then `$CMS_ELIXIR_DIR`, then
`defaultRoot()` discovery.

- `cms build --load DB` — build the content store at `DB` from the `/elixir` tree; print the load
  report (pages, distinct heads, skipped + reasons).
- `cms build --route /elixir/PATH [--db DB] [--out FILE]` — assemble that route from the store
  (or from an in-memory store loaded from `--root` when no `--db`) and write it to stdout or
  `--out`.
- `cms build --verify [--db DB] [--root R]` — assemble every stored page and compare to the
  published file; print `OK n/N pages reproduce byte-for-byte` and list mismatches (route, output
  path, first-diff offset, byte lengths).

Exit codes: `0` success, `1` mismatch/build failure, `2` usage error (no mode, or more than one
mode selected).

## 7. Parity test (`internal/builder/parity_test.go`)

A permanent, offline, deterministic Go test. It locates the published tree via `CMS_ELIXIR_DIR`
or by walking up from the test file to the directory holding `elixir/index.html`; absent the
tree it `t.Skip`s so the suite stays portable.

- `TestPublishedPagesRoundTripByteIdentical` — load the tree into an in-memory store, assemble
  every page, and require byte-equality with the published file. Asserts the loaded count equals
  the on-disk `*.html` count and the skip list is empty (so a non-conforming page fails the test
  rather than being silently omitted). On mismatch, reports route, output path, first-diff offset,
  and an 80-character window from each side.
- `TestStampRoundTrip` — for each page with a non-empty `buildID`, asserts
  `snowflake.Decode(buildID).Timestamp == buildTS` (the page's own stamp is internally
  consistent).
- `TestDistinctHeadCount` — logs the distinct head-template count (`>= 1` asserted).

As of this writing, all 204 published pages round-trip byte-for-byte, all 204 carry a consistent
stamp, and the pages dedup into 66 distinct head templates; no file is skipped.
