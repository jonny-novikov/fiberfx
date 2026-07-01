# MX.9.3 · acceptance stories

Given/When/Then for [`mx.9.3.md`](./mx.9.3.md) (the body wins on any disagreement). **SOLID-FORWARD** —
re-sharpened at this rung's own ship. **Coverage:** K-1, K-2 → S-1; K-3 → S-2; K-4 → S-3; the gate → S-4.
Epic traceability: all four realize epic **S-5** (the live-stories surface).

## S-1 · A component's live stories render — no Storybook runtime (K-1, K-2 · epic S-5)

*As a **design reviewer**, I want each component's stories rendered in its page, so that the real component
is visible in its states without leaving the showcase.*

**Given** a component page with its **Stories** tab open,
**when** the panel awaits the registry's `loadStories()` and feeds the module to the interpreter,
**then** each named-export story renders — `story.render()` mounted as its own component where present,
else `createElement(meta.component, story.args)` — each in its own error boundary, titled by its export
name, from the live `@mercury/ui` source.
**And** `grep -rnE "from \"@storybook/" apps/showcase/src` is empty, and the story files'
`import type { Meta, StoryObj }` shape is re-proved type-only (erased at build).
*(Proves INV-1 + INV-3 + INV-4.)*

## S-2 · The shim liveness sweep — all 65 modules, positively proved (K-3 · epic S-5)

*As a **Director**, I want every story module loaded through the mx.9.1 shim during verify, so that the
shim's presence gate becomes a liveness proof instead of a letter-satisfying no-op.*

**Given** the whole derived registry (65 story modules at the 2026-07-02 count — DERIVED),
**when** the verify sweep awaits every `loadStories()` and mounts every story,
**then** all 65 resolve and render, the pass evidence names the **11 `storybook/test` value-importers**
individually, `fn()`-produced `args` handlers fire as silent no-ops on interaction, and **zero** play-only
stub (`expect`/`userEvent`/`fireEvent`/`waitFor`/`within`) throws.
**And** if a play-only stub DOES throw, the rung STOPS and escalates (the assumption "the showcase never
runs play" is broken) — the shim and the interpreter are never patched to swallow it.
*(Proves INV-2.)*

## S-3 · The adversarial probes: loud resolution failure, contained render failure (K-4)

*As a **Mercury maintainer**, I want the failure modes exercised on purpose, so that the surface's two
designed behaviors are proven, not assumed.*

**Given** a throwaway story file importing a **7th** name from `storybook/test`,
**when** the dev server or build runs,
**then** vite import-analysis fails **LOUD** (no matching export in the shim) — the mx.9.1-designed
behavior; the recorded remedy is one added shim export via escalation, never an inline workaround.
**And given** a throwaway story whose `render()` throws, **when** its page renders, **then** an inline
error card shows (story name + message) while sibling stories and the shell render on. Both probes are
reverted; `packages/**` is clean after.
*(Proves INV-2 failure-mode + INV-4.)*

## S-4 · The gate closes: lazy, scoped, barrel-identical

*As a **Director**, I want the rung's ladder green with the lazy discipline intact, so that the surface
ships without perturbing the library or the bundle shape.*

**Given** the built rung,
**when** the ladder runs (packages typecheck/build unchanged · showcase typecheck/build · the 3-app gate ·
the consume-down greps · the `\.play` call-grep),
**then** every step is green; navigating between two components loads only the selected module (dev network
panel — the mx.9.2 lazy discipline carried forward); the barrel-diff is empty (Director-run).
*(Proves INV-5 + INV-6.)*
