# MX.10 · build context (the agent brief)

Build context for [`mx.10.md`](./mx.10.md) (authoritative body) + [`mx.10.stories.md`](./mx.10.stories.md)
(acceptance). The body wins on any disagreement; this brief lags it. **SOLID-FORWARD** — re-sharpened at the
rung's ship against the as-built manifest set and the installed vite/vitest versions. **NO-INVENT**: every path
and version names a real surface; re-probe each grounding path before trusting it.

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state verbs
> ("sees" / "wants" / "feels" / "knows" / "decides") on a tool, package, or config; no first-person narration.
> State each surface as a contract (precondition / postcondition / invariant) so acceptance is at the boundary.

## References — read first, in this order

1. **The body + acceptance** — [`mx.10.md`](./mx.10.md) (§0 the slice, §3 invariants, §5 the three phases, §7
   the ruled + grain forks) + [`mx.10.stories.md`](./mx.10.stories.md).
2. **The reconcile surface (the current declared state)** — [`../../../../mercury/pnpm-workspace.yaml`](../../../../mercury/pnpm-workspace.yaml)
   (the workspace globs — the four members `packages/*` · `apps/*` · `codemojex/packages/*` · `codemojex/apps/*`;
   the **`catalog:` block is added here**) and [`../../../../mercury/package.json`](../../../../mercury/package.json)
   (the root — `vitest ^3.0.0`, `jsdom ^25`, `react ^19`, `@vitejs/plugin-react ^4.3.3`; the `verify:mercury`
   script). Re-run the declared-version sweep before editing:
   `grep -rn --include=package.json -E '"(typescript|vite|vitest|react|react-dom|jsdom|@vitejs/plugin-react)"' mercury | grep -v node_modules | grep -v codemojex`.
3. **The pnpm catalog protocol** — the `catalog:` (single default catalog) mechanism: a `catalog:` map in
   `pnpm-workspace.yaml`, each dependent declaring `"<dep>": "catalog:"`. Confirm the pnpm version admits it
   (`packageManager: pnpm@10.17.1` — it does).
4. **The vite 7 breaking surface** — the vite 7 migration guide: the `build.target` default →
   `'baseline-widely-available'`; `splitVendorChunkPlugin` removed (already unused here — verified); the Sass
   legacy API removed (verify no Sass — Mercury styles with CSS tokens); the Node floor `^20.19 || >=22.12`; the
   `@vitejs/plugin-react` peer range; the **vitest floor 3.2** (why the split resolves up to `^4`). Ground the
   Storybook risk in [`../../../../mercury/apps/storybook/package.json`](../../../../mercury/apps/storybook/package.json)
   (`@storybook/react-vite` + `storybook` versions — must admit vite 7).
5. **The master-invariant surface** — `packages/mercury-ui/src/index.ts` (the barrel — must stay byte-identical)
   and the gate scripts in the root `package.json` (`verify:mercury`, `build:mercury`, `typecheck:mercury`,
   `sb:build`, `sb:typecheck`).

**Workspace state to re-confirm before building** (`git status --short mercury/`): `packages/phoenix/package.json`
+ `packages/phoenix_live_view/package.json` are **already modified** (in-flight ship-with work) — the migration
edits already-dirty files; report the pre-spawn baseline so the Director attributes correctly and splits the
commit by concern. The in-scope packages are `cluster · core · fx · mercury-core · mercury-effector · mercury-ui
· phoenix · phoenix_live_view`; the in-scope apps are `echomq · mobile · storybook`; **`codemojex/**` is OUT.**

## Requirements (each traced: story ⇠ requirement ⇢ invariant/check)

| # | Requirement | Story | Invariant / check |
|---|---|---|---|
| R-1 | A `catalog:` block in `pnpm-workspace.yaml` with the 7 entries (`typescript ~5.9.3` · `vite ^7` · `vitest ^4` · `react ^19` · `react-dom ^19` · `jsdom ^26` · `@vitejs/plugin-react` v7-compat) | S-1 | INV-2 |
| R-2 | Every in-scope manifest's declared subset of the 7 deps migrated to `"catalog:"` — no literal/caret left in the in-scope set | S-2 | INV-2, INV-5 |
| R-3 | The vite 6→7 lift — catalog `vite ^7`; `@vitejs/plugin-react` v7-compatible; the v7 config surface addressed (`build.target` policy · Sass-legacy verified none · Node floor admits v7) | S-3 | INV-3 |
| R-4 | The `@storybook/react-vite` builder builds on vite 7 (or a named blocker; never a silent `vite` downgrade) | S-4 | INV-3 |
| R-5 | The vitest 3→4 convergence — catalog `vitest ^4`; the root bumped from `^3.0.0`; one resolved vitest major in-scope | S-5 | INV-4 |
| R-6 | typescript tilde-pinned `~5.9.3`; react/react-dom `^19`; jsdom `^26` — all via the catalog, no in-scope caret override | S-6 | INV-5 |
| R-7 | The `@mercury/ui` barrel **byte-identical**; **no** `codemojex/**` manifest edited; **no** `src/**` change | S-7 | INV-1, INV-6, INV-7 |
| R-8 | Green on vite 7 / vitest 4 (`verify:mercury` + apps + `sb:build`); the pre-existing `@echo/*` reds baselined (no new red) | S-8 | INV-8 |

## Execution topology

**Runtime shape.** Not a runtime — a **build-graph reconciliation**. The unit of work is a manifest edit + a
re-resolve + a build proof. The `catalog:` map in `pnpm-workspace.yaml` becomes the single version source; each
in-scope `package.json` dereferences it via `"catalog:"`; `pnpm install` re-resolves the lockfile against the
catalog; the gate proves the `@mercury/*` set + the apps on the resolved toolchain. The boundary
(`codemojex/**` untouched) and the barrel (byte-identical) are invariants across every step, not steps.

**The catalog is workspace-global, the migration is mercury-only.** The `catalog:` block lives in the shared
`pnpm-workspace.yaml`, so it is *available* to the `codemojex/**` members — but this rung flips **only** the
mercury manifests to `"catalog:"`. A `codemojex` manifest keeps its literal version and is therefore inert to
the catalog (additive semantics). The transitional consequence is honest and bounded: the workspace may carry
vite 6 (`codemojex`, still on literals) beside vite 7 (`mercury`, on the catalog) until a sibling `/cm-ship`
rung migrates `codemojex` — safe, because a package's vite version is a **build-time** concern and each package
ships a built artifact.

**Build-order task DAG** (mirror [`mx.10.md`](./mx.10.md) §5 — three phases):
`Phase 1: catalog@vite6 + migrate manifests + root vitest/jsdom bump → verify:mercury green on vite 6 (R-1,R-2,R-5,R-6)`
→ `Phase 2: catalog vite→^7 + plugin-react v7 + config surface + storybook builder check (R-3,R-4)`
→ `Phase 3: baseline reds → verify:mercury + apps + sb:build on vite 7 → barrel-diff + boundary + lockfile scope (R-7,R-8)`.

**EXACT files touched** (the whole pathspec):
- **Edited — the catalog source:** `mercury/pnpm-workspace.yaml` (add the `catalog:` block).
- **Edited — the in-scope manifests** (migrate the declared subset of the 7 deps to `"catalog:"`; bump the root
  `vitest`/`jsdom`): `mercury/package.json`; `mercury/packages/{cluster,core,fx,mercury-core,mercury-effector,
  mercury-ui,phoenix,phoenix_live_view}/package.json`; `mercury/apps/{echomq,mobile,storybook}/package.json`.
  *(Migrate only the deps a manifest already declares — add none it lacks.)*
- **Edited — only where a v7 change requires:** the in-scope `vite.config.ts` files
  (`packages/{mercury-ui,mercury-effector,phoenix,phoenix_live_view}/vite.config.ts`,
  `apps/{echomq,mobile,storybook}/vite.config.ts`) — a `build.target` pin only if §7-A rules it, else untouched.
- **Re-resolved:** `mercury/pnpm-lock.yaml` (only the toolchain deps move).
- **Out of pathspec / untouched:** every `mercury/codemojex/**` manifest; any `mercury/**/src/**`; the
  `@mercury/ui` barrel `packages/mercury-ui/src/index.ts`.

## Agent stories — Directive + Acceptance gate

Each surface is a contract: a **Directive** (what the implementor builds) closed by an **Acceptance gate** (the
check).

- **AS-1 · Phase 1 — catalog + migrate (on vite 6).** *Directive:* add the `catalog:` block to
  `pnpm-workspace.yaml` with the 7 entries but `vite ^6` for now (`typescript ~5.9.3`, `vitest ^4`, `react ^19`,
  `react-dom ^19`, `jsdom ^26`, `@vitejs/plugin-react ^4.3.3`). Migrate every in-scope manifest's declared subset
  of the 7 deps to `"catalog:"`; bump the root `vitest` (`^3.0.0`→catalog `^4`) and `jsdom` (`^25`→catalog
  `^26`). `pnpm install`. *Acceptance:* `pnpm run verify:mercury` + `pnpm --filter "./apps/*" build` exit 0
  **on vite 6**; the INV-2 grep (`"(typescript|vite|vitest|react|react-dom|jsdom|@vitejs/plugin-react)"\s*:\s*"[~^0-9]`
  over the in-scope set) is **empty**; `git diff --name-only -- 'mercury/codemojex/**'` is empty. *(INV-2, INV-5.)*
- **AS-2 · Phase 2 — the vite-7 major.** *Directive:* raise the catalog `vite` to `^7` and `@vitejs/plugin-react`
  to the minimal vite-7-compatible version (§7-B). Address the v7 config surface: rule `build.target` (§7-A —
  default keep unless a diff regresses), confirm no `splitVendorChunkPlugin` (none) and no Sass legacy API, and
  confirm the `engines.node` floors admit `^20.19 || >=22.12`. Verify `@storybook/react-vite` on vite 7. `pnpm
  install`. *Acceptance:* `pnpm --filter @mercury/ui exec vite --version` prints `7.`; `pnpm run verify:mercury`
  + `pnpm --filter "./apps/*" build` + `pnpm run sb:build` exit 0 on vite 7; if Storybook does not admit v7, a
  **named blocker** is recorded (never a silent `vite`→6 downgrade). *(INV-3.)*
- **AS-3 · Phase 3 — the build proof.** *Directive:* baseline the pre-rung red set
  (`pnpm --filter "./packages/*" build`, recording e.g. `@echo/fx`); run the full gate on vite 7 / vitest 4;
  confirm the barrel byte-identical, the boundary held, the lockfile scoped to the toolchain deps.
  *Acceptance:* `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` is
  **empty**; `git diff --name-only -- 'mercury/codemojex/**/package.json'` and `git diff -- 'mercury/**/src/**'`
  are **empty**; the post-rung `pnpm --filter "./packages/*" build` red set **equals** the baseline (no new red);
  the in-scope lockfile resolves a single `vitest@4.x`. *(INV-1, INV-4, INV-6, INV-7, INV-8.)*

**The gate ladder (run from `mercury/`):**
```bash
# --- pre-rung baseline (Phase 3 needs this recorded first) ---
pnpm --filter "./packages/*" build           # record the pre-existing red set (e.g. @echo/fx)

# --- the reconciliation proof ---
pnpm install                                 # re-resolve against the catalog
pnpm run verify:mercury                       # typecheck:mercury + build:mercury + sb:typecheck
pnpm --filter "./apps/*" build                # echomq + mobile (+ storybook via sb:build)
pnpm run sb:build                             # the Storybook builder on vite 7 (the top risk)
pnpm --filter @mercury/ui exec vite --version # prints 7.x

# --- invariants ---
grep -rE '"(typescript|vite|vitest|react|react-dom|jsdom|@vitejs/plugin-react)"\s*:\s*"[~^0-9]' \
  packages/*/package.json apps/*/package.json package.json   # → empty (INV-2)
diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts  # → empty (INV-1)
git diff --name-only -- 'codemojex/**/package.json'          # → empty (INV-6)
git diff -- 'packages/**/src/**' 'apps/**/src/**'            # → empty (INV-7)
```
**NORMAL-to-elevated at ship:** a major bump across every in-scope manifest — the Director's independent gate
re-run + an adversarial probe (a caret override survived? a `codemojex` manifest slipped in? a new red charged to
the lift?) is the gate; a verifier is optional unless the Storybook builder forces a wider change. **Never
`pnpm -r`** (it walks the `codemojex` sub-workspace, the wrong scope) — always `--filter`.

## The prompt (leaves no decision the spec has not fixed)

Reconcile the `mercury/` design-system toolchain to a **single-sourced** version policy and lift it to **vite
7**, in **one internally-phased rung**, touching only `packages/*` + `apps/*` + the workspace root — **never**
`mercury/codemojex/**` (the sibling island migrates later). Introduce a pnpm **`catalog:`** block in
`pnpm-workspace.yaml` (the 7 entries: `typescript ~5.9.3` — a **tilde**, TypeScript is not semver; `vite ^7`;
`vitest ^4`; `react`/`react-dom ^19`; `jsdom ^26`; `@vitejs/plugin-react` at the minimal vite-7-compatible
version) and migrate every in-scope manifest's declared subset of those deps to `"catalog:"` — add no dep a
manifest lacks. Do **Phase 1** on vite 6 (catalog + migrate + the root `vitest`/`jsdom` bump), prove
`verify:mercury` green, then **Phase 2** raise the catalog to vite 7 + a v7-compatible plugin-react, address the
v7 config surface (`build.target` — keep the new default unless a build diff regresses; confirm no
`splitVendorChunkPlugin`, no Sass legacy; confirm the Node floor), and verify the `@storybook/react-vite` builder
on v7 (the top risk — a Storybook bump joins the rung or a **named blocker** is recorded; **never** downgrade
`vite` back to 6 to go green). Then **Phase 3**: baseline the pre-existing `@echo/*` reds, run the full gate on
vite 7 / vitest 4, and prove the invariants — the `@mercury/ui` barrel **byte-identical**, **no** `codemojex`
manifest touched, **no** `src/**` change, the vitest dual-major closed, and **no new red** versus the baseline.
Keep the diff to manifests + `pnpm-workspace.yaml` + `pnpm-lock.yaml` + the vite configs (only where a v7 change
requires); never `pnpm -r` (use `--filter`); report the phoenix/phoenix_live_view working-tree entanglement to
the Director; commit `mercury/…` pathspec only when asked.
