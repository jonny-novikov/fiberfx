# mx.8.2 · Storybook enrichment — the actions slice (variant audit · zero-dep `fn()` action spies · actions-in-context scene · zero-dep gate)

> **Status: ✅ BUILT (gate-green 2026-07-01; `/mercury-ship mx.8.2`; Trio; K-4 activated zero-dep + LAW-1a mutation; see §As-built) — the SECOND slice of the mx.8 epic (actions); the FIRST interactive group; RISK
> NORMAL; the `@mercury/ui` surface is FROZEN byte-identical.** mx.8 ("enrich the Storybook stories" — palette ·
> roundings · variant switching · actions · real-world scenes) is whole-library; the Operator scoped mx.8.1 to
> the **`foundations`** group (shipped, commit `422ba2c6`) and scopes this increment to the **`actions`** group.
> This slice **INHERITS** the mx.8.1 host-wide Palette + Roundings globals (consumed, not rebuilt) and
> **ACTIVATES** the mx.8 **K-4 (actions)** dimension that mx.8.1 deferred as N/A — `actions` is the first group
> whose components declare interaction handlers. It DERIVES the shared mechanism from
> [`../mx.8/mx.8.md`](../mx.8/mx.8.md) (§6.3 the variant audit, §6.4 actions, §6.5 scenes, §7 the invariants) and
> pins the **actions specifics** — it does not restate mx.8's §6.1/§6.2 palette/roundings tables (those are
> mx.8.1's, inherited here).
>
> **The decisions this slice is authored TO (RULED — not re-litigated here):**
> - **[Operator · R1] Slice = the `actions` group ONLY: `Button · IconButton · Link` (3 components).** Cadence
>   confirmed: mx.8.3+ continues **one interactive group per slice** (selection · inputs · feedback · …).
> - **[Operator · R2] Actions (K-4) = a ZERO-DEP `fn()` spy — mx.8 Fork-5 DISSOLVES at ship.** Storybook
>   **10.4.6** bundles the spy + logger + Actions panel in **core**: `storybook/test` (exports `fn`) and
>   `storybook/actions` (exports `action`) BOTH resolve as core subpaths (Director-verified via `require.resolve`
>   from `apps/storybook/`), and `.storybook/main.ts` `addons: []` is fine (the Actions panel is SB10 core, no
>   addon). So K-4 wires with **NO** `apps/storybook/package.json` / `pnpm-lock.yaml` / `.storybook/main.ts` edit.
>   Mechanism: `import { fn } from "storybook/test";` then `args: { onClick: fn() }` on the story `meta`. INV-7
>   (actions fire) is proven **by inspection in the running Storybook** (the mx.8.1 browser-residual pattern), NOT
>   a headless play-function assertion (that path needs `@storybook/test-runner`, a devDep declined this rung).
>   This is the **"re-sharpened at ship"** resolution of mx.8 §A Fork-5 (the actions dependency-fork) + a
>   candidate `D-` for the Director's roadmap fold.
> - **[Director · D-a] Palette + Roundings globals are INHERITED from mx.8.1 (host-wide), CONSUMED not rebuilt.**
>   `apps/storybook/.storybook/preview.tsx` is **NOT edited** this rung — the mx.8.1 globals already re-skin
>   *every* story, including these three. This is the **key contrast with mx.8.1** (which BUILT the globals).
>   mx.8.1-INV6 already proved the globals drive `--bg-brand` on a `Button` (an actions-group component)
>   book-wide, so mx.8.2 **inherits that proof**; a **light re-confirm** on the actions surface suffices (D4). If
>   a genuine gap surfaces, FLAG it — do not silently edit `preview.tsx`.
> - **[Director · D-b] Rung id = mx.8.2** (mx.8 is the parent epic; mx.8.1 = the foundations slice, shipped
>   `422ba2c6`).
> - **[Steward] Homes:** the actions-led scene lives host-home at `apps/storybook/stories/scenes/`; the variant
>   audit EXTENDS the co-located `actions/<Name>/<Name>.stories.tsx`; the `fn()` spy rides the story `meta.args`
>   (not an `argType` control — slot/handler controls stay `control: false`).
> - **[inherited mx.8 · INV-8] Design flows DOWN** — no `/design-sync`, no `DesignSync`, no push to Claude Web.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · parent epic (the shared mechanism):
[`../mx.8/mx.8.md`](../mx.8/mx.8.md) + [`../mx.8/mx.8.llms.md`](../mx.8/mx.8.llms.md) · sibling slice (the
template + the inherited globals): [`../mx.8.1/mx.8.1.md`](../mx.8.1/mx.8.1.md) · acceptance:
[`mx.8.2.stories.md`](./mx.8.2.stories.md) · build brief: [`mx.8.2.llms.md`](./mx.8.2.llms.md) · approach:
[`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md).

---

## Goal

After mx.8.2, the **three `actions` component stories** — `Button` · `IconButton` · `Link` — expose their **full
exported-union control surface** (every variant/size/shape switchable from the Controls panel; the mx.4
grid/state stories kept) AND wire a **zero-dependency `fn()` action spy** on their interaction handlers so every
click **logs to the Storybook core Actions panel**; a host-home **actions-led `Scenes/<Name>`** screen composes
real `@mercury/ui` exports (the actions components LEAD), grounded in a cited real screen. The whole diff is the
three actions stories, the new scene, and this triad — the **`@mercury/ui` barrel is byte-identical to HEAD**,
`preview.tsx` is **UNEDITED** (the mx.8.1 Palette/Roundings globals are inherited and re-confirmed on the actions
surface, not rebuilt), and **no** `apps/storybook/package.json` / `pnpm-lock.yaml` / `.storybook/main.ts` edit
(the mx.8 Fork-5 zero-dep resolution). The load-bearing proofs: **INV-7** — the `fn()` spy fires a real
Actions-panel entry in the running Storybook (a spy imported but never wired to a rendered handler is a LOUD
failure); and **INV-6** — the zero-dep invariant (the `fn` import resolves as a Storybook 10.4.6 **core** subpath;
the git diff touches no dependency manifest).

## Rationale (5W)

- **Why** — A design-system Storybook earns trust when a viewer can *interrogate* the surface. mx.8.1 made that
  true for the presentational `foundations`; `actions` is the first **interactive** group, so it is where two new
  affordances land: switching a control across its every exported variant (the audit), and confirming the control
  actually *does something* — a click registers, visibly, on the Actions panel (the spy). Because Storybook
  10.4.6 ships the spy + Actions panel in core, the mx.8 actions dependency-fork (Fork-5) dissolves into a
  zero-dependency wiring — the honest, minimal path.
- **What** — The `actions` variant/options audit (the three stories expose their full exported-union surface,
  mx.4 grids kept); the K-4 actions wiring (a `fn()` spy on each component's handler, logging to the SB core
  Actions panel, zero new dependency); ≥1 host-home actions-led scene; and the gate, including the **INV-7**
  running-SB liveness check that the spies fire and the **INV-6** zero-dep proof — with the inherited globals
  re-confirmed on the actions surface.
- **Who** — *Authored by* Claude Code as Director-led architect (this triad) + the mx.8.2 build. *Consumed by*
  (1) Mercury contributors + the Claude Design agent interrogating the actions components across variants and
  confirming their handlers fire; (2) the later mx.8 slices (mx.8.3+), which inherit this zero-dep `fn()` pattern
  and apply it to the next interactive group (selection · inputs · …); (3) mx.9 (the showcase), which composes
  the scenes into the shipped site.
- **When** — Now — mx.8.2 is the second slice of the mx.8 epic, decomposed by the Operator to the `actions`
  group; it is the first slice to activate the actions dimension mx.8.1 deferred.
- **Where** — the three `packages/mercury-ui/src/components/actions/<Name>/<Name>.stories.tsx` (audited + spied —
  stories only, no surface change), `apps/storybook/stories/scenes/` (the new actions-led scene), and
  `docs/mercury/specs/mx.8.2/`. `apps/storybook/.storybook/preview.tsx` is **NOT** edited (globals inherited);
  `.storybook/main.ts` / `package.json` / `pnpm-lock.yaml` are **NOT** edited (zero-dep).

## Scope

**In.**
- **D1 — the `actions` variant/options audit (the three stories).** Each of `Button` · `IconButton` · `Link`
  stories exposes its full exported-union control surface (the audit table in §Deliverables). Slot/handler props
  stay `control: false`; boolean props get `control: "boolean"`; the mx.4 grid/state stories are kept.
- **D2 — the K-4 actions wiring (zero-dep `fn()` spies).** Each story's `meta` imports `fn` from the Storybook
  **core** subpath `storybook/test` and sets a spy on the component's handler arg (`args: { onClick: fn() }`),
  wired to the rendered handler so an interaction logs to the SB core Actions panel. **No** new dependency.
- **D3 — the actions-in-context scene.** ≥1 host-home `apps/storybook/stories/scenes/<Name>.stories.tsx`,
  **actions-led** (Button/IconButton/Link carry the screen), composing **only** real `@mercury/ui` exports,
  grounded in a cited real screen; not colliding with the shipped `Scenes/Profile` / `Scenes/Article`.
- **D4 — the gate is green, the spies fire, zero new dependency, the globals re-confirmed.** The full gate
  ladder exits 0; the barrel is byte-identical; the INV-7 running-SB liveness check is POSITIVE (a click logs an
  Actions-panel entry); the INV-6 zero-dep proof holds (`fn` resolves core; no manifest touched); and the
  inherited globals are re-confirmed on the actions surface (Palette=green ⇒ a `Button variant="primary"`
  computes green-9, inheriting mx.8.1-INV6 with `preview.tsx` unedited).

**Out.**
- **The Palette + Roundings globals are NOT rebuilt** — `apps/storybook/.storybook/preview.tsx` is inherited
  from mx.8.1 host-wide and **not edited** (D-a). A genuine gap is FLAGGED, never silently patched.
- **No new dependency** — no `storybook/test` install, no `@storybook/test-runner`, no
  `@storybook/addon-actions`; `apps/storybook/package.json` / `pnpm-lock.yaml` / `.storybook/main.ts` untouched
  (the `fn`/Actions panel are SB 10.4.6 core; INV-6).
- **No headless play-function assertion** — INV-7 is proven by inspection in the running Storybook (the
  mx.8.1 browser-residual pattern); adding `@storybook/test-runner` is out of scope (a devDep declined).
- Any `@mercury/ui` surface change — no new export, no component `.tsx`/`index.ts`/`.prompt.md`/style edit (the
  barrel is byte-frozen; the only `mercury-ui/src/**` edits are `actions/*/*.stories.tsx`).
- The non-actions component groups' story enrichment (later mx.8 slices, mx.8.3+).
- The showcase application composing the scenes (mx.9); effector-wired scenes (mx.5's `stories/effector/` —
  mx.8.2 scenes are presentational, no `@mercury/effector`).
- `/design-sync`, the `DesignSync` MCP, any push to Claude Web (design flows DOWN).
- Editing the roadmap/design/epic (the Director folds the mx.8/mx.8.2 rows + a `D-` per ruled decision — chiefly
  the Fork-5 resolution — at ship).

## Deliverables

Each is a provable unit (the check that proves it is its Invariant; the story that accepts it is its US).

- **mx.8.2-D1 — the `actions` variant/options audit (three stories).** The three
  `actions/<Name>/<Name>.stories.tsx` expose the full exported-union control surface. **Reconcile finding
  (verified against the live `.tsx` + `.stories.tsx` this rung): all three are ALREADY full-union complete
  (mx.4).** Unlike mx.8.1's Heading `as` gap, there is **no top-up** — the exported unions are already exposed
  as typed `select`/`inline-radio` controls, slots are already `control: false`, booleans are already
  `control: "boolean"`. D1 is therefore a **VERIFY** (assert full coverage; INV-3 is the check that proves it),
  and the only per-story edit this rung is D2's `fn()` spy. The audit table (the exported unions are truth, cited
  to the `.tsx`):

  | Component | Handler (K-4 target) | Exported-union controls — already full (mx.4) | Boolean controls | Slots / handlers `control: false` | Audit status |
  |---|---|---|---|---|---|
  | `Button` | `onClick` — inherited via `extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "type">` (`Button.tsx:14`) | `variant` → `ButtonVariant` (6: `primary` · `secondary` · `outline` · `ghost` · `destructive` · `inverse`, `Button.tsx:5-11`) · `size` → `ButtonSize` (`sm` · `md` · `lg`) | `loading` · `fullWidth` · `disabled` | `leading` · `trailing` | ✅ already-full — add only the `fn()` spy (D2) |
  | `IconButton` | `onClick` — inherited via the same `extends Omit<…>` (`IconButton.tsx:11`) | `variant` → `IconButtonVariant` (5: `primary` · `secondary` · `outline` · `ghost` · `destructive`) · `size` → `IconButtonSize` (`sm` · `md` · `lg`) · `shape` → `IconButtonShape` (`circle` · `square`, `IconButton.tsx:7-9`) | `disabled` | `icon` — a curated glyph `select` (`IconName = keyof ICONS` widens to `string`, so the list is a MANUAL NO-INVENT set, mx.8.1-INV8, not a typed union) | ✅ already-full — add only the `fn()` spy (D2) |
  | `Link` | `onClick?: (e: MouseEvent) => void` — **explicit** (`Link.tsx:15`) | `size` → `LinkSize` (`sm` · `md`, `Link.tsx:4`) · `type` → `"button" \| "submit" \| "reset"` | `muted` · `disabled` | `leading` · `trailing` · `onClick` (already `control: false`, `Link.stories.tsx:31`) | ✅ already-full — add only the `fn()` spy (D2; `onClick` already `control: false`) |

  The mx.4 grid/state stories (`Button`: `Variants` · `WithIcon`; `IconButton`: `Variants` · `SizesAndShapes`;
  `Link`: `Sizes` · `States`) and each `Playground` are kept. (≙ mx.8 K-3.)
- **mx.8.2-D2 — the K-4 actions wiring (zero-dep `fn()` spies).** Each of the three stories' `meta` carries
  `import { fn } from "storybook/test";` and a spy on the handler arg (`args: { onClick: fn() }`), wired to the
  rendered component's handler (CSF3 auto-spread, or an explicit `onClick={args.onClick}` in a custom render), so
  activating the control logs to the SB **core** Actions panel. Handler-arg controls stay `control: false` (the
  spy is on `args`, not a control widget) — matching `Link.stories.tsx`'s existing `onClick: { control: false }`.
  No new dependency. (≙ mx.8 K-4.)
- **mx.8.2-D3 — the actions-in-context scene.** ≥1 host-home CSF3 scene story under
  `apps/storybook/stories/scenes/` (`title: "Scenes/<Name>"`, no `component:` field, the `Tokens`/mx.8.1 scene
  shape), **actions-led** (Button/IconButton/Link carry the screen) and composing a few real `@mercury/ui`
  exports for realism. It imports **only** `@mercury/ui` (+ `react`/`@storybook/react-vite`), carries a lead
  comment naming the cited real screen/pattern, and does not collide with `Scenes/Profile` / `Scenes/Article`.

  **The scene is a FORK the Director ratifies** (frame, propose, do not decide — §Forks). Venus recommends
  **one**, with a grounded alternative:

  - **RECOMMENDED — `Scenes/Confirm`** (a confirmation / action-sheet screen; the actions LEAD): an
    **`IconButton`** header toolbar (icon-only, its natural usage — e.g. `close` · `copy` · `cog` from the
    curated glyph set) · a `Heading` + summary `Text` of what is being confirmed (presentational, **no
    inputs**) · a footer **`Button`** action bar exercising the variant spread (`primary` "Confirm & send" ·
    `outline` "Cancel" · `ghost` "Save as draft" · `destructive` "Cancel transfer") · **`Link`** affordances
    ("Change recipient" · muted "How fees work"). Realism: `Card` · `Divider`/`Separator` · `Badge`. Grounded
    in `apps/mobile/src/screens/Send.tsx:56-63` (the real `outline` Cancel + `primary` Send footer action bar)
    + `apps/mobile/src/screens/Home.tsx:33` (the inline "See all" `<a onClick>` → `Link`). This is the cleanest
    "actions lead" — the action bar IS the screen — and the only real icon-only `IconButton` usage.
  - **ALTERNATIVE — `Scenes/Wallet`** (an account/wallet actions hub): a quick-actions cluster (`Button` with a
    leading `<Icon/>`, or `IconButton`s) LEADS · a "See all" / "Manage cards" `Link` · a `Button` CTA row.
    Grounded in `apps/mobile/src/screens/Home.tsx:10-35` (the `em-quick-row` quick-actions + "See all") +
    `apps/mobile/src/screens/Wallet.tsx` (the card list). Slightly less icon-only-faithful (the real quick
    actions carry a visible label ⇒ `Button`-with-leading-`Icon`, not `IconButton`).

  Either composes **only** real `@mercury/ui` exports, host-home, `title: "Scenes/<Name>"`, no `component:`
  field, no `Scenes/Profile`/`Scenes/Article` collision. (≙ mx.8 K-5.)
- **mx.8.2-D4 — the gate is green, the spies fire, zero new dependency, the globals re-confirmed.** The full
  gate ladder exits 0; the barrel is byte-identical; the INV-7 running-SB liveness check is POSITIVE (a click
  on each spied control logs an Actions-panel entry — a wired-but-dead spy is a LOUD failure); the INV-6 zero-dep
  proof holds (`storybook/test` + `storybook/actions` resolve as SB 10.4.6 core subpaths; no dependency manifest
  in the diff); and the inherited globals are re-confirmed on the actions surface (Palette=green ⇒ a `Button
  variant="primary"` computes green-9 `rgb(48, 164, 108)`, inheriting mx.8.1-INV6 with `preview.tsx` unedited).
  (≙ mx.8 K-6.)

**Coverage:** mx.8.2-D1 → US1 · mx.8.2-D2 → US2 · mx.8.2-D3 → US3 · mx.8.2-D4 → US4.

## Invariants

Runnable checks (run from `mercury/`). Each is the gate that proves its property, not prose.

- **mx.8.2-INV1 — the barrel is byte-identical (the master invariant, strongest form).**
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` → **empty**. mx.8.2
  adds no `@mercury/ui` export.
- **mx.8.2-INV2 — the production surface is untouched; `preview.tsx` is UNEDITED (the inherited-globals
  contrast); only actions stories + the new scene + this triad change.** `git diff --name-only` shows **no**
  `packages/mercury-ui/src/**` edit **except** `components/actions/*/*.stories.tsx`; every other changed path is
  `apps/storybook/stories/scenes/**`, `docs/mercury/specs/mx.8.2/**`, or — **AS-BUILT** — the one host-tsc
  `paths` alias in `apps/storybook/tsconfig.json` (a compile-time type-alias for the first `storybook/test`
  import, mirroring the line-12 `@storybook/react-vite` idiom; NOT a dependency, so INV-6 holds — §As-built L-2).
  **`apps/storybook/.storybook/preview.tsx`
  is NOT in the diff** (the Palette/Roundings globals are inherited host-wide from mx.8.1). No component
  `.tsx`/`index.ts`/`.prompt.md`/`styles/**` edit. Any unavoidable other change is flagged + surfaced, never
  silent.
- **mx.8.2-INV3 — `sb:typecheck` clean (the authoritative NO-INVENT gate).** `pnpm sb:typecheck` exits 0 — the
  host `tsc` is the only one that checks the enriched stories + scenes (the library `tsc` excludes
  `**/*.stories.tsx`, mx.3 D-9). Every option array typed by a real **literal** exported union (`ButtonVariant` ·
  `ButtonSize` · `IconButtonVariant` · `IconButtonSize` · `IconButtonShape` · `LinkSize`) rejects an invented
  member; every scene import resolves to a real barrel export.
- **mx.8.2-INV4 — `sb:build` registers the prior homes unchanged + the new `Scenes/*` home.** `pnpm sb:build`
  exits 0; the built index lists every prior component/foundation/effector/scene home **unchanged** (the actions
  basic stories are enriched *in place*, not added — the component-home count does not move) and adds the new
  `Scenes/<Name>` home.
- **mx.8.2-INV5 — packages typecheck/build + the product apps build, undisturbed.**
  `pnpm --filter "./packages/*" typecheck` = 0 · `pnpm --filter "./packages/*" build` = 0 ·
  `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` = 0. The app set is glob-driven and reconciled
  at build; mx.8.2 must not regress the app build.
- **mx.8.2-INV6 — the zero-dep invariant (the mx.8 Fork-5 resolution; gate-liveness).** `git diff` touches
  **no** `apps/storybook/package.json` / `pnpm-lock.yaml` / `apps/storybook/.storybook/main.ts`, and the `fn`
  import is the Storybook 10.4.6 **core** subpath `storybook/test` (not a devDep) — proven by
  `node -e "require.resolve('storybook/test'); require.resolve('storybook/actions')"` resolving from
  `apps/storybook/` (both under the core `storybook` package), and by the import specifier being exactly
  `"storybook/test"` in each story. The Actions panel is SB10 core (`main.ts` `addons: []` unchanged).
- **mx.8.2-INV7 — the actions FIRE (the K-4 liveness; a wired-but-dead spy is a LOUD failure).** Each of the
  three actions stories sets a `fn()` spy on its handler arg (`meta.args.onClick = fn()`) **and** the story's
  effective render passes that arg to the rendered component's handler — CSF3 auto-spread (`component` set, no
  custom `render`), or an explicit `onClick={args.onClick}` where a custom render exists (verify `Link`, which
  carries `onClick: { control: false }`). PRECONDITION: the spy is on `args`, not an `argType` control.
  POSTCONDITION: activating the control in the running Storybook logs an entry to the SB **core** Actions panel
  (proven by inspection in the running SB — the mx.8.1 browser-residual pattern — NOT a headless
  `@storybook/test-runner` play assertion). A spy present in `args` but **not reaching a rendered handler** (a
  custom render that drops it) is a **no-op — a LOUD failure, never a silent pass**.
- **mx.8.2-INV8 — NO-INVENT + token discipline + design-flows-DOWN; slots stay `control: false`.** Every prop
  name/enum member in the audit + scene is real (traced from the live `.tsx`); the exported **literal** unions
  are typecheck-narrowed — an invented option fails INV-3. Slot/handler props (`leading`/`trailing`/`icon`/
  `onClick`) keep `control: false`. Greps (run at ship over the touched paths), all **empty**:
  `grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/storybook/stories/scenes packages/mercury-ui/src/components/actions/*/*.stories.tsx`
  · `grep -rn "window.MercuryUI\|_ds_bundle\|design-sync\|DesignSync" apps/storybook/stories packages/mercury-ui/src/components/actions`.
  Design flows DOWN.

## Definition of Done

- [ ] **mx.8.2-D1** — the three `actions` stories expose their full exported-union control surface (per the audit
  table); slots stay `control: false`, booleans get `control: "boolean"`; the mx.4 grids are kept (US1; INV3,
  INV8).
- [ ] **mx.8.2-D2** — each story `meta` imports `fn` from `storybook/test` and sets `args: { onClick: fn() }`
  wired to the rendered handler; handler-arg controls stay `control: false` (US2; INV6, INV7).
- [ ] **mx.8.2-D3** — ≥1 host-home actions-led scene composes only real `@mercury/ui` exports and cites a real
  screen; `sb:build` registers the new `Scenes/*` home; no collision with `Scenes/Profile`/`Scenes/Article`
  (US3; INV4, INV8).
- [ ] **mx.8.2-D4** — the full gate ladder exits 0; the barrel diff is empty; INV-7 is POSITIVE (each spied
  control logs an Actions-panel entry in the running SB); INV-6 holds (`fn` resolves core, no manifest in the
  diff); the inherited globals re-confirm (Palette=green ⇒ Button green-9 `rgb(48,164,108)`, `preview.tsx`
  unedited) (US4; INV1, INV2, INV5, INV6).
- [ ] **Zero-dep, grounded** — the `fn` import is a core subpath and no dependency manifest is in the diff (the
  Fork-5 resolution is a proven finding, not an assumption) (US4; INV6).
- [ ] **Voice / framing** — no perceptual or interior-state verb on a software component; components
  render / resolve / fire / log / compose / compute; no first person outside the stories' Connextra "I want".

## As-built (mx.8.2 — shipped 2026-07-01, `/mercury-ship mx.8.2`, Trio: `venus-mercury` + `mars-mercury`)

**BUILD-GRADE — the Director's independent verify passed** (a fresh gate re-run + the LAW-1a mutation, not the
peers' word). The measured surface (the commit pathspec): the three `actions/*/*.stories.tsx` (**+8 lines — the
`fn()` spy only**; D1 was a VERIFY — the audit was already full from mx.4), the new
`apps/storybook/stories/scenes/Confirm.stories.tsx`, the host-tsc `apps/storybook/tsconfig.json` (**+1 `paths`
alias** — L-2 below), this triad, and the roadmap/progress fold. Barrel **byte-identical**; `preview.tsx`
**unedited** (the mx.8.1 globals inherited).

- **D- (the mx.8 §A Fork-5 dissolution) — actions = ZERO-DEP.** Fork-5 anticipated an Operator dependency-fork
  for the actions mechanism ("none is installed today"). At ship it **dissolves**: Storybook **10.4.6** ships the
  `fn` spy + the `action` logger + the Actions panel in **core** (`storybook/test` + `storybook/actions` resolve
  as core subpaths; `main.ts` `addons: []` unchanged). K-4 wired with **no** `package.json`/`pnpm-lock.yaml`/
  `main.ts` edit — INV-6 holds. (Venus L-1.)
- **L-2 (the one as-built deviation from the declared touched-set) — the host-tsc `paths` alias.** mx.8.2 is the
  first slice to `import { fn } from "storybook/test"`. The host `tsc` (`apps/storybook/tsconfig.json`, whose
  `include` glob pulls in `packages/mercury-ui/**/*.stories.tsx`) resolves a bare specifier from the **importing
  file's** dir upward — and `storybook` is symlinked only under `apps/storybook/node_modules` (pnpm strict, not
  hoisted), so `storybook/test`'s types are unreachable from the mercury-ui tree (`TS2307`). The fix mirrors the
  **existing** line-12 `@storybook/react-vite` idiom exactly:
  `"storybook/test": ["./node_modules/storybook/dist/test/index.d.ts"]` (the target `.d.ts` is real, 54 KB). It
  is a **compile-time type-alias, NOT a dependency** (zero `package.json`/`pnpm-lock`/`main.ts` change, INV-6
  preserved) and it is **group-agnostic** (the `include` covers every mercury-ui story), so mx.8.3+ inherit it.
  **The asymmetry to remember:** node's runtime resolver (from the consuming app dir) resolved `storybook/test`
  **green** while `tsc` (from the source-file dir) was **red** — a `require.resolve` check is not a proxy for
  `tsc` reachability on a core-subpath import.
- **The scene — `Scenes/Confirm`** (Director-ratified over `Scenes/Wallet`): the actions-led confirmation /
  action-sheet — an icon-only `IconButton` toolbar (`copy · cog · close`) + a presentational `Heading`/`Text`/
  `Card` summary (no inputs) + a footer `Button` action bar spanning the variant spread
  (`primary · outline · ghost · destructive`) + `Link` affordances; grounded in
  `apps/mobile/src/screens/Send.tsx:56-63` + `Home.tsx:33`. Composes only real `@mercury/ui` exports,
  token-styled (no hex).
- **Gate (independently reproduced):** `sb:typecheck` 0 · `@mercury/*` typecheck + build green · `sb:build`
  (registers `Scenes/Confirm`; prior homes unchanged) · barrel byte-identical · zero-dep confirmed
  (`storybook/test` + `storybook/actions` resolve core; no manifest in the diff) · NO-INVENT clean **including**
  the manual Icon-glyph set-equality (`copy · cog · close · check` are all real `ICONS` keys — `IconName` widens
  to `string`, so `sb:typecheck` cannot vet glyphs) · **LAW-1a mutation** bit (an injected bogus `ButtonVariant`
  → `TS2322` → reverted net-zero). **INV-7 wiring** proven (each `Playground` is `{}` — no custom render — so
  CSF3 auto-spreads `{...args}` onto the rendered handler); the live-click Actions-panel entry + the
  `Palette=green ⇒ green-9` computed-style are the browser residuals (per the ruled inspection posture — no
  `@storybook/test-runner`).

Stories: [mx.8.2.stories.md](./mx.8.2.stories.md)  ·  Agent brief: [mx.8.2.llms.md](./mx.8.2.llms.md)  ·  Index: [mx.8.md](../mx.8/mx.8.md)  ·  Sibling slice: [mx.8.1.md](../mx.8.1/mx.8.1.md)  ·  Approach: [../../../aaw/aaw.specs-approach.md](../../../aaw/aaw.specs-approach.md).
