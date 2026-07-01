# MX.9.4 · The contract surface — the compact renderer + the four doc cuts

> **Status: 📐 SOLID-FORWARD (authored 2026-07-02 in the mx.9 split; re-sharpened at its own ship).** The
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
  (whether as sub-tabs of the Docs tab or a segmented control inside it — the epic §5.5 grain choice,
  fixed at THIS ship), and the negative-proof greps.
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
- **INV-4 · Rendered fidelity over the D-7 subset.** The renderer covers the constructs the 65 contracts
  actually use — headings, paragraphs, `|`-tables (the Props table), fenced code (the Examples), lists,
  inline code/bold/links — re-inventoried at ship over 2–3 real contracts; the rendered Docs view
  content-corresponds to the file (headings present, table rows complete, code fences intact).
- **INV-5 · Scope + barrel.** The diff is `apps/showcase/src/**` only; `packages/**` untouched (no
  contract is edited to fit the renderer — a renderer gap is a renderer fix); barrel byte-identical;
  consume-down greps empty.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **compact markdown renderer** (`src/lib/markdown.tsx` or sibling) — typed reimplementation of the bundle `renderMarkdown` pattern over the D-7 construct subset; React elements, no HTML injection | S-1; INV-3, INV-4 |
| K-2 | The **section cutter** — `section(raw, heading)` on `\n## ` boundaries; the four cut definitions bound to the census-verified heading strings (`## Props` · `## The enum language` · `## Notes` · `## Examples`) | S-2; INV-2 |
| K-3 | The **Docs panel wired** — the mx.9.2 stub replaced: `loadPrompt()` awaited (absent → the "no contract" state), the four views presented (sub-tab vs segmented control fixed at ship), Docs = full render | S-1, S-2; INV-1 |
| K-4 | The **negative proofs** — the no-authored-docs greps + the enum-less contract's empty-state verification (one of the real 9) + a probe folder with a story but no prompt showing the "no contract" state (revert) | S-3; INV-1, INV-2 |

## 5 · The method (build order)

1. **Inventory the construct subset at ship** — re-grep 2–3 real contracts (Button + one table-heavy +
   one enum-less of the 9) for the constructs used; fix the renderer's scope to that inventory.
2. **Write the renderer + the cutter** (K-1, K-2).
3. **Wire the Docs panel** (K-3) — fix the four-view presentation grain (epic §5.5) at ship.
4. **Run the negative proofs** (K-4) and revert the probe.
5. **Run the gate ladder** (brief §Gate); Director re-runs + barrel-diff.

## 6 · Dependencies

- **Hard-gates on:** [mx.9.2](../mx.9.2/mx.9.2.md) (the `loadPrompt` loaders + the Docs stub).
  Independent of mx.9.3.
- **Unblocks:** mx.9.5 (the closer's doc-source-of-truth adversarial probe runs over THIS surface).
- **Touches:** `mercury/apps/showcase/src/**` only (probe transiently excepted, reverted).

> **Framing (propagate):** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. Each surface is a contract; acceptance is at the boundary.
