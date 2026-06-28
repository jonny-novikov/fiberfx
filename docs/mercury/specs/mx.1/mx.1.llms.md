# MX.1 — build context (for the implementor)

Working notes for building [`mx.1.md`](./mx.1.md). Exact paths, the move recipe, the gate, the
gotchas. Root = `mercury/` (the pnpm workspace). Run `pnpm` from there.

## Ground facts (re-probe before trusting)

- Workspace globs (`mercury/pnpm-workspace.yaml`): `packages/*`, `apps/*`,
  `codemojex-node/packages/*`, `codemojex-node/apps/*`. Adding `packages/mercury-core` needs **no**
  glob edit.
- `mercury/tsconfig.base.json`: `target ES2024`, `module ESNext`, `moduleResolution Bundler`,
  `jsx react-jsx`, `strict`, **`noUncheckedIndexedAccess`**, `verbatimModuleSyntax`, `declaration`.
  Every package `tsconfig.json` extends it.
- `@mercury/ui` (`packages/mercury-ui/package.json`): `v2.4.0`, dist build
  (`vite build && tsc -p tsconfig.build.json`), `exports`: `.` → `dist/mercury-ui.js`, `./styles.css`,
  `./tokens.css`. Peer deps react/react-dom. tsconfig paths: `@/*` and `$lib/*` → `./src/*`.
- `@mercury/effector` (`packages/mercury-effector/package.json`): peer-deps `@mercury/ui workspace:*`
  + effector/effector-react/react; resolves `@mercury/ui` from source for typecheck, dist for build.
- Apps alias packages to **source** in `apps/*/vite.config.ts`, e.g.
  `"@mercury/ui": resolve(__dirname, "../../packages/mercury-ui/src/index.ts")`. **Five apps:**
  `catalogue`, `docs`, `echomq`, `mobile`, `showcase`.
- `@echo/core` (`packages/echo-core`) is the **source-consumed pattern to mirror** for `D-3`:
  `"exports": { ".": "./src/index.ts" }`, `main`/`types` → `./src/index.ts`, `"private": true`.

## The move recipe

### Step 1 — `@mercury/core` (move, don't rewrite)
- `git mv packages/mercury-ui/src/{internal,shared,utils} packages/mercury-core/src/` and the four
  files `cx.ts`, `date.ts`, `types.ts`, `css.d.ts`. Use `git mv` so history + the LAW-4 R100 rename
  survives.
- Author `packages/mercury-core/src/index.ts` — a barrel re-exporting the public foundation
  (mirror what `mercury-ui/src/index.ts` exported: `cx`/`ClassValue`, `* from ./date`, and the
  shared types). Keep `internal/` mostly internal; export from `shared/` what was public.
- `packages/mercury-core/package.json` (source-consumed, `D-3`): `@mercury/core`, `"type":"module"`,
  `"private": true`, `exports`/`main`/`types` → `./src/index.ts`, React + react-dom as
  **peerDependencies** (the headless hooks), `@internationalized/date` if `date.ts` needs it (check
  the import), devDeps `@types/react`, `csstype`, `typescript`.
- `packages/mercury-core/tsconfig.json`: extend `../../tsconfig.base.json`; `baseUrl: "."`,
  `paths { "@/*": ["./src/*"] }` (the moved files use `@/...` imports — keep the alias so they
  resolve unchanged inside core).

### Step 2 — repoint `@mercury/ui`
- Inside `mercury-ui/src`, the moved files were referenced via `@/internal`, `@/utils`, `@/shared`,
  `./cx`, `./date`, `./types`. Repoint the **remaining** `@mercury/ui` files to `@mercury/core`
  (e.g. `import { cx } from "@mercury/core"`, `import { mergeProps, useId } from "@mercury/core"`).
  The `@/*` path now resolves only to what's left in `mercury-ui/src`.
- `mercury-ui/src/index.ts` barrel: **re-export** `cx`/`ClassValue` and `* from`-date and the shared
  types **from `@mercury/core`** so the public names are unchanged (INV-1). Keep `import
  "./styles/index.css"` (tokens stay here).
- `mercury-ui/package.json`: add `"@mercury/core": "workspace:*"` to deps.

### Step 3 — regroup the components (canon §4.1)
- For each group folder `src/components/<group>/`, create `<Name>/<Name>.tsx` + `<Name>/index.ts`.
- **Split the aggregates** — move each named component out of `Selection.tsx`/`Overlay.tsx`/
  `DataDisplay.tsx`/`Feedback.tsx`/`Input.tsx` into its own `<Name>.tsx`; share any common
  helper via a group-local module or `@mercury/core`. Standalones (`Button`, `Card`, `Table`,
  `Icon`, `Tabs`, `AuthCode`, `Select`) move into `<group>/<Name>/`.
- Net-new (Link, Divider, PasswordStrength, Stat, Chart, Checklist, AuthLayout) → their groups
  (`D-4`). Update `src/index.ts` to re-export from the new folders — **same export names**.
- Co-locate `<Name>.prompt.md` beside each component (port from
  `packages/mercury-ds/components/<group>/<Name>/<Name>.prompt.md` where it exists).

### Step 4 — `@mercury/effector`
- Repoint its `@mercury/ui` `date`/util imports to `@mercury/core`; add `"@mercury/core":
  "workspace:*"` to its deps. It still peer-deps `@mercury/ui` for the `Toaster`→`Alert` usage.

### Step 5 — salvage + delete `mercury-ds`
- `git mv packages/mercury-ds/mercury-components/{Accordion,Toggle,Pagination}.tsx` into their
  `@mercury/ui` groups (`navigation/`, `selection/`, `navigation/` per `D-4`); export them from
  `src/index.ts` (these are **additive** exports — fine under INV-1, which forbids removals/renames,
  not additions). Fold `mercury-additions.css` into the styles import chain if those components need
  it.
- Diff `packages/mercury-ds/handoff/tokens.css` vs `packages/mercury-ui/src/styles/tokens.css`; fold
  in newer tokens **do-no-harm** (additive; don't change existing token values without an `S-3`
  note).
- `git rm -r packages/mercury-ds`. Then `grep -rn "mercury-ds\|MercuryUI" packages apps` → only
  expected hits (none in runtime source).

### Step 6 — wiring
- Add to **every** `apps/*/vite.config.ts`:
  `"@mercury/core": resolve(__dirname, "../../packages/mercury-core/src/index.ts")`.
- `pnpm install` (links the new workspace package).
- Confirm `mercury/.design-sync/config.json` — its build/output target. `pkg` is `@mercury/ui`
  (unchanged). If any path points at `packages/mercury-ds`, note it for `mx.5`; deleting the dir is
  safe (re-generable).

## The gate (from `mercury/`)

```bash
pnpm install
pnpm -r typecheck                       # INV-2 — all packages clean
pnpm -r build                           # INV-2 — all packages build
pnpm --filter "./apps/*" build          # INV-3 — all five apps build
# INV-1 barrel-diff (export NAMES identical; additions OK, removals/renames NOT):
diff <(git show HEAD:packages/mercury-ui/src/index.ts | grep -oE 'export .*' ) \
     <(grep -oE 'export .*' packages/mercury-ui/src/index.ts)
grep -rn "mercury-ds" packages apps     # INV-5 — expect no runtime hits
```

## Gotchas

- **`noUncheckedIndexedAccess` is on** (base tsconfig) — moved files already satisfy it; new
  group-index files must too.
- **`verbatimModuleSyntax` is on** — keep `import type` for type-only imports when repointing to
  `@mercury/core`, or `tsc` errors.
- **`@/*` path alias travels with the move** — the moved `internal/`/`utils/`/`shared/` files import
  each other via `@/...`; give `@mercury/core` the same `@/* → ./src/*` path so they resolve without
  edits. The leftover `@mercury/ui` files keep their own `@/*` for what remains.
- **Two `ClassValue` types exist** — the tiny one in `cx.ts` (the public one) and a richer one in
  `utils/clsx.ts` (internal to `mergeProps`). Both move to core; only the `cx.ts` `ClassValue` is
  re-exported publicly (it's what `@mercury/ui`'s barrel exported). Don't merge them.
- **`Card`/`Table` are standalone with NO `DataDisplay` overlap** — don't try to dedupe them against
  the aggregate; just place the standalone files under `data-display/`.
- **Barrel additions are allowed** — exporting the 3 salvaged components grows the surface; INV-1
  only forbids **removing/renaming** an existing export.
- **`git mv` everything that moves** (LAW-4 R100 rename detection) so the commit, when the Operator
  asks, reads as moves not delete+add.
- **Commit only when asked**, pathspec only; `packages/mercury-ds` deletion + the new package + the
  regroup are one concern — but re-verify `git diff --cached --name-only` before any commit.
