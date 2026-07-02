# MX.9.4 · The contract surface — the compact renderer + the four doc cuts

> **Status: ✅ BUILT (gate-green 2026-07-02 via `/mercury-ship mx.9.4`; Trio — Venus ship-time
> re-sharpen (the construct inventory over all 65 contracts KILLED five seed assumptions) → FORK-1
> RULED Arm A (Operator, via AskUserQuestion) → Mars pass-1 clean → Director independent verify
> (the 8-witness corpus sweep + a cutter mutation net-zero); the harden pass collapsed; as-built
> record §7).** The
> fourth sub-rung of the [`../mx.9/mx.9.md`](../mx.9/mx.9.md) SUB-EPIC — **hard-gates on
> [mx.9.2](../mx.9.2/mx.9.2.md)** (the registry's `loadPrompt` loaders + the Docs stub it fills);
> independent of mx.9.3. mx.9.4 lands the epic's K-4: the `.prompt.md` contract rendered live (the ported
> hand-rolled compact markdown renderer — Fork E RULED, zero dependency) and the **Docs / API / do-don't /
> recipes** surfaces as **cuts of that one rendered contract** — never re-authored prose (epic INV-5, the
> doc-source-of-truth law).
>
> **Risk: NORMAL · formation Trio.** The Operator may override at ship. **Inherited rulings (2026-07-02,
> epic §7 — closed):** B · C · D · E.

Parent epic: [`../mx.9/mx.9.md`](../mx.9/mx.9.md) · prior rung: [`../mx.9.2/mx.9.2.md`](../mx.9.2/mx.9.2.md)
· the contract law: [`../../contracts.md`](../../contracts.md) (`D-7`) · canon:
[`../../mercury.design.md`](../../mercury.design.md) · acceptance:
[`mx.9.4.stories.md`](./mx.9.4.stories.md) · build context: [`mx.9.4.llms.md`](./mx.9.4.llms.md).

## 0 · The slice

The epic's K-4 realizing epic S-6 + S-7. The mx.9.2 Docs stub becomes live: the selected component's
`<Name>.prompt.md` (the registry's lazy `?raw` `loadPrompt` loader — first invoked HERE) renders as
markdown through a compact hand-rolled renderer (the bundle `library.jsx` `renderMarkdown` pattern,
reimplemented typed, building React elements — never `innerHTML`). The four doc surfaces are **section
cuts** of that one contract. **The cut boundaries are grounded in the real D-7 shape (heading census over
all 65 contracts, 2026-07-02):** `## Props` · `## Notes` · `## Examples` · `## Composition` appear in
**65/65**; `## The enum language` in **56/65** — so the missing-section rule (render EMPTY, never invent)
is a live case for 9 contracts, not an edge hypothetical.

## 1 · Goal

A component page's Docs tab renders its full contract; the **API** surface is the `## Props` cut, the
**do/don't** surface is `## The enum language` + `## Notes` (with an explicit absent-state for the 9
contracts lacking the enum section), the **recipes** surface is the `## Examples` cut — every surface a
selection over the ONE fetched contract, byte-derived from the live file. A contract-less entry (possible
only for a probe/future story-only folder) shows an explicit "no contract" state. The app authors **no**
per-component doc prose (the negative grep holds), pulls **no** markdown dependency (Fork E), and touches
only `apps/showcase/src/**`.

## 2 · Rationale (5W)

- **Why.** The doc-source-of-truth law (epic INV-5): documentation that IS the contract, rendered, can
  never fork from it — the copy is the drift surface the law forbids. The four mandate surfaces (API ·
  do/don't · recipes · documentation) come free as cuts once the renderer exists.
- **What.** The compact renderer, the section-cut function, the wired Docs panel with its four views
  (the presentation grain — **FORK-1**, §5 below; the epic §5 step-5 choice, `mx.9.md:231`, ruled by
  the Operator at THIS ship), and the negative-proof greps.
- **Who.** *Built by* the implementor to [`mx.9.4.llms.md`](./mx.9.4.llms.md); *consumed by* library
  users and design/coding agents reading the API; mx.9.5 skins it.
- **When.** After mx.9.2; independent of mx.9.3 (different stub, different loader). Before mx.9.5.
- **Where.** `mercury/apps/showcase/src/**` only.

## 3 · Invariants (runnable checks)

- **INV-1 · Render the contract, never re-author it** (epic INV-5). Every doc surface derives from the
  `?raw`-loaded `<Name>.prompt.md` at render time. Checks: `find apps/showcase/src -name "*.md"` → empty
  (the app authors no markdown); no JSX carries a hardcoded per-component prop table or doc body (review +
  a spot-grep for contract-like literals, e.g. `grep -rn "## Props" apps/showcase/src` hits only the
  cut-boundary constant, never content).
- **INV-2 · The four cuts are selections of ONE parse.** A pure `section(raw, heading)` (split on `\n## `
  boundaries) feeds: Docs = the whole contract; API = `## Props`; do/don't = `## The enum language` +
  `## Notes`; recipes = `## Examples`. A missing section renders an explicit empty state ("this contract
  has no *{heading}* section") — **never** invented content. The 56/65 enum-language census makes this a
  first-class rendered state, verified on a real enum-less contract at ship.
- **INV-3 · Zero dependency, zero injection** (Fork E RULED). The renderer is hand-rolled and builds
  React elements — no `react-markdown`, no `dangerouslySetInnerHTML`. Checks: `apps/showcase/package.json`
  diff empty this rung; `grep -rn "dangerouslySetInnerHTML" apps/showcase/src` → empty.
- **INV-4 · Rendered fidelity over the D-7 subset — the inventory is PERFORMED (2026-07-02, all 65
  contracts; the table is pinned in the brief).** The scope: `#`/`##`/`###` headings (`###` in exactly
  one file, TabNav) · GFM tables with **escaped `\|` cells** (50/65 files — split on `(?<!\\)\|` +
  unescape) · fenced code (info: none/`tsx`) · flat `-` lists **with 1–3-space continuation lines
  joined into the item** (475 lines across 65/65 files — the seed splits them into stray paragraphs) ·
  paragraphs · inline `code`/`**bold**`/`*italic*`/links, where **bold wraps code in 34/65 files** (the
  inline pass extracts code spans as atomic tokens and recurses into mark contents). Ordered/nested
  lists, blockquotes, hr, images: **0/65 — out of scope**, covered by the **fallback law**: any block
  no recognizer claims renders as a paragraph — content always reaches the DOM, never silently dropped.
  **The xref rule:** the corpus's links are 100% relative `.prompt.md` cross-links (0 http) targeting
  source paths the SPA does not serve — a relative link renders as a non-navigating styled span
  (`title` = the target); an absolute `http(s)` link renders a real `<a target="_blank">`. The rendered
  Docs view content-corresponds to the file (headings present, table rows complete, fences intact).
- **INV-5 · Scope + barrel.** The diff is `apps/showcase/src/**` only; `packages/**` untouched (no
  contract is edited to fit the renderer — a renderer gap is a renderer fix); barrel byte-identical;
  consume-down greps empty.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **compact markdown renderer** (`src/lib/markdown.tsx`) — typed reimplementation of the bundle `renderMarkdown` pattern over the inventoried construct scope (INV-4); React elements, no HTML injection | S-1; INV-3, INV-4 |
| K-2 | The **section cutter** — `section(raw, heading)` on `\n## ` boundaries; the four cut definitions bound to the census-verified heading strings (`## Props` · `## The enum language` · `## Notes` · `## Examples`) | S-2; INV-2 |
| K-3 | The **Docs panel wired** — the mx.9.2 stub replaced: `loadPrompt()` awaited entry-keyed with the alive-guard (absent → the "no contract" state), the four views presented per the **FORK-1** ruled grain, Docs = full render | S-1, S-2; INV-1 |
| K-4 | The **negative proofs** — the no-authored-docs greps + the enum-less contract's empty-state verification (one of the real 9) + a probe folder with a story but no prompt showing the "no contract" state (revert) | S-3; INV-1, INV-2 |

## 5 · The method (build order)

1. **Inventory the construct subset at ship** — ✅ **PERFORMED 2026-07-02**: mechanical greps over ALL
   65 contracts + three end-to-end reads (Button · the table-heavy Table · the enum-less Switch). The
   pinned table is in the brief; the scope + the four forced extensions (continuation-joining ·
   `*italic*` · the sentinel inline pass for bold-around-code · the xref rule) are in INV-4.
2. **Write the renderer + the cutter** (K-1, K-2).
3. **Wire the Docs panel** (K-3) — the four-view presentation grain is **FORK-1** (below), **RULED Arm A**
   at ship; the build lands it as the last seam (the brief carries the filled Arm-A wiring).
4. **Run the negative proofs** (K-4) and revert the probe.
5. **Run the gate ladder** (brief §Gate); Director re-runs + barrel-diff.

### FORK-1 · the four-view grain — **RULED (Operator, 2026-07-02, via AskUserQuestion): Arm A**

Epic `mx.9.md:231` (§5 step 5): *"Whether the four views are sub-tabs of one Docs page or top-level — a
§7-A grain choice, ruled at ship."* The persisted route (`App.tsx:8`, `mx-showcase.route.v1`, JSON
`{ group, name, tab }`) and mx.9.5 (the skin rung inherits this grain) both interact.

- **Arm A — a nested sub-tab row inside the Docs tab** (Docs | API | Do/Don't | Recipes). Stories keeps
  top billing; the doc surfaces read as one family. Sub-view state is local (reset per entry), NOT
  persisted — `App.tsx` untouched.
- **Arm B — the four views as top-level tabs beside Stories** (5-tab row). Every surface is one click;
  persistence comes free (the `tab` field widens); but the `Tab` union + `readRoute` in `App.tsx` are
  touched, the row grows 2→5, and mx.9.5 skins the wider grain.
- **Arm C — a segmented control in the Docs panel header.** Visually distinct from the page tabs
  (avoids tab-inside-tab); same state posture as Arm A; hand-rolled chrome per the shell convention
  (the shell never composes the `@mercury/ui` components it demonstrates).

**RULED: Arm A** — a nested sub-tab row inside the Docs tab (Docs | API | Do/Don't | Recipes); sub-view
state local per entry, the persisted route (`mx-showcase.route.v1`) and `App.tsx` untouched; mx.9.5 owes
the two tab rows distinct skinning. In the same ruling the Operator **confirmed the xref rule** (§3
INV-4 / the KILLED-2 fix): relative `.prompt.md` links render as non-navigating spans (title = target);
only `http(s)` links render as real anchors; in-app cross-navigation is a possible later rung.

## 6 · Dependencies

- **Hard-gates on:** [mx.9.2](../mx.9.2/mx.9.2.md) (the `loadPrompt` loaders + the Docs stub).
  Independent of mx.9.3.
- **Unblocks:** mx.9.5 (the closer's doc-source-of-truth adversarial probe runs over THIS surface).
- **Touches:** `mercury/apps/showcase/src/**` only (probe transiently excepted, reverted).

## 7 · As-built record (2026-07-02)

Shipped via `/mercury-ship mx.9.4` (Trio; pass-1 clean, the harden pass collapsed). The diff footprint,
exactly four files in `apps/showcase/src/**`: **NEW** `lib/markdown.tsx` (303 lines — `renderMarkdown`
building React elements over the inventoried construct scope with the sentinel inline pass (code atomic →
links → bold → italic, marks recursing, never into code), fence/GFM-table/h1–h3/flat-list block pass with
the 1–3-space continuation-JOINING law, the paragraph fallback (INV-4), `section(raw, heading)` exact-depth
cutter, the census-bound `DOC_CUTS`), **NEW** `shell/DocsPanel.tsx` (124 lines — the 4-state union, keyed
remount per entry, the Arm-A nested sub-tab row on `.showcase-md-subtabs`, one fetch four selections),
**EDIT** `shell/ComponentPage.tsx` (+4/−2, the stub → `<DocsPanel/>`; Stories byte-untouched), **EDIT**
`showcase.css` (+132 pure-append `showcase-md-*`, `rgb(var(--token))` only). `packages/**` untouched,
barrel byte-identical, `package.json` unchanged (Fork E held).

**Evidence.** Mars 13/13 behavioral witnesses on real raw contracts + 2 self-mutations (continuation-join,
naive pipe-split) both caught. Director independent: the corpus fidelity sweep over ALL 65 contracts with
raw-derived expectations (h1/h2/h3/table/pre/li counts outside fences; sentinel/pipe/bold leakage checks
outside code; every continuation fragment canonicalized-contained in a `li`), the cutter law (Props 65/65
slice-includes-heading; enum language null for EXACTLY the census 9), TabNav exact-depth (`###` inside the
Props slice, 2 tables), the mask-first synthetic, the xref span/anchor split, Switch's real enum-less
empty state, the single-fetch law, the loaderless no-contract state — 8/8; the LAW-1a cutter mutation
(`### ` terminating sections) caught by the TabNav witness, reverted net-zero (content-verified — the file
is untracked, so `git diff` cannot witness the revert). Both gates green (`typecheck:mercury` ·
`build:mercury` · `@mercury/showcase` · `build:apps` + the negative greps); the showcase build code-splits
each contract into its own lazy `?raw` chunk.

**Noted residuals.** (1) Five contracts carry `\|` inside code spans in PROSE (Stat:19, Alert:18,
PasswordStrength:16, Progress:17, Label:23) — an authoring artifact rendered literally, CommonMark-faithful
(GitHub renders the same); a contract-hygiene candidate for a later rung, NOT a renderer gap (INV-5 forbade
editing contracts to fit). (2) The `:5176` visual pass of the four views stays a manual residual, per the
mx.9.3 precedent. **Craft guard (twice-proven this rung):** authoring the U+0000 sentinel via file-write
tooling lands LITERAL NUL bytes — always `perl -ne 'print if /\x00/'` after writing, and spell the escape
as source text.

> **Framing (propagate):** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. Each surface is a contract; acceptance is at the boundary.
