# MX.6 · Apps-side Page stories

> **Status: 📋 PLANNED — spec authored, four forks OPEN (Director ratifies, Operator rules Fork D).**
> The fourth rung of **Movement III (the Design System Storybook)**. mx.3 landed the **host**
> (`apps/storybook/`, Storybook 10.4.6, source-resolved, a light/`dark-theme` decorator); mx.4 gave the
> **library** a co-located `<Name>.stories.tsx` per component (35 + the host `Tokens` = **36** homes) and
> grew the barrel additively (the focused trio); mx.5 added the **state** side — six host-home
> `Effector/<Adapter>` stories wiring live Effector state into the real components (**42** homes, the
> `@mercury/ui` surface frozen byte-identical). mx.6 adds the **application** side: page-level stories that
> render the five product apps' **real screens** — assembled from the real `@mercury/ui` + `@mercury/effector`
> surface — inside the Storybook host. The proof a browser reads: *these whole product pages are composed
> entirely from the design system, no app-specific reusable component required* (the §2 corollary, the canon
> §0 token discipline, the §1 "effector plugs the state from outside" contract — all visible on a real screen.)
>
> **mx.6 ships STORIES, not an app rewrite.** The roadmap mx.6 row records that the five apps are "being
> completely rewritten with Mercury DS and retired when the mx program finishes" — that is **ongoing program
> context**, not an mx.6 deliverable. The five apps **already compose Mercury DS today** (every app imports
> `@mercury/ui` + `@mercury/effector`; §3). mx.6's whole code diff is **new `*.stories.tsx` files** (+ the
> two config edits Fork D requires) — **no app source is rewritten, no screen is changed.**
>
> **Risk: NORMAL — and the `@mercury/ui` public surface is FROZEN byte-identical this rung (Fork C).** Like
> mx.5, mx.6 adds no `@mercury/ui` surface (the apps already render on the current barrel — §3 verified). The
> master invariant for this run is the **strongest** form — `packages/mercury-ui/src/index.ts` byte-identical
> to HEAD. Load-bearing hazards: (a) **the NO-INVENT type gate is a no-op for a story in `apps/*/src/` until
> the host tsc is taught to see it** — Fork D, the load-bearing reconcile finding; (b) a story citing a
> component prop or effector symbol the source does not define — caught by the host `tsc` *once Fork D closes
> the gate*; (c) a per-app stylesheet imported globally in the shared Storybook preview leaking `html/body/*`
> rules across the other 42 homes — checked, BENIGN (§6.6); (d) a story mutating a module-global app store at
> render scope, leaking the screen-state into sibling stories — avoided by the App-level granularity (Fork A).
>
> **The decisions this rung carries (Operator-ruled scope — recorded VERBATIM for ratification at ship):**
> - **mx.6 = apps-side Page stories ONLY.** Page-level `*.stories.tsx` that render the five apps' real
>   screens on the real `@mercury/ui` + `@mercury/effector` surface, inside the Storybook host.
> - **The five apps `showcase/echomq/mobile/catalogue/docs` are in scope; `codemojex-node/apps/economy` is
>   OUT of scope** (the host glob `apps/*/src/**` does not reach it — §4).
> - **mx.6 does NOT touch `@mercury/ui`'s public surface** — the barrel stays byte-identical (Fork C).
> - **mx.6 does NOT rewrite app source** — only NEW story files are added; an existing app `.tsx`/`.css` is
>   read and composed, never edited. (Fork D's two **config** edits — a host `tsconfig` include line + a
>   one-line `exclude` in each app `tsconfig` — are config, not source, and are contingent on the Fork-D ruling.)
> - **Build/deploy + design-sync re-align → mx.7** (the program's last rung).

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · dashboard:
[`../../mercury.progress.md`](../../mercury.progress.md) · prior triad:
[`../mx.5/mx.5.md`](../mx.5/mx.5.md) · method:
[`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md) · contract method:
[`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) · acceptance:
[`mx.6.stories.md`](./mx.6.stories.md) · build context: [`mx.6.llms.md`](./mx.6.llms.md).

---

## A · The forks — Director ratifies; Fork D the Operator rules

Four calls remain. Fork D is **load-bearing** (the reconcile found the type gate is a no-op for an
`apps/*/src/` story; making it live touches host/app config that mx.5 ruled "zero edit" — an Operator
scope call). Forks A/B/C carry a Venus recommendation (each first below = recommended).

### Fork D — apps-side story location + the NO-INVENT type gate (LOAD-BEARING — Operator rules)

- **Rationale.** The Director's grounding said "the host glob already reaches `apps/*/src/**`; no host-config
  edit needed (like mx.5)." The reconcile finds that is **half true**: the **sb:build glob** reaches
  `apps/*/src/**` (`apps/storybook/.storybook/main.ts` line `"../../*/src/**/*.stories.@(tsx|ts)"`) — so a
  story placed there **renders**; but **no gate leg type-checks it**:
  - `pnpm sb:typecheck` (the host `tsc`, the authoritative NO-INVENT gate, `D-10`) — host
    `apps/storybook/tsconfig.json` `include` is `{.storybook/**, stories/**, ../../packages/mercury-ui/src/**/*.stories.tsx}`; it does **not** reach `apps/*/src`.
  - `pnpm --filter "./packages/*" typecheck/build` — packages only.
  - `pnpm --filter "./apps/*" build` — each app's `build` is a **bare `vite build`** (no `tsc`); a
    `.stories.tsx` not imported by `main.tsx` is **never in the build graph**, and `vite build` does not
    type-check regardless.
  - `pnpm sb:build` — Storybook/esbuild **strips types**; a type error does **not** fail it.
  So **D-10's `sb:typecheck` NO-INVENT gate is a no-op for an `apps/*/src/` story** unless the host `tsc` is
  taught to see it. **Worse:** each app's own `tsc` (`tsconfig.json` `include: ["src"]`) **would** compile a
  co-located story, but every app **lacks `@storybook/react-vite`** (no dep, no `paths` entry — verified
  across all five) — so the `import type { Meta, StoryObj } from "@storybook/react-vite"` is unresolvable and
  co-locating a story would turn each app's `typecheck` **RED** (and `pnpm -r typecheck`).
- **5W.** *Who:* the Director + the Operator (host owner). *What:* where the page stories live + how the
  authoritative story `tsc` covers them. *When:* this rung (gate-liveness is a pre-build decision). *Where:*
  `apps/*/src/` (co-located) vs `apps/storybook/stories/apps/` (host home). *Why:* a gate that does not RUN
  on the new stories proves nothing (the charter's "a gate must specify its own liveness — a no-op must not
  satisfy its letter").
- **Steelman D1 — co-locate in `apps/*/src/` + close the gate with two config edits (RECOMMENDED).** Honor
  the Operator-stated model (page stories beside the screens they compose; they retire with the app). Two
  **config-only** edits make the gate live and keep app `typecheck` green:
  (a) extend the host `apps/storybook/tsconfig.json` `include` with **`"../*/src/**/*.stories.tsx"`** (base =
      `apps/storybook/`, so `../*` = `apps/*`; **note** this differs from `main.ts`'s `../../*` because the
      tsconfig resolves from `apps/storybook/` while the glob resolves from `apps/storybook/.storybook/`) — the
      host `tsc` (`pnpm sb:typecheck`) becomes the authoritative NO-INVENT gate for the apps-side stories, exactly
      as it is for the library stories (`D-9`/`D-10`: the host `tsc` is the only `tsc` that checks stories);
  (b) add **`"**/*.stories.tsx"`** to each of the five app `tsconfig.json` `exclude` arrays — the **exact analog
      of `D-9`** (`packages/mercury-ui/tsconfig.json` already excludes `["**/*.stories.tsx","**/*.stories.ts"]`
      from the library `tsc`) — so the app's own `tsc` ignores stories and stays green.
  Cost: 1 host `tsconfig` line + 5 app `tsconfig` `exclude` lines (config, not source). The sb:build glob needs
  **no** edit (it already reaches `apps/*/src/**`).
- **Steelman D2 — host-home `apps/storybook/stories/apps/<App>.stories.tsx` (mirror mx.5).** Place the page
  stories under the host, where `stories/**` is **already** in the host `tsc` `include` (NO-INVENT gate live)
  **and** the sb:build glob. **Zero** app-config edit; **zero** host-config edit. Cost: the stories live
  *outside* the apps (contradicts the co-located model), and import the app `<App/>`/screens via deep relative
  paths (`../../../<app>/src/App`). Cleanest gate story; weakest fidelity to the Operator's stated model.
- **Steelman D3 — co-locate + add `@storybook/react-vite` to all five apps + gate via per-app `typecheck`.**
  Heaviest: a dev-dep + a `paths` entry in five apps that are **being retired**, plus adding
  `pnpm --filter "./apps/*" typecheck` to the ladder. Wasteful investment in soon-deleted apps. Not recommended.
- **Steward / recommendation: D1.** Honors the co-located model, makes the authoritative gate **live** with
  two minimal config edits, keeps every app `typecheck` green, and mirrors the `D-9` precedent. **Operator
  rules** (it relaxes mx.5's "zero host-config edit" — a scope call). *(If the Operator prefers no app/host
  config churn, D2 is the clean fallback.)*

### Fork A — story granularity: **App-level (one `<App/>` story per app — RECOMMENDED)** vs per-screen

- **Rationale.** The five apps split into two shapes (§3): three carry a screens/views/pages dir
  (`showcase` 19 pages, `echomq` 5 views, `mobile` 6 screens) driven by an in-app store router; two are
  monolithic single-`<App/>` apps with internal page state (`catalogue` 130 lines, `docs` 309 lines) and **no
  screens dir**. The granularity question: one story per **app** (render the whole `<App/>`) or one story per
  **screen**.
- **5W.** *Who:* the story authors + the Director. *What:* the home count + what each home shows. *When:* this
  rung. *Where:* `apps/*/src/`. *Why:* fidelity to "real screens", redundancy with mx.4, the store-leak hazard.
- **Steelman (App-level, RECOMMENDED).** One `App.stories.tsx` per app, `title: "Apps/<App>"`, a single
  `Default` story rendering the real `<App/>`. This:
  (1) composes the app's **real screens** — the App's own router/switch renders them all on the real Mercury
      surface, in their real chrome — fully satisfying the mandate;
  (2) is **navigable/interactive** (the in-app effector store drives it) — a richer demo than a static screen
      snapshot, and the only honest treatment of the two **monolithic** apps (which have no screens dir);
  (3) avoids **redundancy** — `showcase`'s 12 `pages/components/*` are component-documentation pages that would
      duplicate the mx.4 component stories as 12 noisy homes; the `<App/>` shows them in context instead;
  (4) avoids the **store-leak hazard** — no story forces a module-global store value to select a screen (Fork B
      / §6.6); the App's defaults render and the viewer navigates within the one story;
  (5) is the **smallest, lowest-risk** diff — 5 files for five soon-retired apps. **Homes: 42 → 47 (+5).**
- **Steelman (per-screen).** One story per screen file (`Apps/<App>/<Screen>`): ~19 + 5 + 6 = **30** screen
  homes for the three multi-screen apps + 2 App-level for the monolithic apps (no screens dir) ≈ **+32 → 74
  homes**. Richer sidebar browsing (each screen its own home). Costs: (i) redundancy — `showcase`'s 12
  component pages re-document mx.4; (ii) the **store-leak hazard** — a screen that only renders correctly under
  a specific store value (e.g. `mobile` `Login` needs `$authed === false`; an `echomq` view needs `$view` set)
  must mutate a module-global store, leaking into sibling stories unless reset per story; (iii) a much larger
  diff on apps that will be deleted at program end.
- **Steward / recommendation: App-level (5 files, 42 → 47).** *(A hybrid — App-level for all five **plus** the
  three `showcase` patterns + `mobile` `Login` as standalone "pattern" stories — is available if the Operator
  wants a few marquee screens surfaced individually; start App-level, fan out only on request.)*

### Fork B — screen-isolation strategy: **render the whole `<App/>` + import the app CSS (RECOMMENDED)**

- **Rationale.** A screen renders faithfully only with (i) its **state** and (ii) its **CSS**. Reconciled:
  **state is module-global** — every app store is `createStore`/`createEvent`/`createForm` at module scope
  read via `useUnit` (`effector` is global, not React-context), so a screen reads its store **with no
  Provider** (verified across `showcase/echomq/mobile` stores). **CSS is the real binding** — each app's
  layout/chrome classes live in `apps/<app>/src/<app>.css`, imported **only in `main.tsx`** (which Storybook
  never runs); without it the screen is unstyled.
- **5W.** *Who:* the story authors. *What:* how a story makes a screen render. *When:* this rung. *Where:* the
  story render + a CSS import. *Why:* fidelity with the least re-implementation.
- **Steelman (render `<App/>` + import the app CSS, RECOMMENDED).** Pairs with Fork A's App-level: the story
  renders the real `<App/>` (full chrome + screens + store, self-contained — no Provider) and imports the app
  stylesheet at the top of the story file (`import "./<app>.css"`; `catalogue` has **no** CSS file — inline
  styles only — so it imports none). Zero chrome re-implementation; the screen is exactly what the app ships.
- **Steelman (a per-app decorator wrapping a bare screen).** For per-screen granularity, a decorator must
  reproduce each app's frame skeleton (`mobile` `.em-frame-wrap`>`.em-phone`>`.em-body`; `echomq`
  `.eqd`>`.eqd-main`>`.eqd-scroll`; `showcase` `<Shell>`). That is re-implementing chrome per app — brittle,
  and only needed if Fork A goes per-screen.
- **Steelman (bare screen, no chrome).** Render `<Home/>` alone: missing the phone frame / dashboard chrome —
  looks broken. Rejected.
- **Steward / recommendation: render `<App/>` + import the app CSS** (pairs with App-level Fork A).

### Fork C — barrel posture: **freeze `@mercury/ui` byte-identical (RECOMMENDED)** vs permit additive growth

- **Rationale.** mx.4 grew the barrel (the focused trio); mx.5 froze it. mx.6's apps **already render** on the
  current `@mercury/ui` surface (§3 — each app imports only existing exports; no app references a missing
  component). A story that renders the existing app needs **no new component**.
- **Steelman (freeze, RECOMMENDED).** No `@mercury/ui` `.tsx`/`index.ts` edit; `index.ts` byte-identical to
  HEAD (the strongest master-invariant form). The whole code diff is the new story files (+ Fork D's config).
- **Steelman (permit additive growth).** Only if grounding finds a screen reaching for a surface the library
  lacks — none found (§3). If a build genuinely needs one, **STOP and surface it** as an additive-growth fork
  (the mx.4 pattern), never grow the barrel silently.
- **Steward / recommendation: FREEZE byte-identical** (no gap found).

---

## 0 · The slice — what mx.6 builds, and why apps-side Page stories

Movement III's destination is a complete, browsable Design System Storybook. mx.3 proved the host renders the
library from source under a theme decorator; mx.4 gave **every component** a home; mx.5 added the **live-state**
dimension. The dimension still empty: a **whole product page**. The Storybook today shows components and
adapters in isolation — it never shows a *real screen* assembled from them. The five workspace apps are exactly
that proof already (every one imports `@mercury/ui` + `@mercury/effector` and composes real screens), but none
of them is registered in the host. mx.6 registers them: **page-level stories that render the apps' real screens
inside the Storybook**, so a browser reads the design system at the scale a product ships — pages, not parts.

What mx.6 is **not**: it adds **no** `@mercury/ui` surface (the barrel is byte-identical — Fork C), **rewrites
no** app source (only new story files — the roadmap's "apps rewritten + retired" line is ongoing context, not
this rung), and includes **no** apps-side production change. The whole code diff is the new `*.stories.tsx`
files plus, under the recommended Fork D, two config edits that make the NO-INVENT type gate live.

## 1 · Goal

After mx.6, the Storybook carries an **`Apps/`** story group with **one page-level home per app** —
`Catalogue · Docs · EchoMQ · Mobile · Showcase` — each rendering the app's **real `<App/>`** (its real screens,
chrome, and store-driven navigation) on the real `@mercury/ui` + `@mercury/effector` surface, with the app's
own stylesheet brought into the story. Concretely (under the recommended Forks A/B/C/D-D1): five CSF3 files at
`apps/<app>/src/App.stories.tsx`, each `title: "Apps/<App>"`, a `Default` story rendering `<App/>` (+ the app
CSS import where the app has one). `pnpm sb:build` registers **exactly the prior 42 homes + the 5 new
`Apps/*` homes = 47** and exits 0; `pnpm sb:typecheck` exits 0 **and type-checks the new stories** (the gate
made live by Fork D); the three packages typecheck/build and the five product apps build (and **`typecheck`**
clean) undisturbed. **The `@mercury/ui` barrel is byte-identical to HEAD; no `@mercury/ui` `.tsx`/`index.ts` is
edited; no app source `.tsx`/`.css` is edited** (only the new story files + Fork D's config edits).

## 2 · Rationale (5W)

- **Why.** A design system is only fully documented when a browser can see a *whole page* built from it — the
  scale at which it actually ships. The canon's load-bearing claims (§2 corollary "an app never houses a
  reusable component"; §0 token discipline; §1 "effector plugs the state from outside") are each best proven on
  a real screen, not a part. The apps already embody the proof; mx.6 makes it visible in the Storybook before
  the apps retire (mx.7 closes the program).
- **What.** Five page-level CSF3 stories, one per app, each rendering the real `<App/>` (real screens + chrome +
  store) on the real Mercury surface, with the app stylesheet imported.
- **Who.** *Authored by* Claude Code as Director-led architect (this triad) + the story-author wave(s).
  *Consumed by* — (1) Mercury contributors + the Claude Design agent browsing real-page compositions; (2) the
  canon §2/§0/§1 contracts, which these stories make demonstrable at page scale; (3) mx.7 (the static build +
  design-sync re-align), which ships the resulting Storybook.
- **When.** Now — Movement III, after the live-state stories (mx.5) and before build/deploy (mx.7).
- **Where.** Only `apps/*/src/*.stories.tsx` (five new files) + `docs/mercury/specs/mx.6/` + (Fork D-D1) one
  host `tsconfig` line + five app `tsconfig` `exclude` lines.

## 3 · The apps + screens inventory (reconciled — read the source, not the roadmap)

Each app **already composes `@mercury/ui` + `@mercury/effector`** today; the table is the ground truth a story
renders. "State" = module-global effector stores (no Provider). "CSS to bring" = the app stylesheet imported
only in `main.tsx` (Storybook never runs `main.tsx`, so the story brings it). All paths verified.

| App (`name`) | Shape | Real screens (count) | Composes (Mercury) | App state | CSS to bring | App-level story file (NEW) |
|---|---|---|---|---|---|---|
| **showcase** (`@mercury/showcase`) | Shell + store router | `pages/` = Overview + `components/*` (12) + `foundations/*` (3) + `patterns/*` (3) = **19** | `@mercury/ui` (Button/Card/Input/Modal/…), `@mercury/effector` (`createForm`/`toast`/`Toaster`) | `store.ts` (`$route`/`$progress`/`$inviteOpen`/`$dangerOpen`) | `./showcase.css` | `apps/showcase/src/App.stories.tsx` |
| **echomq** (`@mercury/echomq`) | dashboard + Tabs router | `views/` = Overview · Jobs · Groups · Batches · Processors = **5** | `@mercury/ui` (Tabs/Card/Segmented/Search/Table/…), `@mercury/effector` (`initTheme`/`setTheme`) | `store.ts` (`$view`/`$selected`/`$range`/`$procRunning`) | `./echomq.css` | `apps/echomq/src/App.stories.tsx` |
| **mobile** (`@mercury/mobile`) | phone frame + tab/auth router | `screens/` = Home · Activity · Wallet · Profile · Send · Login = **6** | `@mercury/ui` (Button/Input/…), `@mercury/effector` (`createForm`/`Toaster`/`initTheme`) | `store.ts` (`$authed`/`$tab`/`$sending`/`$filter`/`sendForm`) | `./mobile.css` | `apps/mobile/src/App.stories.tsx` |
| **catalogue** (`@mercury/catalogue`) | **monolithic** `<App/>` (130 lines), internal `useState` page | none (single `App.tsx`; pages = `colors`/`type`/`components`) | `@mercury/ui` (Button/Chip/Tag/Badge/Avatar/Alert/Progress/Tabs/Card/Segmented/Icon), `@mercury/effector` (`useTheme`/`setTheme`) | local `useState` + effector theme | **none** (inline styles + tokens; `main.tsx` imports no CSS) | `apps/catalogue/src/App.stories.tsx` |
| **docs** (`@mercury/docs`) | **monolithic** `<App/>` (309 lines), internal `useState` section + scroll-spy | none (single `App.tsx`; doc sections) | `@mercury/ui` (Button/Chip/Tag/Switch/Input/Alert/Card/Segmented/Badge/Progress/Icon), `@mercury/effector` (`useTheme`/`setTheme`/`toast`/`Toaster`/`createForm`) | local `useState` + effector | `./docs.css` | `apps/docs/src/App.stories.tsx` |

**Barrel-gap check (Fork C):** every `@mercury/ui` name each app imports is an existing export — no app reaches
for a missing component. mx.6 needs **no** additive growth; the barrel stays byte-identical.

## 4 · Host wiring — RECONCILED: the glob is ready; the type gate is NOT

| Host claim | As-built (cited) | Verdict |
|---|---|---|
| The sb:build glob reaches `apps/*/src/**` | `apps/storybook/.storybook/main.ts` `"../../*/src/**/*.stories.@(tsx\|ts)"` (resolves from `.storybook/`) | **MATCH** — a story in `apps/*/src/` is registered by sb:build with no edit |
| `codemojex-node/apps/economy` is excluded | it lives under `codemojex-node/apps/`, not `apps/` — the glob `apps/*/src/**` does not reach it | **MATCH** — economy stays out of scope |
| The host `tsc` type-checks `apps/*/src/` stories | `apps/storybook/tsconfig.json` `include` = `{.storybook/**, stories/**, ../../packages/mercury-ui/src/**/*.stories.tsx}` — **no `apps/*/src`** | **MISSING** → **Fork D**: add `"../*/src/**/*.stories.tsx"` to the host `include` |
| Each app's `tsc` tolerates a co-located story | every app `tsconfig.json` `include: ["src"]`, **no `@storybook/react-vite`** dep/`paths` (all five) | **MISSING** → **Fork D**: add `"**/*.stories.tsx"` to each app `tsconfig` `exclude` (the `D-9` analog) |
| Host depends on `@mercury/effector`/`effector`/`effector-react` | `apps/storybook/package.json` deps (mx.5 §4) | MATCH — present (apps that use effector wire it themselves; stories import from the app, not new) |

> **The reconcile reverses the Director's "host needs nothing (like mx.5)".** mx.5's stories lived in
> `stories/effector/`, already inside the host `include`; mx.6's stories live in `apps/*/src/`, which the host
> `include` does not reach **and** which each app's own `tsc` would choke on. The gate is a no-op until Fork D
> closes it — surfaced, not silently patched.

## 5 · Deliverables

- **K-1 — five App-level page stories** (Fork A), one per app, at `apps/<app>/src/App.stories.tsx`. Each CSF3
  (`Meta`/`StoryObj`), `title: "Apps/<App>"`, a `Default` story rendering the real `<App/>`.
- **K-2 — each story renders the app's REAL screens, not a re-build** (Fork B). The story imports `{ App } from
  "./App"` and renders it; the app's module-global effector store drives navigation (no Provider). The story
  authors **no** chrome and **no** screen — it composes the shipped `<App/>`.
- **K-3 — each story brings the app's CSS** (Fork B). `import "./<app>.css"` at the top of the story file for
  the four apps that have one (`showcase`/`echomq`/`mobile`/`docs`); `catalogue` imports none (it has no CSS
  file — inline styles + tokens). The leak is benign (§6.6).
- **K-4 — the `@mercury/ui` public surface is byte-identical** (Fork C). No edit to
  `packages/mercury-ui/src/index.ts` or any `packages/mercury-ui/src/components/**` `.tsx`/`index.ts`. (Any
  unavoidable non-export-changing fix is flagged and surfaced.)
- **K-5 — no app SOURCE is rewritten.** No edit to any existing app `.tsx`/`.css`. The only app-dir changes are
  the five new `App.stories.tsx` files and (Fork D-D1) the one-line `exclude` per app `tsconfig.json`.
- **K-6 — the NO-INVENT type gate is made LIVE** (Fork D-D1). The host `apps/storybook/tsconfig.json` `include`
  gains `"../*/src/**/*.stories.tsx"`, so `pnpm sb:typecheck` **type-checks the five new stories** (the gate's
  own liveness — a present story is compiled with a positive proof, not skipped). Each app `tsconfig.json`
  `exclude` gains `"**/*.stories.tsx"`, so app `typecheck` stays green.
- **K-7 — the gate is green** (§7): `sb:typecheck` 0 (covering the new stories) · `sb:build` exit 0 registering
  **47** homes (prior 42 + 5 new `Apps/*`) · `pnpm --filter "./packages/*" typecheck`/`build` 0 · the five
  product apps `build` **and** `typecheck` 0 · barrel byte-identical · the NO-INVENT + token greps empty.

**Coverage:** K-1 → S-1..S-5 ; K-2 → S-1..S-5 ; K-3 → S-1..S-5 ; K-4 → S-6 ; K-5 → S-7 ; K-6 → S-8 ; K-7 → S-9.

## 6 · The per-app render map (grounded — `.tsx` + the app store cited)

Each row: the entry the story renders → the real screens it surfaces → the isolation needs (CSS / state). Every
fact verified in source; **no prop, screen, or store invented.**

### 6.1 · Showcase → `<App/>` (`Shell` + 19 store-routed pages)
- **Render:** `import { App } from "./App"` → `<App/>`. `App` renders `<Shell><Active/></Shell>`, `Active` from
  `PAGES[useRoute()]` (`apps/showcase/src/App.tsx`). `Shell` owns the sidebar/topbar/scroll + two store-wired
  `Modal`s + a `<Toaster position="bottom-end" />` + a live-progress `setInterval` ticker (cleaned on unmount).
- **State:** `apps/showcase/src/store.ts` — `$route` (persisted to `localStorage`), `$progress`, `$inviteOpen`,
  `$dangerOpen` — all module-global; the story renders with `$route`'s default (`overview` or the persisted
  value) and the viewer navigates via the sidebar within the one story.
- **CSS:** `import "./showcase.css"`.

### 6.2 · EchoMQ → `<App/>` (dashboard + 5 `Tabs`-routed views)
- **Render:** `<App/>` renders `.eqd` frame (`Sidebar`/`Topbar`/`MetricStrip`) + a `Tabs<View>` over
  `views/{Overview,Jobs,Groups,Batches,Processors}` (`apps/echomq/src/App.tsx`). Views compose `Card`/`Segmented`/
  `Search`/`Table`/`Progress`/`Switch` + the app's own `charts/` (Donut/Throughput).
- **State:** `apps/echomq/src/store.ts` — `$view` (default `"Overview"`), `$range`, `$selected`, `$run`,
  `$procRunning` — module-global; the viewer switches views via `Tabs` within the story.
- **CSS:** `import "./echomq.css"`. **Theme:** the app's `main.tsx` defaults to dark; the story does **not** run
  `main.tsx`, so the Storybook theme toolbar (mx.3 decorator) governs — acceptable (the dashboard reads tokens).

### 6.3 · Mobile → `<App/>` (phone frame + 6 screens, auth + tab router)
- **Render:** `<App/>` renders `.em-frame-wrap`>`.em-phone` with `StatusBar` + (authed) `Header`/screen/`BottomNav`
  or (not) `Login`, + a `<Toaster position="bottom-center" />` (`apps/mobile/src/App.tsx`). `$authed` defaults
  **true** → `Home` shows; the viewer reaches `Login` by logging out within the story (Profile → logout). `Send`
  is an overlay over the tab router.
- **State:** `apps/mobile/src/store.ts` — `$authed`/`$tab`/`$sending`/`$filter` + `sendForm` (`createForm`) —
  module-global. **Leak-free at App-level:** screens call setters only in `onClick` handlers, never at render
  scope (verified), so the story mutates no store on mount.
- **CSS:** `import "./mobile.css"`.

### 6.4 · Catalogue → `<App/>` (monolithic, internal `useState` pages)
- **Render:** `<App/>` is a single 130-line component — a sidebar + `colors`/`type`/`components` pages switched
  by local `useState` (`apps/catalogue/src/App.tsx`), composing `Button`/`Chip`/`Tag`/`Badge`/`Avatar`/`Alert`/
  `Progress`/`Tabs`/`Card`/`Segmented`/`Icon` + a `Segmented` theme switch (`useTheme`/`setTheme`).
- **State:** local `useState` + the effector theme store (module-global). **CSS:** **none** — `main.tsx` imports
  no stylesheet; the app uses inline styles + `rgb(var(--token))` only (the preview already loads the `@mercury/ui`
  stylesheet for tokens). The story imports **no** app CSS.

### 6.5 · Docs → `<App/>` (monolithic, internal `useState` section + scroll-spy)
- **Render:** `<App/>` is a single 309-line component — a doc site (nav + sections + an in-page `createForm`
  settings demo + `toast`/`Toaster`) with a scroll-spy `useEffect` (a `window` scroll listener, cleaned on
  unmount) (`apps/docs/src/App.tsx`), composing `Button`/`Chip`/`Tag`/`Switch`/`Input`/`Alert`/`Card`/`Segmented`/
  `Badge`/`Progress`/`Icon`.
- **State:** local `useState` + module-scope `createForm` + the effector theme store. **CSS:** `import "./docs.css"`.

### 6.6 · The two checked hazards (handled, not forks)
- **CSS leak (benign).** A story `import "./<app>.css"` is **global** in the shared Storybook runtime (every
  story module loads once). The only global rules in the four app stylesheets are `html,body { margin:0;
  height:100% }` (matches Storybook defaults), `#root { height:100% }` (**no-op** — Storybook renders into
  `#storybook-root`), and `*::-webkit-scrollbar` (cosmetic, webkit-only). Cross-app class overlap is tiny and
  compound-scoped (`.is-active` always under a prefixed parent; `.eyebrow` scoped `.dx-hero .eyebrow` in docs);
  chrome classes are app-prefixed (`.eqd-*`/`.em-*`/`.dx-*`) or local. **Verdict: benign** — recorded as INV-7,
  not a fork. (Per-screen granularity would worsen nothing here.)
- **Store leak (avoided).** A module-global app store mutated at a story's render scope would leak the screen
  state into sibling stories. App-level (Fork A) renders `<App/>` at its store **defaults** and never mutates a
  store on mount (§6.3) — leak-free. (This hazard is the chief reason per-screen granularity carries more risk.)

## 7 · Invariants — as runnable gates

Run from `mercury/`. Each invariant is the check that proves it.

- **INV-1 — the barrel is byte-identical (master invariant, strongest form).**
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` → **empty**.
- **INV-2 — no app SOURCE and no `@mercury/ui` source is rewritten.** `git diff --name-only` shows **no** edit
  under `packages/mercury-ui/src/` and **no** edit to any existing app `.tsx`/`.css`. The only added/changed
  paths: the five new `apps/*/src/App.stories.tsx`, the host `apps/storybook/tsconfig.json` (one `include`
  line), the five app `tsconfig.json` (one `exclude` line each), and this triad. (Any unavoidable
  non-export-changing component fix is flagged + surfaced — never silent.)
- **INV-3 — `sb:typecheck` clean AND covering the new stories (the authoritative NO-INVENT gate, made live).**
  `pnpm sb:typecheck` exits 0; the host `tsconfig` `include` now matches `apps/*/src/**/*.stories.tsx` (proof
  of liveness: an invented prop in an apps-side story FAILS this run — the gate must RUN on the new files, not
  skip them). This is the only `tsc` that checks stories (library excludes them — `D-9`; apps exclude them — Fork D).
- **INV-4 — `sb:build` registers exactly the prior 42 homes + the 5 new `Apps/*` homes (= 47).**
  `pnpm sb:build` exits 0; the built index lists `Apps/Catalogue`, `Apps/Docs`, `Apps/EchoMQ`, `Apps/Mobile`,
  `Apps/Showcase` **and** all 42 prior homes unchanged.
- **INV-5 — packages typecheck/build + the five product apps build AND typecheck, undisturbed.**
  `pnpm --filter "./packages/*" typecheck` = 0 · `pnpm --filter "./packages/*" build` = 0 ·
  `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` = 0 ·
  `pnpm --filter "./apps/*" --filter "!@mercury/storybook" typecheck` = 0 (proves Fork D's app `exclude` keeps
  each app `tsc` green with a co-located story present).
- **INV-6 — NO-INVENT.** Every screen/`<App/>` the story renders is a real app entry; the story authors no
  component and no fabricated prop; no story contains `window.MercuryUI` or `_ds_bundle`. Grep:
  `grep -rln "window.MercuryUI\|_ds_bundle" apps/*/src/*.stories.tsx` → **empty**.
- **INV-7 — token discipline (over the STORY files only).** The new story files author no raw hex; any layout
  color is `rgb(var(--token))` (canon §6). Grep **the story files**, not the app source (existing app screens
  may carry a hex — e.g. `mobile/src/screens/Login.tsx` `color:"#fff"` — which mx.6 neither adds nor edits):
  `grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/*/src/*.stories.tsx` → **empty**.

## 8 · Out of scope (explicit)

- Any `@mercury/ui` component change, new export, or `index.ts` edit (mx.6 freezes the surface — Fork C).
- Any **rewrite** of app source `.tsx`/`.css` (mx.6 adds only new story files; the "apps rewritten + retired"
  roadmap line is ongoing context, not this rung).
- `codemojex-node/apps/economy` (outside the `apps/*/src/**` glob — out of scope, Director-confirmed).
- Build/deploy of the static Storybook + the design-sync re-align (**mx.7**, Operator-ruled).
- Editing the roadmap/progress/design — the Director folds at ship: a new `D-12` (mx.6, with the ratified
  Fork-D arm), the roadmap mx.6 row → BUILT, and the **stale gate-§ note** (roadmap "How the program runs"
  step 3 says `pnpm -r typecheck`/`pnpm -r build` where the island gate is `pnpm --filter "./packages/*"` — a
  do-no-harm canon delta for the Director, not fixed here).

## 9 · As-built (Apollo / the verifier — filled post-build)

> To be completed post-build: classify every promise (K-1..K-7, INV-1..INV-7, S-1..S-9) MATCH/STALE/INVENTED/
> MISSING; record the ratified Fork-D arm + the exact files shipped; reproduce the gate (all EXIT 0) including
> the `sb:build` 47-home count and the liveness proof that `sb:typecheck` actually compiles the new stories
> (a deliberate bad-prop mutation must turn it RED, then revert). Record any pathspec-hygiene note (e.g. the
> Operator's out-of-band `mercury/vitest.config.ts` edit, which is NOT mx.6 and stays out of the commit).
