# MX.1 · The structural rung — extract `@mercury/core`, regroup `@mercury/ui` the Claude-Design way, delete `mercury-ds`

> **Status: ✅ BUILT — gate-green on this machine 2026-06-28 (commit pending).** Implemented per
> this body; the gate is green — 4 packages typecheck + build, 5 apps typecheck + build, the
> barrel-diff is **91 → 103 (additive only, 0 removed/renamed)**, and no `mercury-ds` reference
> remains. The **first build rung of Mercury UI** and the
> floor the Design System Storybook (Movement II, `mx.2`–`mx.5`) stands on: until the foundation is
> a package and the components are one-folder-per-component, a faithful Storybook can't be built
> cleanly.
>
> **Risk: MEDIUM.** No new runtime behavior — the rung **moves** code (hoist the foundation, split
> the aggregates) and deletes a scratch package. The hazard is the **public surface**: if a regroup
> drops or renames an export, every app breaks. The master invariant (the barrel-diff, §3) is the
> guard. No destructive op outside `packages/mercury-ds` (which is generated/ephemeral, `D-2`).
>
> **The decisions this rung rules** (canon §7): `D-3` (core is source-consumed, React a peer dep),
> `D-4` (net-new component group placement). `D-1`/`D-2` are Operator-confirmed.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · acceptance:
[`mx.1.stories.md`](./mx.1.stories.md) · build context: [`mx.1.llms.md`](./mx.1.llms.md).

## 0 · The slice — what mx.1 builds, and why structure first

Mercury's reusable foundation is **trapped inside `@mercury/ui`** (`src/internal`, `src/shared`,
`src/utils`, `cx`/`date`/`types`), yet `@mercury/effector` already reaches across the package line to
use it. And `@mercury/ui`'s components are **flat aggregate files** — `Selection.tsx` holds five
controls, `DataDisplay.tsx` four — which neither match how a design system is browsed nor map onto
story files. A scratch package, `packages/mercury-ds`, holds a generated Claude-Design export plus a
few hand-authored extras.

mx.1 draws the modular line and adopts the Claude-Design layout, in three moves behind a **stable
public barrel**:

1. **Extract `@mercury/core`** — hoist the foundation into its own UI-free package.
2. **Regroup `@mercury/ui`** — `src/components/<group>/<Name>/`, splitting the aggregates.
3. **Salvage + delete `mercury-ds`** — fold in its real source + contracts, then remove it.

Structure first because every Movement II rung assumes the grouped folders exist (a 1:1 home for
`<Name>.stories.tsx`).

## 1 · Goal

Ship the three-package modular topology of the canon §1 — `@mercury/core` (UI-free) below
`@mercury/ui` (Claude-Design grouped) and `@mercury/effector` — with `packages/mercury-ds` deleted,
**all five apps still building**, and `@mercury/ui`'s public export surface **byte-identical** in its
export names. No new component behavior; no token redesign.

## 2 · Scope

### In
- **`@mercury/core`** (new `packages/mercury-core`): the move-inventory of canon §3 (`internal/`,
  `shared/`, `utils/`, `cx.ts`, `date.ts`, `types.ts`, `css.d.ts`) + `package.json` (source-consumed,
  `D-3`) + `tsconfig.json` extending `../../tsconfig.base.json`.
- **`@mercury/ui` regroup**: `src/components/<group>/<Name>/<Name>.tsx` + co-located `<Name>.prompt.md`
  + per-folder `index.ts`; split the 5 aggregates (`Selection`/`Overlay`/`DataDisplay`/`Feedback`/
  `Input`); place standalones; assign the net-new (canon §4.1). Repoint internal imports to
  `@mercury/core`; re-export `cx`/`date`/shared types from `@mercury/core` to hold the barrel.
- **`@mercury/effector`**: repoint its cross-package `date`/util imports to `@mercury/core`; add
  `@mercury/core` to its deps.
- **Salvage** from `mercury-ds`: `mercury-components/{Accordion,Toggle,Pagination}.tsx`
  (+ `mercury-additions.css`) into `@mercury/ui` groups + exported; each generated `<Name>.prompt.md`
  co-located; `handoff/tokens.css` diffed + folded do-no-harm.
- **Delete** `packages/mercury-ds` in full.
- **Wiring**: add the `@mercury/core` vite alias to every app's `vite.config.ts`; confirm
  `.design-sync/config.json`'s output path is not the deleted dir.

### Out
- **The Storybook** (`mx.2`–`mx.5`) — this rung only makes it buildable.
- **Migrating design tokens into `@mercury/core`** — tokens stay in `@mercury/ui` (`D-1`); a deferred
  question.
- **Any component behavior / prop / token change** — pure relocation + regroup.
- **The `.design-sync` pipeline re-alignment** — `mx.5`.
- **Git commit** — the Operator commits when asked.

## 3 · Invariants (runnable checks)

- **INV-1 · The barrel holds.** The set of named exports from `@mercury/ui`'s `src/index.ts` is
  identical before/after (the master invariant, canon §2). Mechanical: diff the export names of
  `git show HEAD:packages/mercury-ui/src/index.ts` against the working tree — empty diff.
- **INV-2 · Packages typecheck + build.** `pnpm -r typecheck` and `pnpm -r build` exit 0 for
  `@mercury/core`, `@mercury/ui`, `@mercury/effector`.
- **INV-3 · Apps build.** `pnpm --filter "./apps/*" build` exits 0 — all five apps resolve packages
  via alias.
- **INV-4 · No cycle, no dangling import.** `@mercury/core` imports nothing in-workspace; no file
  imports a `mercury-ds` path or a moved `@/internal`/`@/utils`/`@/shared` path that no longer
  exists.
- **INV-5 · `mercury-ds` is gone** and the three salvaged components (Accordion, Toggle, Pagination)
  are exported from `@mercury/ui` (net-additive exports, allowed by INV-1 — additions don't break
  consumers; the check is "no removals/renames").

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | `@mercury/core` package (hoisted foundation, source-consumed) | typechecks standalone; exports the §3 inventory; React a peer dep |
| K-2 | `@mercury/ui` regrouped into `<group>/<Name>/` (aggregates split, net-new placed) | INV-1 + INV-2; each component folder has `<Name>.tsx` + `index.ts` (+ `.prompt.md` where salvaged) |
| K-3 | `@mercury/ui` + `@mercury/effector` repointed to `@mercury/core` | INV-2; barrel re-exports `cx`/`date`/shared types |
| K-4 | Salvage absorbed; `packages/mercury-ds` deleted | INV-5; Accordion/Toggle/Pagination exported |
| K-5 | App + tooling wiring (`@mercury/core` alias; design-sync output confirmed) | INV-3; `.design-sync/config.json` not pointing at the deleted dir |

## 5 · The mapping (the heart of K-2)

The component → group table and the aggregate-split notes are the canon's
[§4.1](../../mercury.design.md#41--the-component--group-mapping-verified-against-source). The
build executes that table: each aggregate's exports move into per-component folders under their
group; `Card`/`Table` (standalone, no overlap) drop under `data-display/`; the seven net-new and the
three salvaged components take the groups in `D-4`.

## 6 · Dependencies

- **Hard-gates on:** `mx.0` (the docs floor — met). Nothing else.
- **Unblocks:** all of Movement II (`mx.2`–`mx.5`) — the Storybook host assumes the grouped
  structure + `@mercury/core` resolvable from source.
- **Touches:** `mercury/packages/{mercury-core (new), mercury-ui, mercury-effector, mercury-ds
  (deleted)}`, `mercury/apps/*/vite.config.ts`, `mercury/.design-sync/config.json`.
