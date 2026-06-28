# MX.3 · The Storybook host + foundations stories

> **Status: ✅ BUILT — gate-green 2026-06-28 (shipped via `/mercury-ship mx.3`).** The opener of **Movement III (the Design System Storybook)**. mx.0–mx.2
> built the floor: a three-package topology behind a stable barrel (mx.1), and a hand-authored
> `<Name>.prompt.md` contract beside all 33 components (mx.2). A story is a *rendered restatement of a
> contract* — so the Storybook stands on mx.2, and mx.3 lands the **host** plus the **first three
> foundation stories** that prove the host renders `@mercury/ui` from source under a theme decorator.
>
> **Risk: NORMAL.** mx.3 **adds** a workspace app (`apps/storybook/`), dev tooling (Storybook +
> `@storybook/react-vite`), and three `*.stories.tsx` — all additive. It does **not** touch the
> `@mercury/ui` barrel, does **not** extract/rename/delete a package, does **not** delete/rename a
> component, and does **not** change the token pipeline. The master invariant (the barrel-diff) is
> untouched. Hazards to hold the line on: (a) a **Storybook / Vite-6 / React-19 version mismatch**
> (build-time; caught by the `sb:build` smoke); (b) the **gitignore / `ds-bundle` relocation** getting
> the `/design-sync` `localDir` wrong; (c) **the storybook app leaking into the per-rung apps gate**
> (slows the ladder) or its co-located stories **leaking into `@mercury/ui`'s own `tsc`** (the
> library has no Storybook types — it would fail the packages gate). (a)/(c) are the load-bearing ones.
>
> **The decisions this rung carries (Operator-ruled, recorded for the canon at ship as `D-9`):**
> the Storybook host is a **new workspace app `apps/storybook/`** (not a `packages/*` member — a
> Storybook ships nothing, it *composes* `@mercury/ui` like the other apps); it resolves `@mercury/*`
> **from source** via a vite alias mirroring `apps/showcase/vite.config.ts`; it is **excluded from the
> per-rung apps gate** and proven by a separate `pnpm sb:build` smoke; and it is the single
> `/design-sync` `localDir` (the `ds-bundle/` relocates under it). mx.3 lands **host + foundations
> only** — the apps-side stories + the additive library enhancement are the **mx.4** mandate, recorded
> forward in §6.
>
> **As-built (2026-06-28, BUILD-GRADE).** Shipped via `/mercury-ship mx.3` (Director-led: venus → mars
> → Director verify). The host is `apps/storybook/` (`@mercury/storybook`) on **Storybook 10.4.6**
> (`@storybook/react-vite`) — the latest stable supporting Vite 6 + React 19; the spec invited "the
> latest stable", so the as-built is the 10.x line, not the 8/9.x the body sketched. It resolves
> `@mercury/*` from source via a byte-mirror of the showcase vite alias, with a `globalTypes`
> light/`dark-theme` toolbar + a scoped `dark-theme`-wrapper decorator and the `@mercury/ui` stylesheet
> loaded in preview. Three CSF3 foundation stories — `Foundations/Icon` (38-name `IconName[]`-typed
> select + Gallery), `Actions/Button` (six variants × three sizes + WithIcon), and a host-local
> `Foundations/Tokens` — each control traced to its mx.2 `<Name>.prompt.md`. Gate green (Director
> independent re-run): packages typecheck+build (4); the **five** product apps build
> (`--filter "!@mercury/storybook"`); barrel byte-identical (INV-1); `pnpm sb:build` → `storybook-static/`
> registering **exactly** the three titles (INV-8 scope). INV-8's library-`tsc` stories-`exclude` proven
> load-bearing by a net-zero mutation spot-check. `ds-bundle/` relocated under the host as the single
> `/design-sync` `localDir`. **Open (out-of-island, Operator):** `mercury/.gitignore` is itself
> repo-ignored (the root bare-`.gitignore` rule), so the `storybook-static/` ignore is locally effective
> but wants a ROOT-registry entry for fresh-clone/CI durability. Canon gains `D-9`.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · dashboard:
[`../../mercury.progress.md`](../../mercury.progress.md) · prior triad:
[`../mx.2/mx.2.md`](../mx.2/mx.2.md) · contract template:
[`../../contracts.md`](../../contracts.md) · method:
[`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md) · acceptance:
[`mx.3.stories.md`](./mx.3.stories.md) · build context: [`mx.3.llms.md`](./mx.3.llms.md).

## 0 · The slice — what mx.3 builds, and why host-and-foundations first

Movement III's destination is a per-component Design System Storybook standing on the clean
three-package topology (roadmap §The movements). mx.3 is its **opener**: it lands the **host** and
**three foundation stories**, nothing more. Splitting the host off from the component fan-out keeps
the proving surface small — mx.3 has to answer one question: *does a `@storybook/react-vite` host,
resolving `@mercury/ui`/`@mercury/core`/`@mercury/effector` from source like the apps, render a real
`@mercury/ui` component with its controls and a light/`dark-theme` toggle, and build to a static
bundle — without disturbing the barrel or the per-rung gate?* Answer that with three stories, and the
fan-out (mx.4) is a known shape.

The host is a **new workspace app**, `apps/storybook/`, not a package under `packages/`. The canon's
`packages/*` is the **shipped-library tier** (`@mercury/core` · `@mercury/ui` · `@mercury/effector`,
canon §1); a Storybook **ships nothing** — it *composes* `@mercury/ui` exactly as the five product
apps do, so it belongs in the `apps/*` tier (it auto-joins the `apps/*` workspace glob,
[`pnpm-workspace.yaml`](../../../../mercury/pnpm-workspace.yaml)). It resolves the packages **from
source** via a vite alias that mirrors [`apps/showcase/vite.config.ts`](../../../../mercury/apps/showcase/vite.config.ts)
(`@mercury/* → ../../packages/*/src/index.ts`), so a package edit is live in dev with no prebuild —
the same convention the canon names for the Storybook host (canon §1).

The three first stories are **foundations**: **Icon**, a **tokens** story, and **Button**. Each
story's `argTypes`/controls are a *rendered restatement* of the component's `<Name>.prompt.md` — the
hand-authored contract mx.2 fixed (canon §4/§6, `D-7`). The stories co-locate beside their component
per canon §4 (the grouped layout gives Movement III a 1:1 story home); the tokens story, which has no
single component, lives in the host's own `stories/` home. That is the whole of mx.3 — **no
app-screen stories, no other component stories**; those are mx.4+ (§6).

## 1 · Goal

A `@storybook/react-vite` host exists at `apps/storybook/` and **builds to a static bundle**
(`pnpm sb:build` → `storybook-static/`, exit 0). It resolves `@mercury/ui`/`@mercury/core`/
`@mercury/effector` **from source** via a vite alias mirroring the apps; a **global theme decorator**
renders every story in light and in `dark-theme` from a toolbar toggle; and its **stories glob is
forward-compatible** — it spans both `packages/mercury-ui/**/*.stories.tsx` (filled this rung) and
`apps/**/*.stories.tsx` (filled mx.4). Three foundation stories ship — **Icon**, a **tokens** story,
**Button** — each CSF3, each with controls written from the component's `<Name>.prompt.md`. The host
is **excluded from the per-rung apps gate** (the gate builds only the five product apps) and proven
by the separate `sb:build` smoke; the `ds-bundle/` (the `/design-sync` upload bundle) is **relocated
under the host** so `apps/storybook/` is the single `/design-sync` `localDir`. **No component
behavior, prop, token, or barrel export changes. The master invariant holds.**

## 2 · Rationale (5W)

- **Why.** Movement III is the program's destination — a browsable, per-component Storybook is how a
  human or a design/coding agent discovers and trusts the surface mx.1/mx.2 built. The host must be
  built **once, correctly**: a Storybook that resolves the packages from source (no prebuild drift), a
  theme decorator that exercises the canon's dark flip, and a stories glob that is forward-compatible
  with the mx.4 apps-side fan-out. Proving it with three foundation stories — the smallest set that
  touches the icon set, the token vocabulary, and a rich enum component — de-risks the fan-out without
  perturbing the gate.
- **What.** A new `apps/storybook/` host: `package.json` (Storybook devDeps + `@mercury/*` as
  `workspace:*`), `.storybook/main.ts` (`@storybook/react-vite`, CSF3, the forward-compatible stories
  glob), `.storybook/preview.tsx` (a global **light / `dark-theme` decorator** + a toolbar global, and
  the stylesheet load), a `vite.config.ts` mirroring the apps' source-resolution alias, and a
  `tsconfig.json`. Three CSF3 stories — `foundations/Icon/Icon.stories.tsx`,
  `actions/Button/Button.stories.tsx` (co-located beside their `.tsx`), and a host-local
  `stories/Tokens.stories.tsx` (tokens are not a single component). Plus the gate/ignore/relocation
  wiring: a `sb:build` root script, the per-rung apps-gate **exclusion** of the storybook app, the
  `.gitignore` entries, and the `ds-bundle/ → apps/storybook/ds-bundle/` relocation.
- **Who.** *Authored by* Claude Code as Director-led architect (this triad) + the implementor wave
  (the host + stories). *Consumed by* — (1) Mercury contributors browsing the library; (2) the Claude
  Design agent (the host re-aligns with the `.design-sync` export at mx.6); (3) **mx.4** (the
  per-component fan-out + the apps-side Pages, which inherit this host's glob, decorator, and
  source-resolution); (4) any AAW implementor verifying a component visually.
- **When.** Now — the opener of Movement III, hard-gating on **mx.2** (the contracts each story
  restates — met) and on mx.1's grouped structure (met). It unblocks mx.4 (the component-stories
  fan-out + the additive library enhancement) and mx.5/mx.6 (Effector stories, build/deploy +
  design-sync re-align).
- **Where.** New: `mercury/apps/storybook/**`. Co-located stories:
  `mercury/packages/mercury-ui/src/components/foundations/Icon/Icon.stories.tsx` and
  `.../actions/Button/Button.stories.tsx`. Host-local: `mercury/apps/storybook/stories/Tokens.stories.tsx`.
  Wiring: `mercury/package.json` (the `sb:build` script; the `build:apps` storybook exclusion),
  `mercury/.gitignore` (storybook output + the relocated bundle), `mercury/pnpm-lock.yaml` (the
  Storybook devDeps — a real dep moves), and one additive `exclude` line in
  `mercury/packages/mercury-ui/tsconfig.json` (so the co-located stories never enter the library's own
  `tsc`; see INV-8). Decision recorded as `D-9` in canon §7 at ship.

## 3 · Invariants (runnable checks)

- **INV-1 · The barrel holds.** mx.3 adds a host app + stories + dev tooling; it touches **no**
  component source and adds **no** export. The barrel-diff (canon §2) shows **0 removed/renamed**.
  Mechanical: `diff <(git show HEAD:packages/mercury-ui/src/index.ts | grep -oE 'export .*') <(grep -oE 'export .*' packages/mercury-ui/src/index.ts)`
  is empty (and ideally byte-identical — stories add no export).
- **INV-2 · The five product apps + the packages still build.** `pnpm --filter "./packages/*"
  typecheck` and `pnpm --filter "./packages/*" build` exit 0; the **five** product apps build via
  `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` (exit 0). A host-app rung must not
  perturb the product build.
- **INV-3 · The storybook builds — the smoke (NOT the per-rung apps gate).** `pnpm sb:build`
  (≡ `pnpm --filter @mercury/storybook build`) produces `apps/storybook/storybook-static/` and exits
  0. This is the Director-run **ship** smoke; it is **excluded** from the per-rung
  `pnpm --filter "./apps/*" build` so the standard ladder stays fast (INV-8).
- **INV-4 · The host resolves from source.** `apps/storybook/vite.config.ts` aliases
  `@mercury/ui|core|effector → ../../packages/<pkg>/src/index.ts` (byte-mirroring
  `apps/showcase/vite.config.ts`), and `@storybook/react-vite` consumes that alias (directly, or via a
  `viteFinal` merge in `main.ts`). No prebuilt `dist/` is required to render a story.
- **INV-5 · The theme decorator works.** A global decorator + a toolbar global render every story
  under a `light-theme` / `dark-theme` ancestor (the canon §0 dark flip is a `dark-theme` class on an
  ancestor; the token block lives at `packages/mercury-ui/src/styles/tokens.css` `.dark-theme`).
  Toggling the toolbar re-renders a story dark; the stylesheet (`@mercury/ui`'s `styles/index.css`) is
  loaded in the preview so tokens resolve. Observable: the Button story's surface inverts between the
  two toolbar states.
- **INV-6 · The stories glob is forward-compatible.** `.storybook/main.ts`'s `stories` covers
  **both** `packages/mercury-ui/**/*.stories.@(tsx|ts)` (filled this rung) **and**
  `apps/**/*.stories.@(tsx|ts)` (for mx.4), plus the host's own `stories/**` — even though mx.3 fills
  only the packages + host-local side. Grep `main.ts` shows all three roots.
- **INV-7 · Stories are grounded in the contract, not invented.** Each story's `argTypes`/controls
  are a restatement of the component's `<Name>.prompt.md`: every control name + its option set appears
  in that contract (and in the `.tsx` source it grounds). Icon's `name` options are the `IconName`
  set; Button's `variant`/`size` options are exactly the contract's enum language. No story uses a
  prop the source does not define, and no story cites `window.MercuryUI`/`_ds_bundle`.
- **INV-8 · Scope discipline (and the library gate stays green).** The rung touches only:
  `apps/storybook/**` (new); the two co-located `*.stories.tsx` + the host-local `Tokens.stories.tsx`;
  `mercury/.gitignore`; `mercury/package.json` (the `sb:build` script + the `build:apps` exclusion);
  `mercury/pnpm-lock.yaml` (Storybook devDeps); and **one additive `exclude` line** in
  `mercury/packages/mercury-ui/tsconfig.json` so the co-located stories never enter the library's own
  `tsc` (the library carries no Storybook types — without the exclude, `pnpm --filter @mercury/ui
  typecheck`/`build` would fail). No other production code; no app-screen stories; no second/third
  component story. The relocated `ds-bundle/` is git-invisible (gitignored).

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **`apps/storybook/` host** — `package.json` (Storybook devDeps + `@mercury/*` `workspace:*`) · `.storybook/main.ts` (`@storybook/react-vite`, CSF3, the forward-compatible stories glob) · `.storybook/preview.tsx` · `vite.config.ts` (source-resolution alias, mirrors showcase) · `tsconfig.json` | INV-3 + INV-4 + INV-6; the host builds and resolves packages from source |
| K-2 | The **three foundation stories** — `foundations/Icon/Icon.stories.tsx` · `actions/Button/Button.stories.tsx` (co-located) · host-local `stories/Tokens.stories.tsx`; CSF3; controls written from each `<Name>.prompt.md` | INV-7; each control name/option traces to the contract + `.tsx`; the three render in the host |
| K-3 | The **theme decorator** — a global decorator + a toolbar global that toggles a `light-theme`/`dark-theme` ancestor; the stylesheet loaded in preview | INV-5; a story re-renders dark from the toolbar |
| K-4 | The **gate / ignore / relocation** — the `sb:build` root script; the per-rung apps-gate **exclusion** of `@mercury/storybook` (and the `build:apps` script updated to match); `.gitignore` entries (`storybook-static/` + the relocated bundle); `ds-bundle/ → apps/storybook/ds-bundle/`; the `@mercury/ui` tsconfig stories-`exclude` | INV-2 + INV-3 + INV-8; the per-rung gate builds only the five and stays green; the host is the single `/design-sync` `localDir` |
| K-5 | The **forward mx.4 apps/* mandate** recorded in the spec (§6) — the host's glob already spans `apps/**/*.stories.tsx`; mx.4 fills the apps side **and** enhances `@mercury/ui` additively | §6 records the mandate quote-faithfully; the glob (INV-6) is built to receive it |

## 5 · The method (build order)

A small task DAG; the host lands first, the stories imitate the wiring it fixes.

1. **Scaffold the host.** Create `apps/storybook/{package.json, vite.config.ts, tsconfig.json}` —
   `package.json` name `@mercury/storybook`, `private`, `type: module`, `@mercury/*` as `workspace:*`,
   Storybook devDeps; `vite.config.ts` **byte-mirrors** `apps/showcase/vite.config.ts`'s alias block;
   `tsconfig.json` extends `../../tsconfig.base.json` with the same `paths` the apps use. Install
   (this writes `pnpm-lock.yaml` — a legitimate part of the commit; a real dep moved).
2. **Wire `.storybook/`.** `main.ts` — `@storybook/react-vite` framework, CSF3, the
   forward-compatible `stories` glob (host `stories/**` + `packages/mercury-ui/**` + `apps/**`), and
   the source-resolution path (the `vite.config.ts` auto-merge, or a `viteFinal` adding the same
   alias). `preview.tsx` — the global theme decorator + a `globalTypes` toolbar toggle, and the
   stylesheet load (`@mercury/ui` side-effect CSS, or `styles/index.css` directly).
3. **Isolate the co-located stories from the library `tsc`.** Add `"**/*.stories.tsx"` to
   `packages/mercury-ui/tsconfig.json`'s `exclude` (it propagates to `tsconfig.build.json`, which
   extends it) so `pnpm --filter @mercury/ui typecheck`/`build` never sees a Storybook import. The
   host's `tsconfig.json` covers the package stories for typechecking instead.
4. **Author the three stories** (controls from the contract, NO-INVENT):
   - `foundations/Icon/Icon.stories.tsx` — `argTypes`: `name` (select over the `IconName` set from
     [`Icon.prompt.md`](../../../../mercury/packages/mercury-ui/src/components/foundations/Icon/Icon.prompt.md)),
     `size` (number), `strokeWidth` (number). A default story + a grid story over the icon set.
   - `actions/Button/Button.stories.tsx` — `argTypes`: `variant` (the six-value select), `size`
     (`sm|md|lg`), `loading`/`fullWidth`/`disabled` (boolean), per
     [`Button.prompt.md`](../../../../mercury/packages/mercury-ui/src/components/actions/Button/Button.prompt.md);
     `leading`/`trailing` toggled via a story arg rendering an `<Icon />` (not a raw control). A
     variant-grid story.
   - host `stories/Tokens.stories.tsx` — `title: "Foundations/Tokens"`; renders the canon §6 token
     swatches (surfaces · text · borders · the status families) + the type ramp
     (`--font-primary|secondary|display`) from `rgb(var(--token))`, so the decorator visibly flips them
     dark.
5. **Gate + smoke.** Run the per-rung ladder (packages typecheck/build + the **five** apps build with
   the storybook exclusion + the barrel-diff), then the **separate** `pnpm sb:build` smoke. Both green.
6. **Relocate + ignore.** Point the `/design-sync` `localDir` at `apps/storybook/` (the `ds-bundle/`
   lives under the host); add the `.gitignore` entries. The full `/design-sync` pipeline re-align is
   **mx.6** — mx.3 only relocates the bundle and points the host folder at it.

Grounding sources (re-probe before trusting, per [`mx.3.llms.md`](./mx.3.llms.md)): the apps' vite
alias + tsconfig `paths`; the barrel `packages/mercury-ui/src/index.ts`; the theme mechanism in
`@mercury/effector`'s `theme.ts` + the `.dark-theme` block in `packages/mercury-ui/src/styles/tokens.css`;
the two contracts the Icon/Button stories restate.

## 6 · Dependencies

- **Hard-gates on:** `mx.2` (the 33 hand-authored `<Name>.prompt.md` contracts — met; each story is a
  rendered restatement of its component's contract) and `mx.1` (the grouped structure that gives each
  component a 1:1 story home — met).
- **Unblocks:** `mx.4` (component stories + the apps-side Pages + the additive library enhancement),
  then `mx.5` (Effector-powered stories) and `mx.6` (build/deploy + the `.design-sync` re-align).
- **Touches:** `mercury/apps/storybook/**` (new host); two co-located
  `packages/mercury-ui/src/components/{foundations/Icon,actions/Button}/<Name>.stories.tsx` + the
  host-local `apps/storybook/stories/Tokens.stories.tsx`; `mercury/package.json` (the `sb:build`
  script + the `build:apps` storybook exclusion); `mercury/.gitignore`;
  `mercury/packages/mercury-ui/tsconfig.json` (one additive stories-`exclude`); `mercury/pnpm-lock.yaml`
  (Storybook devDeps). The `ds-bundle/` relocates under the host (git-invisible). Canon §7 gains `D-9`
  at ship (the Director folds the canon/roadmap/progress).

### Forward: the apps/\* story mandate (mx.4)

mx.3's host is built so its `stories` glob already spans **both** `packages/mercury-ui/**/*.stories.tsx`
(filled this rung) **and** `apps/**/*.stories.tsx` (empty until mx.4). The apps-side fan-out is the
**mx.4** mandate — recorded forward here so the host is built to receive it, not built this rung. The
Operator's intent (quote-faithful):

> Each app under `apps/{catalogue,echomq,showcase,mobile,docs}` exports an `App` (verified: each has
> `src/App.tsx` + `src/main.tsx`). **mx.4** builds **brand-new Pages** based on the apps' **existing
> REAL composed screens**, wiring **REAL `@mercury/ui` components + `@mercury/effector`** plugged in.
> **MANDATORY: mx.4 ENHANCES `@mercury/ui`** (additively — master invariant: additions OK,
> removals/renames NOT) to cover **more controls, more cases, and more pages** that those screens need.

So mx.4 is where the apps-side stories land **and** where `@mercury/ui` grows (additively, under the
master invariant) to cover the controls/cases/pages those real screens need. mx.3 only proves the
host renders the library side; it adds no app story and no export.

> **Framing (propagate to any brief derived from this spec):** no gendered pronouns for agents; no
> perceptual or interior-state verbs; no first-person narration. State each surface as a contract
> (precondition / postcondition / invariant) so acceptance is at the boundary, not by re-reading the diff.
