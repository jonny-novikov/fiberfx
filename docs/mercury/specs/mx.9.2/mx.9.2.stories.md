# MX.9.2 · acceptance stories

Given/When/Then for [`mx.9.2.md`](./mx.9.2.md) (the body wins on any disagreement). Connextra form; each
story names the deliverable, the invariant(s), and the epic story it realizes
([`../mx.9/mx.9.stories.md`](../mx.9/mx.9.stories.md)). **Coverage:** K-1 → S-1, S-2; K-2 → S-2, S-3;
K-3 → S-3; K-4 → S-3; K-5 → S-4.

## S-1 · The nav is derived from the real library — the liveness probe (K-1 · epic S-3)

*As a **library maintainer**, I want the showcase nav built from the real `@mercury/ui` tree, so that it
covers the whole surface and never drifts.*

**Given** the running showcase and `src/registry.ts` built from exactly two lazy `import.meta.glob` patterns
over `../../../packages/mercury-ui/src/components/**` (stories modules; prompt files `?raw`),
**when** a reviewer creates a throwaway
`packages/mercury-ui/src/components/foundations/__Probe__/__Probe__.stories.tsx` (a minimal CSF module) and
reloads,
**then** a `__Probe__` entry appears under Foundations with **zero** edit to `apps/showcase/src/**` — and
after deleting the probe folder it disappears the same way. The probe never touches the barrel (`index.ts`
lists component folders explicitly; the probe folder is glob-visible, barrel-invisible).
**And** `grep -c "import.meta.glob" apps/showcase/src/registry.ts` → 2, and the component-name spot-grep over
`registry.ts` is empty.
*(Proves INV-1.)*

## S-2 · Every component appears, grouped and counted (K-1, K-2 · epic S-4)

*As a **design-system browser**, I want every `@mercury/ui` component navigable under its group, so that the
showcase is the comprehensive home the mandate names.*

**Given** the loaded showcase,
**when** the sidebar renders,
**then** every component with a `*.stories.tsx` is listed under its group in the epic-S-4 order
(Foundations · Actions · Inputs · Selection · Data display · Feedback · Overlay · Navigation · Layout),
names sorted within each group, an unknown future group segment appended derived (never dropped),
**and** the sidebar footer's derived total equals
`find packages/mercury-ui/src/components -name "*.stories.tsx" | wc -l` (65 at the 2026-07-02 count — the
number lives in this check, never in the code).
*(Proves INV-2 + INV-1.)*

## S-3 · The shell frames the engine: route, page, stubs — nothing loads (K-2, K-3, K-4)

*As a **Mercury contributor**, I want the shell to navigate and persist without executing any story module,
so that the derivation risk ships isolated from the interpreter risk.*

**Given** the shell,
**when** a viewer selects a component,
**then** the component page opens (group · name header) with a **Stories | Docs** tab bar whose panels are
static stubs naming mx.9.3 / mx.9.4, the selection persists to `mx-showcase.route.v1` and survives a reload,
and the no-selection state renders the Home panel (the relocated mx.9.1 sanity content — components +
swatches still painting).
**And** no `*.stories.tsx` request appears in the dev-server network panel on boot or navigation (the lazy
loaders are stored, never called — MANUAL review enforcement, stated honestly).
*(Proves INV-3 + INV-5.)*

## S-4 · The theme mechanism flips and persists (K-5 · epic S-8, mechanism half)

*As a **design reviewer**, I want a light/dark toggle whose class flip persists, so that the mx.9.5
dual-theme acceptance has a working mechanism to deepen.*

**Given** the topbar toggle,
**when** a viewer switches theme,
**then** `document.documentElement` carries `dark-theme` (respectively `light-theme`) — the canon §0
mechanism — the Home panel's swatches and components repaint, the choice persists to
`mx-showcase.theme.v1`, and a reload boot-applies it before first paint (the `main.tsx` boot line).
**And** `src/showcase.css` styles through `rgb(var(--token))` families only — the raw-hex grep over
`apps/showcase/src/**` finds none.
*(Proves INV-4; the across-the-library dual-theme acceptance is mx.9.5's gate — epic S-8.)*
