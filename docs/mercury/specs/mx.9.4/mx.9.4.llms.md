# MX.9.4 · build context (the agent brief)

Build context for [`mx.9.4.md`](./mx.9.4.md) (authoritative body) + [`mx.9.4.stories.md`](./mx.9.4.stories.md).
The body wins on any disagreement. **SOLID-FORWARD** — re-sharpened at the rung's own ship; the construct
inventory below is the SHIP-TIME step, deliberately not performed at authoring (2026-07-02). What IS
authoring-time verified: the section-heading census.

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state
> verbs; no first-person narration. State each surface as a contract.

## Grounded facts (verified 2026-07-02 — cite, do not re-derive)

- **The D-7 heading census over all 65 contracts:** `## Props` **65/65** · `## Notes` **65/65** ·
  `## Examples` **65/65** · `## Composition` **65/65** · `## The enum language` **56/65**. The exemplar
  `actions/Button/Button.prompt.md` heading lines: `# Button — …` (1) · `## Props` (7) ·
  `## The enum language` (21) · `## Composition` (35) · `## Examples` (44) · `## Notes` (67).
- **The four cuts** (epic §5.5): Docs = the whole contract · API = `## Props` · do/don't =
  `## The enum language` + `## Notes` · recipes = `## Examples`. `## Composition` renders inside the full
  Docs view (it is not a named cut).
- **The loader** — the mx.9.2 registry's `loadPrompt?: () => Promise<string>` (lazy `?raw`, absent when no
  sibling `.prompt.md`).

## References — read at THIS rung's ship (the re-sharpen list)

1. **This brief + the body.**
2. **The pattern source** — `mercury/packages/mercury-ds/project/showcase/library.jsx`, the
   `renderMarkdown` function only (read-only untracked seed; reimplement typed, never port verbatim).
3. **2–3 real contracts** for the construct inventory — `Button.prompt.md` + one table-heavy + one of the
   9 enum-less (locate at ship: `grep -L "^## The enum language" packages/mercury-ui/src/components/*/*/*.prompt.md`).
4. The contract format note [`../../contracts.md`](../../contracts.md) (`D-7`) — the six-section shape.

**Precondition:** mx.9.2 SHIPPED. Independent of mx.9.3. **Inherited rulings:** B · C · D · E — zero new
dependency (the hand-rolled renderer IS the ruling).

## Requirements (each traced: story ⇠ requirement ⇢ invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R-1 | The compact renderer over the D-7 construct subset (React elements; no innerHTML; no dependency) | S-1 | INV-3, INV-4 |
| R-2 | `section(raw, heading)` on `\n## ` boundaries; the four cuts bound to the census heading strings | S-2 | INV-2 |
| R-3 | The Docs panel wired: full Docs + the four views; the presentation grain (sub-tabs vs segmented) fixed at ship | S-1, S-2 | INV-1 |
| R-4 | Missing-section → explicit empty state (proven on a real enum-less contract); missing-contract → explicit "no contract" state (probe) | S-2, S-3 | INV-2 |
| R-5 | Negative proofs: no authored `.md` in the app; no hardcoded API table; no `dangerouslySetInnerHTML` | S-1, S-4 | INV-1, INV-3 |
| R-6 | Scope `apps/showcase/src/**`; `package.json` unchanged; barrel byte-identical | S-4 | INV-5 |

## Execution topology (shape, not bytes — re-sharpened at ship)

- **NEW** `src/lib/markdown.tsx` — the renderer (block-level pass: `## `/`### ` headings · `|`-tables ·
  ``` fences · `- ` lists · paragraphs; inline pass: `code` · **bold** · [links]) + `section(raw, heading)`.
- **EDIT** `src/shell/ComponentPage.tsx` — the Docs stub → the wired panel with the four views (Stories
  panel untouched — mx.9.3's surface, whichever ships first; the two edits are disjoint stub
  replacements).
- **The probe** — a transient story-only folder under `packages/mercury-ui/src/components/<group>/`
  (create → observe the "no contract" state → DELETE; Director re-verifies `packages/**` clean).

## The gate ladder (run from `mercury/` — NEVER `pnpm -r`)

```bash
pnpm --filter "./packages/*" typecheck && pnpm --filter "./packages/*" build   # unchanged
pnpm --filter @mercury/showcase typecheck && pnpm --filter @mercury/showcase build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build                  # 3 product apps
find apps/showcase/src -name "*.md"                                            # → empty
grep -rn "dangerouslySetInnerHTML" apps/showcase/src                           # → empty
grep -rnE "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" apps/showcase  # → empty
# Director-run: barrel-diff byte-identical; app package.json unchanged this rung;
# the enum-less empty-state + no-contract probe verified rendered.
```

## The prompt (the decisions this spec fixes; the ship re-sharpens the rest)

Replace the mx.9.2 Docs stub with the contract surface: a typed, zero-dependency reimplementation of the
bundle `renderMarkdown` pattern (React elements, never `innerHTML`) over the construct subset the real 65
contracts use (inventoried at ship), plus a pure `section(raw, heading)` cutter binding the four views to
the census-verified headings — Docs whole · API `## Props` · do/don't `## The enum language` + `## Notes` ·
recipes `## Examples`. A missing section renders an explicit empty state (prove it on one of the real 9
enum-less contracts); a missing contract renders an explicit "no contract" state (prove via a transient
probe, then revert). Author no doc prose, edit no contract to fit the renderer, add no dependency. Touch
only `apps/showcase/src/**`; the ladder green before reporting; escalate any construct the renderer cannot
cover rather than silently dropping content.
