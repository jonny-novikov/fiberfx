# MX.9.1 · The showcase spine — the source-resolved scaffold + the workspace join

> **Status: 🔨 BUILD-READY (authored 2026-07-02 in the mx.9 split; NOT yet built).** The first buildable
> sub-rung of the [`../mx.9/mx.9.md`](../mx.9/mx.9.md) SUB-EPIC (the layered-engine split, Operator-ruled
> 2026-07-02). mx.9.1 lands the **spine**: the `apps/showcase/` scaffold that resolves `@mercury/*` from
> source, the app-local `storybook/test` shim wired into the vite alias, a sanity page proving alias + tokens,
> the fresh root `dev:showcase` script, and the apps-gate join (2 → 3 product apps). **No registry, no shell,
> no story rendering** — those are mx.9.2/9.3/9.4; the spine is the smallest slice that builds, renders, and
> joins the gate.
>
> **Risk: NORMAL · formation Trio** (Director + architect/`venus` + implementor/`mars` two-pass). The
> Operator may override at ship. **Inherited rulings (2026-07-02, epic §7 — closed, do not re-open):** B
> (`apps/showcase` / `@mercury/showcase`) · C (conventional vite/React on the source alias; `loader.js` /
> `@babel/standalone` REJECTED) · D (the prototypes stay untracked read-only seeds) · E (zero new dependency).

Parent epic: [`../mx.9/mx.9.md`](../mx.9/mx.9.md) · canon: [`../../mercury.design.md`](../../mercury.design.md)
· roadmap: [`../../mercury.roadmap.md`](../../mercury.roadmap.md) · dashboard:
[`../../mercury.progress.md`](../../mercury.progress.md) · acceptance: [`mx.9.1.stories.md`](./mx.9.1.stories.md)
· build context: [`mx.9.1.llms.md`](./mx.9.1.llms.md).

## 0 · The slice

The epic's K-1 (the app scaffold) plus the wiring half of K-6 (the `dev:showcase` ADD + the apps-gate join),
plus one surface the 2026-07-02 reconcile added: the **`storybook/test` shim** — 11 of the 65 story files
VALUE-import that bare specifier (the mx.8.2 `fn()` spy + play helpers), so the vite config must resolve it
to app-local code from day one, or the mx.9.2 registry's lazy story modules would fail at their first load.
The shim's alias entry and module land HERE (the config is complete from day one); its **liveness across all
65 story modules is proved at mx.9.3** (the rung that first executes story modules).

## 1 · Goal

A vite/React app exists at `apps/showcase/` (`@mercury/showcase`) and **builds** (`pnpm --filter
@mercury/showcase build` → `apps/showcase/dist/`, exit 0), joining the apps gate as the third product app. It
resolves `@mercury/ui` / `@mercury/effector` / `@mercury/core` **from source** via the vite alias + tsconfig
`paths` byte-mirroring `apps/echomq`, **plus one showcase-specific alias entry** resolving `storybook/test`
to the app-local no-op shim. A sanity page renders real barrel exports (`Button` · `Card` · `Badge`) and
token swatches, proving the alias delivers both the components and the stylesheet (the barrel side-effect
import). The root gains `dev:showcase` (port 5176, strictPort). The barrel is byte-identical; the lockfile
gains only the `@mercury/showcase` importer block.

## 2 · Rationale (5W)

- **Why.** Every later surface (registry, interpreter, renderer, chrome) presupposes a workspace app that
  builds and resolves the packages from source. Landing the spine alone makes the riskiest wiring (workspace
  join, alias, shim, lockfile) a small, fully verifiable diff before any engine code exists.
- **What.** Seven files: `apps/showcase/{package.json, vite.config.ts, tsconfig.json, index.html}` +
  `src/{main.tsx, App.tsx, shims/storybook-test.ts}`; one script line added to `mercury/package.json`; the
  lockfile importer block from `pnpm install`.
- **Who.** *Built by* the implementor to [`mx.9.1.llms.md`](./mx.9.1.llms.md) (every file's exact content is
  carried in the brief — write-first). *Consumed by* mx.9.2–9.5 (the engine rungs build inside this scaffold)
  and the Operator (accepting at the gate + the rendered sanity page).
- **When.** First of the five sub-rungs; the epic's external hard gates (mx.7.4 + mx.8) are SHIPPED and
  satisfied. mx.9.2 hard-gates on this rung.
- **Where.** New `mercury/apps/showcase/**`; edited `mercury/package.json` (one script line);
  `mercury/pnpm-lock.yaml` (the importer block). Nothing else — no `packages/*` edit, no other app.

## 3 · Invariants (runnable checks)

- **INV-1 · The barrel is byte-identical** (epic INV-1). mx.9.1 touches no `packages/**` file. Check:
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` → empty
  (Director-run; agents run no git).
- **INV-2 · Source resolution, byte-mirrored** (epic INV-2). `apps/showcase/vite.config.ts` carries the three
  `@mercury/*` alias lines **byte-identical** to `apps/echomq/vite.config.ts`, and `tsconfig.json` mirrors the
  same three `paths`; the sanity page renders with **no** package `dist/` required. Check: diff the three
  alias lines against `apps/echomq/vite.config.ts`; run `pnpm run dev:showcase` before any package build.
- **INV-3 · The app builds and joins the gate** (epic INV-3). `pnpm --filter @mercury/showcase typecheck` and
  `build` exit 0; `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` exits 0 building exactly
  **three** product apps (`echomq` · `mobile` · `showcase`) — no root script edit needed for the join.
- **INV-4 · The shim resolves `storybook/test` to app-local code.** `vite.config.ts` carries the alias entry
  `"storybook/test" → src/shims/storybook-test.ts`; the shim exports exactly the six names the 11 story files
  import — `fn` (a callable-no-op factory: it IS invoked, in `args`) + `expect` · `userEvent` · `fireEvent` ·
  `waitFor` · `within` (play-only; loud-throw stubs — the showcase never runs `play`). Checks:
  `grep -n "storybook/test" apps/showcase/vite.config.ts` → 1 alias entry;
  `grep -cE "^export (function|const)" apps/showcase/src/shims/storybook-test.ts` → 6 export statements.
  *Liveness (the gate must exercise the outcome) is mx.9.3's job — the first rung that executes story
  modules proves all 65 load through the shim; at mx.9.1 the check is presence + shape only, stated as such.*
- **INV-5 · The tsc posture** (the epic reconcile's nuance). `tsc` does not traverse `import.meta.glob`
  targets, and no mx.9.1 source imports `storybook/test`, so `pnpm --filter @mercury/showcase typecheck`
  passes with **no** `storybook/test` entry in tsconfig `paths`. If a later rung's build proves otherwise,
  the fallback is a `paths` entry pointing at **the shim itself** (keeping types and runtime aligned), noted
  in the brief — not silently mirrored from the Storybook host.
- **INV-6 · Consume-down greps empty** (epic INV-7).
  `grep -RnE "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" apps/showcase` → empty.
- **INV-7 · Scope + lockfile posture** (epic INV-9). The diff is exactly: `apps/showcase/**` (7 new files) +
  `mercury/package.json` (one added line) + `mercury/pnpm-lock.yaml` (the `@mercury/showcase` importer block;
  **no new external dependency versions** — Fork E RULED). The worktree lockfile is routinely dirty from
  sibling programs — the Director partitions at commit; the design seeds stay untracked and unread by the
  build.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | `apps/showcase/package.json` — `@mercury/showcase`, `private`, `type: module`, scripts `dev`/`build`/`preview`/`typecheck`, the **exact** `apps/echomq` dep/devDep set (`@mercury/*` `workspace:*`; note: echomq declares **no** `@mercury/core` dep — the mirror preserves that, the alias covers it) | S-1; INV-3, INV-7 |
| K-2 | `apps/showcase/vite.config.ts` — the echomq alias block byte-mirrored + the one `storybook/test` shim entry | S-2; INV-2, INV-4 |
| K-3 | `apps/showcase/src/shims/storybook-test.ts` — the six-export no-op shim | S-2; INV-4 |
| K-4 | `apps/showcase/tsconfig.json` — extends `../../tsconfig.base.json`, the echomq `paths`/options mirror | S-2; INV-2, INV-5 |
| K-5 | `apps/showcase/index.html` (`class="light-theme"` on `<html>`, canon §0) + `src/main.tsx` + `src/App.tsx` — the sanity page: `Button`/`Card`/`Badge` from `@mercury/ui` (barrel-verified exports) + token swatches (`--bg-brand` · `--bg-brand-subtle` · `--fg-on-brand` · `--indigo-3`, styles-verified) | S-1, S-2; INV-2 |
| K-6 | The wiring — `"dev:showcase": "pnpm --filter @mercury/showcase exec vite --port 5176 --strictPort"` added to `mercury/package.json` (after `dev:mobile`; 5174/5175/5177/5180 are taken, 5176 verified free) + the apps-gate join (2 → 3, automatic) + `pnpm install` (the importer block) | S-3, S-4; INV-3, INV-7 |

## 5 · The method (build order)

1. **Write the scaffold** — all seven `apps/showcase` files exactly as carried in
   [`mx.9.1.llms.md`](./mx.9.1.llms.md) §Topology (the brief is write-ready; no echomq read required, the
   bytes are transcribed and the brief cites their source lines).
2. **Wire the root** — add the `dev:showcase` script line; run `pnpm install` from `mercury/` (writes the
   importer block).
3. **Prove the spine** — `pnpm run dev:showcase` → the sanity page renders the three components + the four
   swatches on `:5176` with no package `dist/` present.
4. **Run the gate ladder** (brief §Gate, verbatim) — packages unchanged · showcase typecheck/build · the
   3-app gate · the consume-down greps; the Director re-runs independently + the barrel-diff + the lockfile
   partition at commit.

## 6 · Dependencies

- **Hard-gates on:** the epic's external gates (mx.7.4 + mx.8 — SHIPPED, satisfied). Nothing else — this is
  the ladder's first rung.
- **Unblocks:** mx.9.2 (the registry + shell build inside this scaffold; hard gate), and transitively
  mx.9.3–9.5.
- **Touches:** `mercury/apps/showcase/**` (new) · `mercury/package.json` (one line) · `mercury/pnpm-lock.yaml`
  (importer block). Out of pathspec: everything else, including the design seeds and `packages/**`.

> **Framing (propagate):** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. Each surface is a contract (precondition / postcondition / invariant); acceptance is
> at the boundary.
