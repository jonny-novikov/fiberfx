# MX.9.4 · acceptance stories

Given/When/Then for [`mx.9.4.md`](./mx.9.4.md) (the body wins on any disagreement). **SOLID-FORWARD** —
re-sharpened at this rung's own ship. **Coverage:** K-1, K-3 → S-1; K-2, K-3 → S-2; K-4 → S-3; the gate →
S-4. Epic traceability: S-1 realizes epic **S-6**; S-2 realizes epic **S-7**.

## S-1 · The contract is rendered, never re-authored (K-1, K-3 · epic S-6)

*As an **AAW implementor**, I want the docs rendered from the `.prompt.md` contract, so that the
documentation can never fork from the source.*

**Given** a component page's **Docs** tab,
**when** it awaits the registry's `loadPrompt()` and feeds the raw contract to the compact renderer,
**then** the full contract renders — headings, the Props table, fenced Examples code, lists, inline marks —
content-corresponding to the live file, via React elements (no `dangerouslySetInnerHTML`, no markdown
dependency — Fork E).
**And** the negative proof: `find apps/showcase/src -name "*.md"` is empty and no in-app JSX carries a
per-component API table or doc body (the app authors nothing a contract already owns).
*(Proves INV-1 + INV-3 + INV-4.)*

## S-2 · API, do/don't, and recipes are cuts of the one contract (K-2, K-3 · epic S-7)

*As a **library consumer**, I want the API, do/don't, and recipes surfaces, so that a component is usable
from one trustworthy source.*

**Given** a component whose contract carries the census-verified sections,
**when** the four views present,
**then** **API** = the `## Props` cut, **do/don't** = `## The enum language` + `## Notes`, **recipes** =
`## Examples` — each a selection over the same fetched contract (one parse, four views).
**And** for one of the real **9 contracts lacking `## The enum language`** (the 56/65 census,
2026-07-02), the do/don't view renders `## Notes` plus an explicit absent-state for the enum section —
empty, never invented.
*(Proves INV-2.)*

## S-3 · The absent-contract and probe states are explicit (K-4)

*As a **Mercury maintainer**, I want the no-contract path exercised, so that a story-only folder degrades
loudly-visible instead of breaking the page.*

**Given** a throwaway component folder carrying a story but **no** `.prompt.md`,
**when** its Docs tab opens,
**then** an explicit "no contract" state renders (the page and its Stories tab unaffected) — and the probe
folder is deleted after, `packages/**` clean.
*(Proves INV-1's degraded path + INV-2's empty-state law.)*

## S-4 · The gate closes: zero dependency, scoped, barrel-identical

*As a **Director**, I want the ladder green with the dependency posture intact, so that the doc surface
ships as pure app code over the existing loaders.*

**Given** the built rung,
**when** the ladder runs (packages unchanged · showcase typecheck/build · the 3-app gate · the
consume-down + `dangerouslySetInnerHTML` + authored-docs greps),
**then** every step is green, `apps/showcase/package.json` is unchanged this rung, and the barrel-diff is
empty (Director-run).
*(Proves INV-3 + INV-5.)*
