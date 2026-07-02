# MX.9.4 · acceptance stories

Given/When/Then for [`mx.9.4.md`](./mx.9.4.md) (the body wins on any disagreement). **WRITE-READY** —
re-sharpened 2026-07-02 at this rung's ship (the construct inventory performed; the observables below
name real contract lines). **Coverage:** K-1, K-3 → S-1; K-2, K-3 → S-2; K-4 → S-3; the gate →
S-4. Epic traceability: S-1 realizes epic **S-6**; S-2 realizes epic **S-7**.

## S-1 · The contract is rendered, never re-authored (K-1, K-3 · epic S-6)

*As an **AAW implementor**, I want the docs rendered from the `.prompt.md` contract, so that the
documentation can never fork from the source.*

**Given** a component page's **Docs** tab,
**when** it awaits the registry's `loadPrompt()` and feeds the raw contract to the compact renderer,
**then** the full contract renders — headings, the Props table, fenced Examples code, lists, inline marks —
content-corresponding to the live file, via React elements (no `dangerouslySetInnerHTML`, no markdown
dependency — Fork E). The named fidelity observables (the INV-4 inventory, real lines):
an escaped-pipe cell renders literal pipes (`Button.prompt.md:11` → `"primary" | "secondary" | …`);
a wrapped list item renders as ONE `<li>` (`Button.prompt.md:37–38` — never a stray paragraph);
bold-around-code renders `<strong>` containing `<code>` (`Table.prompt.md:16`); `*italic*` renders
`<em>` with no literal asterisks (`Button.prompt.md:41–42`); Table's SECOND 3-col table renders; a
relative `.prompt.md` link renders as a non-navigating xref span (no dead `<a>`).
**And** the negative proof: `find apps/showcase/src -name "*.md"` is empty and no in-app JSX carries a
per-component API table or doc body (the app authors nothing a contract already owns).
*(Proves INV-1 + INV-3 + INV-4.)*

## S-2 · API, do/don't, and recipes are cuts of the one contract (K-2, K-3 · epic S-7)

*As a **library consumer**, I want the API, do/don't, and recipes surfaces, so that a component is usable
from one trustworthy source.*

**Given** a component whose contract carries the census-verified sections,
**when** the four views present,
**then** **API** = the `## Props` cut, **do/don't** = `## The enum language` + `## Notes`, **recipes** =
`## Examples` — each a selection over the same fetched contract (one parse, four views). The cut is
exact-depth: `TabNav.prompt.md`'s `### TabNavItem` block (line 17) stays INSIDE its `## Props` cut,
never terminates it.
**And** for **selection/Switch** (one of the real 9 contracts lacking `## The enum language` — the
56/65 census, re-confirmed 2026-07-02), the do/don't view renders `## Notes` plus an explicit
absent-state for the enum section — empty, never invented.
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
**when** the ladder runs (the root `@mercury/*`-scoped scripts `typecheck:mercury` / `build:mercury` —
**never** `./packages/*`, which sweeps `@echo/fx` + the untracked `mercury-ds` — · showcase
typecheck/build · `build:apps` · the consume-down + `dangerouslySetInnerHTML` + authored-docs greps,
all with `--exclude-dir=node_modules`),
**then** every step is green, `apps/showcase/package.json` is unchanged this rung, and the barrel-diff is
empty (Director-run).
*(Proves INV-3 + INV-5.)*
