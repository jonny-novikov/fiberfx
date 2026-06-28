# @mercury/core — the UI-free foundation

The base of Mercury: headless behavior + helpers, **zero components, zero JSX**. Source-consumed
(`exports`/`main`/`types` → `./src/index.ts`, `private: true`) — `@mercury/ui`, `@mercury/effector`,
the apps, and the Storybook all resolve it from source. React is a **peer** dep (for the headless
hooks); `@internationalized/date` is a runtime dep (the date wrappers).

See the program CLAUDE.md ([`../../CLAUDE.md`]) for the AAW loop + the standing laws.

## What lives here

`src/internal/` (focus · `use-arrow-navigation` · `use-id` · `get-directional-keys` · kbd · dom ·
math · clamp · debounce · `date-time/` …), `src/shared/` (the curated reuse barrel — the
`Without`/`WithChildren`/`WithElementRef` type kit, `mergeProps`, value types like `Selected`/
`Orientation`/`Direction`), `src/utils/` (clsx · merge-props · events · style · strings · …), and the
top-level `cx.ts` · `date.ts` · `types.ts`. The moved files reference each other via the
`@/* → ./src/*` path alias kept in `tsconfig.json`.

## Rules

- **The public barrel is minimal (`D-5`).** `src/index.ts` exports `cx`/`ClassValue` + the `date`
  formatters — exactly what crosses into `@mercury/ui`'s public surface. The deeper foundation stays
  as files, surfaced explicitly only when a consumer needs it. **Do not** widen the barrel to dump
  all of `internal/`.
- **No in-workspace dependency, no cycle.** core imports nothing from `@mercury/ui` /
  `@mercury/effector`. If you reach upward, the layering is wrong.
- **Boundary imports must be relative.** An `@/` import resolves *inside* core (the path alias), but
  anything a UI/effector consumer pulls through the barrel must be **relative** — apps have no `@`
  alias, and vite would resolve `@/` against the wrong root (the mx.1 landmine that only tree-shaking
  hid).
- `verbatimModuleSyntax` + `noUncheckedIndexedAccess` are on (base tsconfig) — keep `import type` for
  type-only imports; guard every index read.

## Add a util / hook

Drop it under the right `src/` subtree; export it from `src/index.ts` **only if** a UI component needs
it across the package boundary — otherwise keep it internal and import it relative within core. Gate:
`pnpm --filter @mercury/core typecheck`.
