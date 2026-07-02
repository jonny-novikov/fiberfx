# MX.9.4 · build context (the agent brief)

Build context for [`mx.9.4.md`](./mx.9.4.md) (authoritative body) + [`mx.9.4.stories.md`](./mx.9.4.stories.md).
The body wins on any disagreement. **WRITE-READY (re-sharpened 2026-07-02 at ship)** — the construct
inventory below is PERFORMED (all 65 contracts, mechanical greps + three end-to-end reads); the builder
writes first. **FORK-1 RULED (Operator, 2026-07-02): Arm A** — a nested sub-tab row inside the Docs tab;
the placeholders below are filled; the xref rule (non-navigating spans for relative links) is confirmed.

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state
> verbs; no first-person narration. State each surface as a contract.

## Grounded facts (verified 2026-07-02 — cite, do not re-derive)

- **The census (re-confirmed at ship):** 65 contracts under
  `mercury/packages/mercury-ui/src/components/*/*/*.prompt.md`. Headings: `## Props` · `## Notes` ·
  `## Examples` · `## Composition` **65/65**; `## The enum language` **56/65**. The 9 enum-less:
  data-display/Table · inputs/{Search,AuthCode,Input,Select} · layout/AuthLayout ·
  selection/{Radio,Checkbox,Switch}. **Heading order is uniform — exactly two orders exist:**
  `Props → The enum language → Composition → Examples → Notes` (56) and the same minus the enum section
  (9). `## Props` is always the first `## `; `## Notes` always the last.
- **The construct inventory (the owed ship-time step — PERFORMED over all 65):**

| Construct | Files /65 | Handling (fixed by this spec) |
|---|---|---|
| `# ` h1 · `## ` h2 | 65 · 65 | Render; `## ` is THE cut boundary (exact depth) |
| `### ` h3 | 1 (`navigation/TabNav/TabNav.prompt.md:17`, `` ### `TabNavItem` ``) | Render; **never** a cut boundary; inline pass applies inside headings |
| `#### `–`###### ` | 0 | Out of scope → the fallback law |
| GFM table (header + `\|[\s:|-]+\|` separator) | 65 (67 tables — Table + TabNav carry a SECOND 3-col table under `## Props`) | `<table>` head+body; per-cell inline pass |
| Escaped `\|` in cells | 50 | **Must** split on `/(?<!\\)\|/` + unescape `\|`→`\|`-literal (seed `splitRow`, library.jsx:16–18); `Button.prompt.md:11` must render `"primary" \| "secondary" \| …` |
| Fenced code (info: none \| `tsx`, 66 blocks, all top-level) | 65 | `<pre><code>` literal text; info string ignored |
| Flat `-` list | 65 | `<ul><li>`; no other list marker in the corpus |
| **List-item continuation lines** (1–3-space indent) | 65 (475 lines; 100% follow a list item) | **JOIN into the current `<li>`** — the seed splits each into a stray `<p>` (structural corruption of every contract's lists); mandatory extension |
| Ordered/nested lists · blockquote · hr · images · `~~` · ref-links · indented code | 0 each | Out of scope → the fallback law |
| Inline `` `code` `` | 65 | Atomic token, extracted FIRST (protects `*` `\|` `<tags>` inside backticks) |
| `**bold**` | 65 | `<strong>`; **34/65 files wrap a code span in bold** (`Table.prompt.md:16`) — see the inline algorithm |
| `*italic*` (single asterisk, prose) | 16 | `<em>` — **extension over the seed** (the seed renders literal asterisks); e.g. `Button.prompt.md:41–42` (spans a joined line) |
| `_italic_` | 0 (the lone `_…_` hit is BEM names inside code, `Menubar.prompt.md:25`) | Out of scope |
| `[text](target)` links | 60 (~200 links; **100% relative `.prompt.md` cross-links, 0 http**) | The xref rule (below) |

- **The fallback law (INV-4, no silent drop):** any block line no recognizer claims renders as a
  paragraph — content always reaches the DOM, never dropped. Out-of-scope constructs are covered by
  this, not by silence.
- **The xref rule (inventory-driven, fixed by the body §3):** every corpus link targets a sibling
  `.prompt.md` source path that the SPA does not serve — a real `<a>` would navigate to a dead route. A
  relative link renders as a non-navigating `<span className="showcase-md-xref" title={target}>{text}</span>`;
  an absolute `http(s)` link (0 today) renders `<a target="_blank" rel="noreferrer">`.
- **The registry surface** (`mercury/apps/showcase/src/registry.ts:3–11`):
  `ShowcaseEntry = { group: string; name: string; loadStories: StoryModuleLoader; loadPrompt?: PromptLoader }`;
  `PromptLoader = () => Promise<string>` (lazy `?raw`; **absent** when no sibling `.prompt.md`).
- **The Docs stub** (`mercury/apps/showcase/src/shell/ComponentPage.tsx`, ~50 lines): `type Tab =
  "stories" | "docs"`; a `role="tablist"` row of `.showcase-tab` buttons; the docs branch is
  `<p className="showcase-stub">The contract surface lands at mx.9.4.</p>`; the stories branch is
  `<StoriesPanel entry={entry} />` — **mx.9.3's surface, DO NOT touch**.
- **The route persistence** (`mercury/apps/showcase/src/App.tsx:8–27`): `ROUTE_KEY =
  "mx-showcase.route.v1"` stores JSON `{ group, name, tab }`; `readRoute` degrades an unknown `tab` to
  `"stories"`. Arm-relevant: Arm B widens the `Tab` union + `readRoute`; Arms A/C keep App.tsx untouched.
- **The pattern source** — `mercury/packages/mercury-ds/project/showcase/library.jsx:8–54`
  (`escapeHtml` · `renderInline` · `splitRow` · `renderMarkdown`). Read-only untracked seed. Line 130
  outputs via `dangerouslySetInnerHTML` — **the banned mechanism (INV-3)**: reimplement the parsing shape
  as React elements; never port the output path, never `escapeHtml` (React text nodes are safe).

## References — Mars's grounding reads (≤3; everything else is IN this brief)

1. `mercury/packages/mercury-ds/project/showcase/library.jsx:8–54` — the seed algorithm.
2. `mercury/apps/showcase/src/lib/storyRender.tsx:118–165` — the `PanelState` union + the entry-keyed
   alive-guarded effect to mirror.
3. `mercury/apps/showcase/src/shell/ComponentPage.tsx` — the stub to replace (50 lines).

**Precondition:** mx.9.2 + mx.9.3 SHIPPED. **Inherited rulings:** B · C · D · E — zero new dependency
(the hand-rolled renderer IS the ruling). **FORK-1 RULED: Arm A** — build order still puts the
renderer/cutter first; the grain (the nested sub-tab row) lands last.

## Requirements (each traced: story ⇠ requirement ⇢ invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R-1 | The compact renderer over the inventoried construct scope (React elements; no innerHTML; no dependency; the fallback law) | S-1 | INV-3, INV-4 |
| R-2 | `section(raw, heading)` on exact-depth `## ` boundaries (`###` never cuts); the four cuts bound to the census heading strings | S-2 | INV-2 |
| R-3 | The Docs panel wired: full Docs + the four views per the ruled grain (**Arm A — nested sub-tabs**) | S-1, S-2 | INV-1 |
| R-4 | Missing-section → explicit empty state (proven on selection/Switch, a real enum-less contract); missing-contract → explicit "no contract" state (probe) | S-2, S-3 | INV-2 |
| R-5 | Negative proofs: no authored `.md` in the app; no hardcoded API table; no `dangerouslySetInnerHTML` | S-1, S-4 | INV-1, INV-3 |
| R-6 | Scope `apps/showcase/src/**`; `package.json` unchanged; barrel byte-identical; transient harness + probe DELETED before ship | S-4 | INV-5 |

## Execution topology (write-ready — the exact files + signatures)

### NEW `mercury/apps/showcase/src/lib/markdown.tsx` — the renderer + the cutter (the only new file)

```tsx
export function renderMarkdown(md: string): ReactNode;
export function section(raw: string, heading: string): string | null;
export const DOC_CUTS: {
  api: readonly string[];      // ["Props"]
  dodont: readonly string[];   // ["The enum language", "Notes"] — contract order
  recipes: readonly string[];  // ["Examples"]
};
```

- **Block pass** (seed `renderMarkdown` shape, `library.jsx:19–54`, over the inventoried scope): strip
  `\r`, split lines; fenced code (``` … ```, literal) → GFM table (a `|`-row whose NEXT line matches
  `/^\s*\|[\s:|-]+\|\s*$/`; `splitRow` = trim outer pipes + `split(/(?<!\\)\|/)` + unescape `\|`) →
  `#{1,3}` headings (inline pass on the text) → flat `-`/`*` list, **each item joining its 1–3-space
  indented continuation lines** (a run of `- item` lines; a following ` {1,3}\S` line appends to the
  current item with a space) → blank line → paragraph with continuation-joining (the seed's stop set,
  minus the constructs out of scope). Any unclaimed line → paragraph (the fallback law).
- **Inline pass** (runs on heading text, list items, table cells, paragraphs): extract `` `code` ``
  spans FIRST as atomic tokens (sentinel placeholders); on the remaining text parse `[text](target)` →
  the xref rule, then `**bold**`, then `*italic*`, **recursing into mark contents and re-substituting
  the code tokens** — bold-around-code (`Table.prompt.md:16`, 34/65 files) and italic spanning a joined
  line (`Button.prompt.md:41–42`) must render. Keys from token position. No `escapeHtml` — text nodes.
- **`section`**: return the raw slice from the line `## <heading>` (exact match after `## `) up to —
  excluding — the next line starting `## ` at exact depth 2 (`### ` does NOT terminate — TabNav), or
  `null` when absent. The slice INCLUDES its own `## <heading>` line (the view renders it).

### EDIT `mercury/apps/showcase/src/shell/ComponentPage.tsx` — the stub → the wired Docs panel

Replace ONLY the docs branch (`ComponentPage.tsx:46`); the Stories branch, the tab row, and the header
stay byte-wise intact. Add a `DocsPanel` (same file or `src/shell/DocsPanel.tsx` — builder's choice)
mirroring the mx.9.3 `StoriesPanel` effect shape (`storyRender.tsx:118–165`):

```tsx
type DocsState =
  | { status: "no-contract" }                       // entry.loadPrompt === undefined — set WITHOUT calling anything
  | { status: "loading" }
  | { status: "ready"; raw: string }
  | { status: "load-error"; message: string };
// effect keyed by `${entry.group}/${entry.name}`, alive-guard, .then(ok, err) — the exact mx.9.3 shape
```

- `ready` → the four views over the ONE `raw`: **Docs** = `renderMarkdown(raw)` whole; **API** =
  the `DOC_CUTS.api` sections; **do/don't** = the `DOC_CUTS.dodont` sections concatenated in contract
  order, each absent section rendering the explicit empty state (`.showcase-md-empty`: "this contract
  has no *{heading}* section"); **recipes** = `DOC_CUTS.recipes`. One fetch, one raw string, four
  selections (INV-2).
- **The view grain: RULED Arm A — a nested sub-tab row inside the Docs tab** (Docs | API | Do/Don't |
  Recipes; body §5 FORK-1). Build the renderer, cutter, state machine, and views first; the grain is the
  last ~30 lines. View selection is `useState` LOCAL to the Docs panel, keyed/reset per entry (e.g. a
  `key={entryKey}` remount or an effect reset); the route JSON, `ROUTE_KEY`, the `Tab` union, and
  `App.tsx` are all UNTOUCHED. The sub-tab row mirrors the page row's `role="tablist"` a11y shape with
  its own additive class (`.showcase-md-subtabs` or sibling) so mx.9.5 can skin the two rows distinctly.
- `no-contract` → an explicit `.showcase-md-empty` "no contract" paragraph (S-3); `loading` /
  `load-error` mirror the mx.9.3 classes' shape (`.showcase-story-loading` / `-load-error` precedent).

### EDIT `mercury/apps/showcase/src/showcase.css` — additive `showcase-md-*` block

New classes only (the existing 24 `showcase-*` rules untouched): `.showcase-md` (container) ·
`.showcase-md-h1/-h2/-h3` · `.showcase-md-p` · `.showcase-md-table` · `.showcase-md-code` ·
`.showcase-md-ul` · `.showcase-md-xref` · `.showcase-md-empty` (+ the ruled grain's chrome, e.g.
`.showcase-docs-views`). `rgb(var(--token))` only (the file's existing idiom — 27 uses, zero raw hex);
code surfaces on `--font-secondary`; never author `.mx-*`.

## The gate ladder (run from `mercury/` — the gate of record, mx.9.2/9.3 precedent)

> ⚠ **NEVER `pnpm --filter "./packages/*"`** — it sweeps `@echo/fx` (fails from HEAD, pre-existing) and
> the untracked `mercury-ds` folder. The gate is the root `@mercury/*`-scoped scripts.

```bash
pnpm run typecheck:mercury                                                # root script, @mercury/* scoped
pnpm run build:mercury
pnpm --filter @mercury/showcase typecheck && pnpm --filter @mercury/showcase build
pnpm run build:apps                                                       # the 3 product apps
# negative greps — ALWAYS --exclude-dir=node_modules (pnpm symlinks workspace packages under apps/*)
find apps/showcase/src -name "*.md"                                       # → empty
grep -rn  --exclude-dir=node_modules "dangerouslySetInnerHTML" apps/showcase/src              # → empty
grep -rnE --exclude-dir=node_modules "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" apps/showcase/src  # → empty
grep -rn  --exclude-dir=node_modules "## Props" apps/showcase/src         # → empty-or-comment (DOC_CUTS holds "Props", never content)
# Director-run: barrel-diff byte-identical; apps/showcase/package.json unchanged; probe + harness deleted.
```

## The transient verify harness (L-mx9.3a — prescribe, capture, DELETE)

vitest ^3 + jsdom ^25 + @testing-library/react ^16 resolve as **ROOT devDeps only** — run from
`mercury/` root, never from the app dir:

```bash
pnpm exec vitest run --config apps/showcase/vitest.transient.config.ts
```

The config is `mergeConfig(<showcase vite.config>, defineConfig({ test: { environment: "jsdom",
include: ["apps/showcase/src/**/*.verify.test.tsx"] } }))` — **include paths ROOT-RELATIVE** (vitest
resolves `include` against the RUN CWD, not the config dir). The harness files
(`vitest.transient.config.ts` + `src/lib/markdown.verify.test.tsx`) are transient: created → evidence
captured into the progress ledger → **DELETED before ship**. The load-bearing assertions (behavioral,
against the REAL raw contracts imported `?raw`):

- `Button.prompt.md`: the Props table renders; the `variant` cell shows literal
  `"primary" | "secondary" | …` (escaped-pipe unescape); the wrapped Composition item is ONE `<li>`
  (continuation-joining); the italic parenthetical renders as `<em>` without literal asterisks;
  the `[Icon](…)` xref renders non-navigating (no `<a href$=".prompt.md">`).
- `Table.prompt.md`: BOTH tables render (the 3-col `Column<Row>` table too); bold-around-code
  (`**\`Column<Row>\` (the cell config):**`) renders `<strong>` containing `<code>`.
- `TabNav.prompt.md`: `section(raw, "Props")` contains the `### TabNavItem` block (exact-depth cut).
- `Switch.prompt.md` (real enum-less): `section(raw, "The enum language") === null`; the do/don't view
  renders `## Notes` + the explicit absent-state.
- `DocsPanel` with a stub entry `{ …, loadPrompt: undefined }`: the "no contract" state renders and
  `loadStories` is not called.

## The K-4 probe method (transient, reverted)

1. Create `mercury/packages/mercury-ui/src/components/<group>/ProbePrompt/ProbePrompt.stories.tsx`
   (minimal CSF: a default `{ component }` + one args story) and **no** `.prompt.md` → the registry
   derives the entry with `loadPrompt` absent (registry.ts:68–73) → observe the Docs tab's explicit
   "no contract" state (dev server or the harness) → **DELETE the folder**;
   `git status --porcelain packages/` must be clean at report.
2. The enum-less empty state is proven on **selection/Switch** — a REAL contract, no fixture.

## The prompt (the decisions this spec fixes; FORK-1 is the one placeholder)

Replace the mx.9.2 Docs stub with the contract surface: a typed, zero-dependency reimplementation of
the seed `renderMarkdown` (React elements, never `innerHTML`) over the inventoried construct scope —
including the four mandatory extensions the inventory forced (list-continuation joining · `*italic*` ·
the sentinel inline pass for bold-around-code · the non-navigating xref rule) and the fallback law (an
unclaimed block renders as a paragraph, never drops) — plus the exact-depth `section(raw, heading)`
cutter binding the four views to the census headings: Docs whole · API `## Props` · do/don't `## The
enum language` + `## Notes` · recipes `## Examples`. A missing section renders an explicit empty state
(prove on selection/Switch); a missing contract renders an explicit "no contract" state (prove via the
ProbePrompt folder, then revert). Mirror the mx.9.3 StoriesPanel effect shape entry-keyed with the
alive-guard. The view grain is RULED Arm A: the nested sub-tab row inside the Docs tab, local state.
Author no doc prose, edit no contract to fit the renderer, add no dependency, touch only
`apps/showcase/src/**` (+ the transient probe/harness, deleted). The corrected ladder green before
reporting; escalate any construct outside the inventory rather than silently dropping content.
