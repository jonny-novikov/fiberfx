# MX.1 — stories (the structural rung)

The acceptance face of [`mx.1.md`](./mx.1.md). Each story is Given/When/Then with the invariant it
exercises. "The build" = the `mx.1` implementation; "a consumer" = one of the five apps or a
downstream importer.

## US1 — the public surface never moves under a consumer

*As a consumer of `@mercury/ui`, I want the regroup + core extraction to be invisible, so my imports
keep working untouched.*

- **Given** an app importing `{ Button, Input, Card, Alert, useTheme-adjacent types }` from
  `@mercury/ui` before mx.1,
- **When** the build extracts `@mercury/core` and regroups every component into `<group>/<Name>/`,
- **Then** the app's imports resolve unchanged — every name previously exported from
  `@mercury/ui/src/index.ts` is still exported, same name + same type.
- **Exercises:** INV-1 (barrel-diff empty for removals/renames) · INV-3 (apps build).

## US2 — the foundation becomes a package, by moving not rewriting

*As a maintainer, I want `@mercury/core` to be the existing `internal`/`shared`/`utils`/`cx`/`date`/
`types` hoisted verbatim, so behavior is identical and review is a move-diff.*

- **Given** the foundation living in `mercury-ui/src/{internal,shared,utils}` + `cx.ts`/`date.ts`/
  `types.ts`/`css.d.ts`,
- **When** the build creates `packages/mercury-core` and moves those files there,
- **Then** `@mercury/core` typechecks standalone, ships them as its public surface, declares React a
  **peer** dependency (for the headless hooks `useId`/`use-arrow-navigation`), and imports nothing
  in-workspace.
- **Exercises:** K-1 · INV-2 · INV-4 (no cycle).

## US3 — `@mercury/ui` re-exports the moved symbols to hold the barrel

*As a consumer importing `cx` or a `date` helper or a shared type from `@mercury/ui`, I want it to
still come from `@mercury/ui`, so nothing breaks even though the symbol now lives in core.*

- **Given** `cx`, the `date` utilities, and the shared types were exported from `@mercury/ui`,
- **When** they move to `@mercury/core`,
- **Then** `@mercury/ui`'s barrel **re-exports** them from `@mercury/core` — the symbol changes
  house, the surface does not.
- **Exercises:** K-3 · INV-1.

## US4 — the aggregates split into per-component folders

*As a design-system author, I want one folder per component grouped by category, so each component
has a home for its source, its contract, and (next) its story.*

- **Given** `Selection.tsx` (Checkbox/Radio/Segmented/Slider/Switch), `Overlay.tsx` (Modal/Tooltip),
  `DataDisplay.tsx` (Avatar/Badge/Chip/Tag), `Feedback.tsx` (Alert/Progress), `Input.tsx`
  (Input/Textarea/Search),
- **When** the build regroups,
- **Then** each becomes `src/components/<group>/<Name>/<Name>.tsx` + `index.ts` (+ `.prompt.md` where
  a contract was salvaged), under the canon §4.1 groups, and `Card`/`Table` (standalone, no overlap)
  land under `data-display/`.
- **Exercises:** K-2 · INV-1 (exports preserved through the split).

## US5 — the salvage is absorbed, then the scratch package is deleted

*As the Operator, I want the real source out of `mercury-ds` folded into `@mercury/ui` and the
ephemeral package gone, so there's one source of truth.*

- **Given** `mercury-ds/mercury-components/{Accordion,Toggle,Pagination}.tsx` (the only runtime
  source; everything in `mercury-ds/components/` is a generated stub),
- **When** the build moves them into their `@mercury/ui` groups, exports them, co-locates the
  generated `.prompt.md` contracts, folds in any newer `handoff/tokens.css` tokens, and **deletes
  `packages/mercury-ds`**,
- **Then** Accordion/Toggle/Pagination are exported from `@mercury/ui`, no file imports a
  `mercury-ds` path, and the package directory is gone.
- **Exercises:** K-4 · INV-5 · INV-4 (no dangling import).

## US6 — every app and the tooling still resolve

*As a developer running the monorepo, I want `pnpm dev`/`build` to work across all apps with the new
package, so the source-resolution convention is intact.*

- **Given** apps resolve `@mercury/ui`/`@mercury/effector` from source via vite alias,
- **When** `@mercury/core` is added and `mercury-ds` removed,
- **Then** every app's `vite.config.ts` also aliases `@mercury/core` to its source, `pnpm --filter
  "./apps/*" build` exits 0, and `.design-sync/config.json` does not point its output at the deleted
  `mercury-ds` dir.
- **Exercises:** K-5 · INV-3.

## Coverage

| Deliverable | Stories |
|---|---|
| K-1 `@mercury/core` package | US2 |
| K-2 `@mercury/ui` regrouped | US4 |
| K-3 repointed + barrel re-exports | US3 |
| K-4 salvage absorbed + `mercury-ds` deleted | US5 |
| K-5 app + tooling wiring | US6 |
| INV-1 barrel holds | US1, US3, US4 |
| INV-2 packages typecheck/build | US2 |
| INV-3 apps build | US1, US6 |
| INV-4 no cycle / no dangling | US2, US5 |
| INV-5 `mercury-ds` gone | US5 |
