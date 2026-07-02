# MX.10 · Workspace dependency reconciliation & the vite 7 lift (the pnpm catalog)

> **Status: 📐 SOLID-FORWARD (specced 2026-07-01, NOT yet built).** A **cross-cutting toolchain rung** —
> orthogonal to the Movement III feature ladder (`mx.0`–`mx.9` build the design system; `mx.10` lifts the
> *toolchain* beneath it). It makes the workspace's shared dev-dependency versions a **single-sourced
> invariant** (a pnpm `catalog:`) and lifts the build toolchain from **vite 6 to vite 7**, converging
> **vitest** to one major and tilde-pinning **typescript** on the way. It adds **no** component, **no** export,
> **no** story: the `@mercury/ui` barrel is **byte-identical** before and after (the master invariant — a
> dependency rung must not perturb the public surface).
>
> **The three shaping forks are RULED (Operator, 2026-07-01):** scope = **`packages/*` + `apps/*` + the
> workspace root, NOT `mercury/codemojex/**`** (the codemojex sub-workspace adopts the catalog in a sibling
> `/cm-ship` rung); mechanism = the **pnpm `catalog:`** protocol (one version, referenced everywhere); shape =
> **one rung, internally phased** (hygiene on vite 6 → the vite-7 major → the build proof). The residual grain
> forks (§7) are minor and Steward-ruled.
>
> **Risk: NORMAL-to-elevated.** No new process or runtime surface, but a **major-version bump across every
> in-scope manifest** is a wide blast radius. The load-bearing hazards: (a) the `@storybook/react-vite` builder
> not yet supporting vite 7 (the largest vite consumer — INV-3); (b) a caret **overriding** the catalog and
> re-opening drift (INV-2 / INV-5); (c) a **codemojex** manifest edited, crossing the ruled boundary (INV-6);
> (d) a **pre-existing `@echo/*` red** (e.g. `@echo/fx` from HEAD) mis-attributed to the lift (INV-8). A build
> proof on the real toolchain closes each.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · dashboard:
[`../../mercury.progress.md`](../../mercury.progress.md) · the reconcile surface (the workspace manifest set):
[`../../../../mercury/pnpm-workspace.yaml`](../../../../mercury/pnpm-workspace.yaml) +
[`../../../../mercury/package.json`](../../../../mercury/package.json) · method:
[`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md) · authoring contract:
[`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md) · acceptance:
[`mx.10.stories.md`](./mx.10.stories.md) · build context: [`mx.10.llms.md`](./mx.10.llms.md).

## 0 · The slice — a toolchain rung, not a feature rung

Every rung `mx.0`–`mx.9` builds the **design system**: `@mercury/core`/`ui`/`effector`, the Storybook host, the
component import, the showcase. `mx.10` builds none of that — it lifts the **toolchain the whole ladder stands
on**. Two moves, one rung:

1. **Make the versions an invariant.** Across the in-scope manifests, `typescript` is declared **six ways**
   (`^5.5.4` · `^5.6.3` · `^5.7.0` · `^5.7.2` · `^5.8.3` · `~5.9.3`); `vitest` is a **live dual-major** (the
   workspace root declares `^3.0.0` and four leaf packages declare `^4.0.16`, so the lockfile carries **both**
   `vitest@3.2.6` and `vitest@4.1.9` — the `@testing-library/jest-dom` (JEST RETIRED! MUST BE REMOVED) collision recorded in the
   dual-vitest trap note). The tree resolves cleanly *today* only because pnpm's highest-satisfiable dedup
   happens to collapse the carets to one `typescript@5.9.3` — that uniformity is **luck, not policy**, and one
   fresh install or one new low-ceiling package fans it back out. The **pnpm `catalog:`** protocol replaces the
   luck with a rule: one version declared in `pnpm-workspace.yaml`, every manifest referencing `"catalog:"`.
   After it, version drift is not *unlikely* — it is **unrepresentable**.
2. **Lift the build major.** The toolchain sits one major behind on **vite 6**; **vite 7** is the current line.
   The lift also *forces* the vitest convergence (vite 7 requires a vitest floor of 3.2, so the split resolves
   **up** to `^4`) and rides alongside the `typescript` tilde-pin (the last-session principle: TypeScript is
   **not** semver, so a caret admits type-checking-breaking minors — the tilde `~5.9.3` is the correct pin).

Because the surface is the design system's **build config + manifests**, not its components, the rung's defining
discipline is **restraint**: the `@mercury/ui` public barrel stays byte-identical (INV-1), and the ruled
boundary holds — no `mercury/codemojex/**` manifest is touched (INV-6), even though the catalog block, living in
the shared `pnpm-workspace.yaml`, is *available* to those members for a later `/cm-ship` rung to adopt.

## 1 · Goal

A pnpm **`catalog:`** block exists in `mercury/pnpm-workspace.yaml` declaring one version each for `typescript`
(`~5.9.3`), `vite` (`^7`), `vitest` (`^4`), `react` + `react-dom` (`^19`), and the two deps the moves couple in
(`jsdom` `^26`, `@vitejs/plugin-react` at a vite-7-compatible version). **Every** in-scope manifest —
`mercury/packages/*`, `mercury/apps/*`, and the workspace root `mercury/package.json` — references `"catalog:"`
for those deps, so the version literal appears in **exactly one place**. The toolchain is lifted to **vite 7**
with **vitest 4**; the `@mercury/*` packages + the workspace apps typecheck and build on the new toolchain; the
`@mercury/ui` barrel is byte-identical (master invariant holds). The `mercury/codemojex/**` sub-workspace is
**out of scope** — its manifests keep their explicit versions until a sibling `/cm-ship` rung migrates them, a
bounded transitional state the rung records honestly.

## 2 · Rationale (5W)

- **Why.** The shared toolchain versions are **un-policed** — six `typescript` specs, a live `vitest`
  dual-major, a split `jsdom` (`^25` root vs `^26` in the vendored Phoenix packages) — and the build major is a
  release behind. Un-policed versions drift silently on the next install and re-open the jest-dom collision; a
  stale major forgoes vite 7's toolchain (Rollup 4 / esbuild / the Environment API) and its Node floor. A
  **catalog** makes the version a single-sourced invariant; the **vite 7 lift** modernizes the build and forces
  the vitest convergence that closes the dual-major. One rung reconciles the policy and lifts the major together
  because vite 7 and the vitest floor are **coupled** — they cannot land apart.
- **What.** A `catalog:` block in `pnpm-workspace.yaml` (7 entries); every in-scope manifest's literal dep spec
  for those deps replaced with `"catalog:"`; the **vite 6→7** major bump (the catalog `vite`, `@vitejs/plugin-
  react` raised to a vite-7-compatible version, the v7 config surface addressed — the `build.target` default,
  the removed `splitVendorChunkPlugin` [already unused], the removed Sass legacy API [verify none], the
  `@storybook/react-vite` builder verified on v7); the **vitest 3→4** root convergence; the re-resolved
  `pnpm-lock.yaml`. **No** new runtime dependency; **no** `src/**` behaviour change.
- **Who.** *Authored by* the Mercury spec-steward (this triad); *built by* the implementor wave. *Consumed by* —
  (1) every Mercury contributor and CI, who get a deterministic, single-sourced install with no dual-major; (2)
  the `mercury/codemojex/**` sub-workspace, which adopts the catalog next (a sibling `/cm-ship` rung); (3) the
  Operator, accepting a current, policed toolchain under the design system.
- **When.** **Orthogonal** to the Movement III feature ladder — shippable independent of `mx.7.3.3` / `mx.8.3+`
  / `mx.9`. Recommended **before** `mx.9` so the new showcase app inherits a clean, current toolchain rather
  than migrating one later.
- **Where.** `mercury/pnpm-workspace.yaml` (the catalog block); `mercury/packages/*/package.json` +
  `mercury/apps/*/package.json` + `mercury/package.json` (catalog references + the vite/vitest bumps); the vite
  config files a v7 change requires (`packages/{mercury-ui,mercury-effector,phoenix,phoenix_live_view}/
  vite.config.ts`, `apps/{echomq,mobile,storybook}/vite.config.ts`); `mercury/pnpm-lock.yaml` (re-resolved).
  **Out:** every `mercury/codemojex/**` manifest.

## 3 · Invariants (runnable checks)

- **INV-1 · The master invariant holds — the barrel is byte-identical.** `mx.10` changes config + manifests, not
  component source; it touches **no** export. Mechanical:
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` is **empty**. When
  in doubt resolve the full export set (TS `getExportsOfModule`), not a text-diff. A dependency rung that moves
  the barrel is a defect.
- **INV-2 · Single-source — every in-scope manifest references the catalog.** For the seven catalog deps, a grep
  over the in-scope `package.json` set finds **no literal version** — each declares `"catalog:"`. The version
  literal appears in **exactly one place**, the `pnpm-workspace.yaml` `catalog:` block. Observable:
  `grep -rE '"(typescript|vite|vitest|react|react-dom|jsdom|@vitejs/plugin-react)"\s*:\s*"[~^0-9]' ` over
  `packages/*/package.json apps/*/package.json package.json` is **empty**; the same keys under `catalog:` carry
  the literals.
- **INV-3 · vite is 7.** The mercury manifests resolve `vite@7.x`; `pnpm run verify:mercury` and
  `pnpm --filter "./apps/*" build` (echomq · mobile · storybook via `sb:build`) exit 0 on vite 7, and
  `@vitejs/plugin-react` resolves to a version whose peer range admits vite 7. Observable: `pnpm --filter
  @mercury/ui exec vite --version` prints `7.`; the Storybook build (`pnpm run sb:build`) exits 0.
- **INV-4 · The vitest dual-major is closed.** After the root converges to `^4`, the lockfile resolves a
  **single** vitest major (`4.x`) for the in-scope set — the root no longer pulls `3.x`. Observable:
  `grep -E '^\s+vitest@3' pnpm-lock.yaml` attributable to an in-scope importer is **empty** (any residual `3.x`
  is a `codemojex/**` importer only — the bounded transitional state, INV-6).
- **INV-5 · TypeScript is tilde-pinned, uniform.** The catalog `typescript` is `~5.9.3` (a **tilde** — patch
  within 5.9, because TypeScript is not semver); **no** in-scope manifest overrides it with a caret. Observable:
  the `catalog:` typescript entry begins `~`; the INV-2 grep confirms no in-scope caret override.
- **INV-6 · Boundary — no codemojex manifest edited.** `git diff --name-only` touches **no**
  `mercury/codemojex/**` `package.json`. The catalog block is **additive** — inert for any manifest that still
  declares a literal — so its presence changes no `codemojex` resolution. Observable:
  `git diff --name-only -- 'mercury/codemojex/**/package.json'` is **empty**.
- **INV-7 · No new dependency, no code change.** The rung's diff is **manifests + `pnpm-workspace.yaml` +
  `pnpm-lock.yaml` + vite/vitest config** only — no `src/**` behaviour edit, no dependency added beyond the
  toolchain devDep bumps the lift requires. Observable: `git diff --name-only` outside the config/manifest set
  is empty; `git diff -- 'mercury/**/src/**'` is empty.
- **INV-8 · Green on the new toolchain, pre-existing reds baselined.** `pnpm run verify:mercury`
  (`typecheck:mercury` + `build:mercury` + `sb:typecheck`) and `pnpm --filter "./apps/*" build` exit 0 on
  vite 7 / vitest 4. Any package **already red from HEAD** (e.g. `@echo/fx`, a known tsc-only red) is
  **recorded pre-rung** (a baseline capture) so a pre-existing failure is never attributed to the lift; `mx.10`
  neither fixes nor regresses it. Observable: the pre-rung `pnpm --filter "./packages/*" build` red set equals
  the post-rung red set (no *new* red introduced by the toolchain move).

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | **The `catalog:` block** in `pnpm-workspace.yaml` — 7 entries: `typescript ~5.9.3` · `vite ^7` · `vitest ^4` · `react ^19` · `react-dom ^19` · `jsdom ^26` · `@vitejs/plugin-react` (vite-7-compatible) | INV-2; the version literal lives in exactly one place |
| K-2 | **Every in-scope manifest migrated to `catalog:`** — `packages/*` + `apps/*` + the root `package.json`, for the seven deps (each literal → `"catalog:"`) | INV-2 + INV-5; the grep for an in-scope literal/caret override is empty |
| K-3 | **The vite 6→7 lift** — catalog `vite ^7`; `@vitejs/plugin-react` raised to a v7-compatible version; the v7 config surface addressed (`build.target` policy · `splitVendorChunkPlugin` [none] · Sass legacy [verify none]); `@storybook/react-vite` builder verified on v7 | INV-3; `verify:mercury` + the apps build + `sb:build` green on vite 7 |
| K-4 | **The vitest 3→4 convergence** — catalog `vitest ^4`; the root bumped from `^3.0.0`; the dual-major closed (one resolved major for the in-scope set) | INV-4; the in-scope lockfile resolves a single `vitest@4.x` |
| K-5 | **The typescript / react / jsdom reconciliation** — via the catalog: `~5.9.3` (tilde) · `^19` (react is semver) · `^26` (jsdom); no in-scope caret override | INV-5; a uniform, single-sourced pin for each |
| K-6 | **The gate + proof** — `verify:mercury` + the apps build green; the barrel byte-identical; the pre-existing `@echo/*` reds baselined; the re-resolved lockfile scoped to the toolchain deps | INV-1 + INV-6 + INV-7 + INV-8; green on the new toolchain, boundary held, no new red |

## 5 · The method (build order) — three phases

The rung is **internally phased** (the ruled shape): hygiene first on the *old* major so the reconciliation is
provable in isolation, then the major bump, then the build proof. The boundary (no `codemojex` touch) and the
barrel (byte-identical) hold across all three.

1. **Phase 1 — hygiene (on vite 6, low-risk).** Add the `catalog:` block to `pnpm-workspace.yaml` with the
   *current* majors (vite `^6` for now, vitest `^4`, typescript `~5.9.3`, react/react-dom `^19`, jsdom `^26`,
   `@vitejs/plugin-react ^4.3.3`). Migrate every in-scope manifest's seven deps to `"catalog:"`. Bump the root
   `vitest` from `^3.0.0` (the catalog now carries `^4`) and the root `jsdom` from `^25`. `pnpm install`; run
   `verify:mercury` + the apps build **still on vite 6** — the reconciliation is green before the major moves.
2. **Phase 2 — the vite-7 major.** Raise the catalog `vite` to `^7` and `@vitejs/plugin-react` to a
   vite-7-compatible version. Address the v7 breaking surface **at the config**: decide the `build.target`
   policy (§7-A), confirm no `splitVendorChunkPlugin` (already none) and no Sass legacy API, confirm the
   `engines.node` floors admit vite 7's `^20.19 || >=22.12` (the workspace is `>=22`). Verify the
   `@storybook/react-vite` builder on vite 7 — the largest vite consumer, and the rung's top risk (a Storybook
   bump joins the rung, or a documented blocker, if it does not support v7). `pnpm install`.
3. **Phase 3 — the build proof.** Baseline the pre-rung red set (`pnpm --filter "./packages/*" build`, recording
   e.g. `@echo/fx`). Run `verify:mercury` + `pnpm --filter "./apps/*" build` + `sb:build` on vite 7 / vitest 4.
   Barrel-diff byte-identical. Confirm the boundary (`git diff --name-only -- 'mercury/codemojex/**'` empty) and
   the lockfile scope (only the toolchain deps re-resolved). The post-rung red set equals the baseline (no new
   red).

Grounding sources (re-probe before trusting, per [`mx.10.llms.md`](./mx.10.llms.md)): the declared dep set
(`grep` the in-scope manifests); the vite config files; the `@storybook/react-vite` + `storybook` versions in
`apps/storybook/package.json`; the vite 7 migration guide (the breaking surface); the barrel
`packages/mercury-ui/src/index.ts`; the pnpm catalog docs (the `catalog:` protocol).

## 6 · Dependencies

- **Hard-gates on:** nothing in the feature ladder — `mx.10` is orthogonal and self-contained. Soft: a reachable
  toolchain (Node `>=22.12`, pnpm `>=10.17`) for the install + build proof.
- **Unblocks:** the **sibling `/cm-ship` rung** that migrates the `mercury/codemojex/**` manifests to the same
  catalog (they become the visible catalog-adopters this rung leaves in waiting); and `mx.9` (the showcase app),
  which inherits a clean, current toolchain rather than migrating one after the fact.
- **Touches:** `mercury/pnpm-workspace.yaml` (the catalog block) · `mercury/packages/*/package.json` +
  `mercury/apps/*/package.json` + `mercury/package.json` (catalog references + the vite/vitest bumps) · the
  in-scope `vite.config.ts` files (only where a v7 change requires) · `mercury/pnpm-lock.yaml` (re-resolved).
  **Out of pathspec / untouched:** every `mercury/codemojex/**` manifest; any `mercury/**/src/**`; the
  `@mercury/ui` barrel. **Entangled-tree note:** `packages/phoenix/package.json` +
  `packages/phoenix_live_view/package.json` are **already modified** in the working tree (in-flight ship-with
  work) — the migration edits already-dirty files; the Director attributes against the pre-spawn baseline and
  splits the commit by concern at ship. Canon §7 / the roadmap / the dashboard: the Director folds at ship (the
  `mx.10` ladder row + a `D-` for each ruled fork).

## 7 · Forks for the Operator

The **three shaping forks are RULED** (2026-07-01, recorded in the status block): **scope** = `packages/*` +
`apps/*` + root, not `codemojex` · **mechanism** = the pnpm `catalog:` · **shape** = one rung, phased. What
remains are **minor grain forks**, each with a Steward recommendation; the Operator rules at the ship's sharpen
stage.

### Fork A — the vite 7 `build.target` policy · *Steward: keep the new default*

- **Arms.** **(a)** Adopt vite 7's new default `build.target` (`'baseline-widely-available'` — a fixed modern
  baseline) · **(b)** pin the prior explicit target to preserve byte-identical build output.
- **Steward: (a)** — the consumers are current engines (the Storybook host, the Telegram Mini App view, the
  desktop shell); take the modern default unless a build-output diff shows a real regression, then pin.

### Fork B — the `@vitejs/plugin-react` version · *Steward: minimal v7-compatible*

- **Arms.** Take the **minimal** version whose peer range admits vite 7 (the smallest change) · vs jump to the
  plugin's newest major eagerly.
- **Steward: minimal** — the reconciliation intends **no behaviour change**; take the least version that
  satisfies vite 7's peer requirement, catalog-pinned like the rest.

### Fork C — a pre-existing `@echo/fx` red · *Steward: baseline-and-document*

- **Arms.** **Baseline** the pre-existing red (record it pre-rung, exclude it from the lift's attribution) · vs
  **repair** it inside `mx.10`.
- **Steward: baseline** — `mx.10` is a version-spec + build-major rung, not an `@echo/fx` repair; fixing an
  unrelated pre-existing failure is scope creep. Record it; the Operator schedules the repair separately.

### Fork D — the catalog's coupled entries (`jsdom`, `@vitejs/plugin-react`) · *Steward: include*

- **Arms.** Include `jsdom` + `@vitejs/plugin-react` in the catalog (they are shared, and both are *forced* by
  the react/vite moves — `jsdom` already splits `^25`/`^26`; the plugin must be v7-compatible) · vs keep the
  catalog to the four the Operator named (typescript · vite · vitest · react) and leave these as per-manifest
  literals.
- **Steward: include** — both are workspace-shared and coupled to the lift; catalog-pinning them completes the
  single-source policy at no extra risk. `react-dom` rides with `react` regardless.

> **Framing (propagate to any brief derived from this spec):** no gendered pronouns for agents; no perceptual or
> interior-state verbs ("sees" / "wants" / "feels" / "knows" / "decides") on a tool, package, or config; no
> first-person narration. State each surface as a contract (precondition / postcondition / invariant) so
> acceptance is at the boundary, not by re-reading the diff.
