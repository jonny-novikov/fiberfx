# Mercury UI — Program Progress Dashboard

**One-line state.** The docs floor (`mx.0` ✅) and **the structural rung `mx.1` ✅ are BUILT and
gate-green on this machine (committed)**: `@mercury/core` is extracted (the UI-free
foundation, source-consumed), `@mercury/ui` is regrouped the Claude-Design way
(`src/components/<group>/<Name>/`, the 5 aggregates split), the real source is salvaged out of the
(now-deleted) ephemeral `mercury-ds`, and the public barrel is **byte-stable + additive only** — the
barrel-diff shows all 91 prior exports preserved, +12 from the salvaged Accordion/Toggle/Pagination.
All four packages typecheck + build and all five apps build. **Movement II — the authored contract
layer (`mx.2`) — is now BUILT**: all 33 components carry a hand-authored, grounded, cross-linked
`<Name>.prompt.md` (coverage 33/33 · 75 cross-links resolve · no extractor framing · build
undisturbed), authored in 3 waves via `/mercury-ship mx.2`. **Movement III (the Storybook) has opened — `mx.3` ✅ BUILT:** the
`apps/storybook/` host (`@storybook/react-vite` 10.4.6) resolves the packages from source, with a
light/`dark-theme` decorator and the first three foundation stories (Icon · tokens · Button) writing
their controls from the mx.2 contracts. **`mx.4` ✅ BUILT:** every component now carries a co-located
CSF3 story (35 component homes + the host `Foundations/Tokens` = **36** registered by `sb:build`), and
the first additive growth landed — the **focused trio** (`Card` `title`/`actions` header props · new
`ListRow` · new `MoneyInput`), the barrel grown additively by four export names. **`mx.5` ✅ BUILT:**
a host-home `Effector/<Adapter>` story for all six `@mercury/effector` adapters (theme · toast ·
createForm · strength · createCooldown · formatter) wiring live Effector state into the real
components — **42** `sb:build` homes (36 + 6), the `@mercury/ui` surface frozen byte-identical, zero
host-config edit. **The tail was re-scoped 2026-06-29 (Operator-ruled):** `mx.6` (apps-side Pages) is
**DROPPED** ("skip apps"); the frontier is **`mx.7`** — import the Claude-Design bundle's net-new
components into `@mercury/ui`, a **5-batch epic** (`mx.7.1`–`mx.7.5`; 30 net-new + 2 folds; design
flows DOWN only) — then **`mx.8`** (enrich the stories) and **`mx.9`** (one comprehensive showcase app
replacing the retired apps). **All three tail triads are authored**; **`mx.7.1`+`mx.7.2` are BUILT** (gate-green 2026-06-30 — 15 components,
barrel 107→160, 0 removed). **`mx.7.3` was Operator-SPLIT 2026-06-30** into `mx.7.3.1` (DateField) · `mx.7.3.2`
(Calendar) · `mx.7.3.3` (the 4 selection composites + 2 folds) — the heavy date pair shed one machine each. The
frontier was **`mx.7.3.1`** (DateField) — now ✅ **BUILT 2026-06-30** (BUILD-GRADE; composes `@mercury/core`'s
new `useDateField` composable, A2 arm a; barrel 50→51 folders; a REAL aaw Trio in two
connection-death-resilient mars waves, x.md §5 LAW-1b). **`mx.7.3.2`** (Calendar) is now ✅ **BUILT 2026-06-30** (BUILD-GRADE; composes `@mercury/core`'s new `useCalendar` sibling composable, A2 arm a reusing the mx.7.3.1 date layer; barrel +1; a REAL aaw Trio + Apollo grid-machine verify in write-ready waves — Apollo's pass survived a parent-process death via recover-from-tree, x.md §5 LAW-1b). The frontier is **`mx.7.3.3`** (the 4 selection composites + 2 folds). **Solo mx.7.x reconcile (2026-06-30): CLEAN** — `mx.7.1`+`mx.7.2`
committed (`5f4847f1`/`acf538dd`), gate-green, §9-reconciled (barrel 107→160, 0 removed); the 7.3 split is
coherent; the date foundation is grounded (9 `internal/date-time` machinery files; the curated `useDateField`
composes them) and **INV-6 holds** (`@internationalized/date` lives on `@mercury/core`, never `@mercury/ui`) →
`mx.7.3.1` cleared to build. Forward
plan: [`mercury.roadmap.md`](./mercury.roadmap.md); architecture:
[`mercury.design.md`](./mercury.design.md).

---

## Legend

| Symbol | State | Meaning |
|---|---|---|
| ✅ | **SHIPPED** | committed / authored, gate-green on this machine |
| 🔨 | **IN FLIGHT** | building now — partial artifacts on disk, not yet committed |
| 📋 | **PLANNED** | fixed on the confirmed ladder; triad may or may not be authored |
| 🅿️ | **DEFERRED** | parked behind a sequencing boundary (Operator-revisable, not deleted) |
| 🔒 | **PROPOSED** | a decision awaiting Operator ratification at build time |

ANSI bars: `█` done · `░` remaining. A rung is one shippable increment.

---

## Development Progress

```text
Mercury UI · packages mercury-core (new) · mercury-ui · mercury-effector · destination: the DS Storybook

Movement I · the modular foundation & the Claude-Design structure
  mx.0   ✅ SHIPPED   ████████████████████  program docs floor — roadmap · design · progress · program · mx.1 triad (2026-06-28)
  mx.1   ✅ BUILT     ████████████████████  extract @mercury/core · regroup @mercury/ui <group>/<Name> · salvage+delete mercury-ds · barrel 91→103 additive (gate-green 2026-06-28; committed)

Movement II · the authored contract layer   (laddered behind mx.1 — grounds on the grouped structure)
  mx.2   ✅ BUILT     ████████████████████  33/33 hand-authored <Name>.prompt.md (grounded · enum language · Composition cross-links · real-call-site examples) + D-8 split ratified — gate-green 2026-06-28 (committed 5e229956)

Movement III · the Design System Storybook   (laddered behind mx.2 — each story writes its controls from the contract)
  mx.3   ✅ BUILT     ████████████████████  Storybook host (apps/storybook · @storybook/react-vite 10.4.6) + light/dark decorator + foundations stories (Icon · tokens · Button) — gate-green 2026-06-28 (/mercury-ship mx.3)
  mx.4   ✅ BUILT     ████████████████████  component stories (35 homes + Tokens = 36) + the focused-trio enhancement (Card title/actions · ListRow · MoneyInput; barrel +4) — gate-green 2026-06-29 (/mercury-ship mx.4)
  mx.5   ✅ BUILT     ████████████████████  effector-powered stories — all 6 adapters (theme · toast · createForm · strength · createCooldown · formatter); 42 homes; barrel byte-identical — gate-green 2026-06-29 (/mercury-ship mx.5)
  mx.6   ❌ DROPPED   ────────────────────  apps-side Pages — DROPPED 2026-06-29 (Operator "skip apps"); value moves to mx.9
  mx.7   📋 PLANNED   ░░░░░░░░░░░░░░░░░░░░  IMPORT the Claude-Design bundle's net-new components → @mercury/ui · 5-batch epic (30 net-new + 2 folds) · design flows DOWN only
    7.1  ✅ BUILT     ████████████████████  foundational primitives — Heading·Text·Label·IconButton·Separator (+5) — gate-green 2026-06-30
    7.2  ✅ BUILT     ████████████████████  feedback/display+layout — Callout·Spinner·Skeleton·Blockquote·DataList·Code·Kbd·AspectRatio·Collapsible·ScrollArea (+10) — gate-green 2026-06-30
    7.3  🪟 SPLIT     ────────────────────  input/selection composites — Operator-split 2026-06-30 into 7.3.1/7.3.2/7.3.3 (date pair shed one machine each)
    7.3.1 ✅ BUILT     ████████████████████  DateField — segmented spinbutton (+1) · composes @mercury/core useDateField (A2 arm a) · barrel 50→51 · REAL aaw Trio, 2 mars waves (LAW-1b) — gate-green 2026-06-30
    7.3.2 ✅ BUILT     ████████████████████  Calendar — month-grid picker (+1) · composes @mercury/core useCalendar (A2 arm a) · barrel +1 · grid machine — REAL aaw Trio + Apollo, write-ready waves (LAW-1b) — gate-green 2026-06-30
    7.3.3 📋 PLANNED  ░░░░░░░░░░░░░░░░░░░░  selection composites — CheckboxGroup·CheckboxCards·RadioGroup·RadioCards (+4) + folds Textarea/ToggleGroup
    7.4  📋 PLANNED   ░░░░░░░░░░░░░░░░░░░░  overlay-floor primitive + Dialog·AlertDialog·Popover (+3) · Squad-tier
    7.5  📋 PLANNED   ░░░░░░░░░░░░░░░░░░░░  menus/hover/nav (consume the floor) — Dropdown·ContextMenu·HoverCard·LinkPreview·Menubar·TabNav (+6) · Squad-tier
  mx.8   🪟 EPIC      ░░░░░░░░░░░░░░░░░░░░  enrich the stories — palette · roundings · variants · actions · scenes · now an EPIC, sliced by group (@mercury/ui surface frozen)
    8.1  ✅ BUILT     ████████████████████  foundations slice — Palette+Roundings brand-only toolbar globals (host-wide) · foundations variant audit (Heading `as` gap filled) · 2 foundations-in-context scenes (Profile·Article) · barrel byte-identical · K-4 deferred — gate-green 2026-07-01 (/mercury-ship mx.8.1)
    8.2  ✅ BUILT     ████████████████████  actions slice — Button·IconButton·Link variant audit (already full, mx.4) · K-4 ACTIVATED zero-dep fn() spy (SB10.4.6 core storybook/test; Fork-5 dissolved) · Scenes/Confirm · preview.tsx inherited/unedited · barrel byte-identical — gate-green 2026-07-01 (/mercury-ship mx.8.2)
    8.3+ 📋 PLANNED   ░░░░░░░░░░░░░░░░░░░░  remaining interactive groups' audit + scenes (selection · inputs · feedback · …), one per slice, inheriting the zero-dep fn() pattern, as mx.7.4/7.5 land the library
  mx.9   📋 PLANNED   ░░░░░░░░░░░░░░░░░░░░  ONE comprehensive showcase app (library · docs · API · do/don't · recipes) replacing retired apps · Squad-tier
```

---

## The master invariant

> **The public export surface of `@mercury/ui` holds.** Every named value/type from
> `src/index.ts` before a rung is still exported after it — same name, same type. Core extraction
> and regrouping are internal moves; the five apps never break. The mechanical check is the
> **barrel-diff** in every package rung's gate. Corollary: reusable components live ONLY in
> `packages/*`; apps only compose them.

---

## Roll-up

- **Landed.** `mx.0` — the docs floor. `mx.1` — the structural rung, **built + gate-green**
  (committed): `packages/mercury-core` (new, source-consumed, `react` peer + `@internationalized/date`),
  `@mercury/ui` regrouped into `components/<group>/<Name>/` (9 groups; the 5 aggregates split into
  per-component files), Accordion/Toggle/Pagination salvaged + exported, `mercury-ds` deleted, the
  `@mercury/core` alias added to all 5 apps (vite + tsconfig).
- **Gate evidence (2026-06-28, on this machine).** `pnpm --filter "./packages/*"` typecheck + build
  green (4 packages); `pnpm --filter "./apps/*"` typecheck + build green (5 apps); barrel-diff =
  **0 removed/renamed, +12 additive**; no `mercury-ds` reference remains; `@mercury/core` has no
  in-workspace dependency.
- **As-built notes.** `tokens.css` left untouched — the `mercury-ds/handoff/tokens.css` delta was
  only `/* @kind color */` design-sync annotations (identical values), so folding them would be
  harmful noise (do-no-harm). `src/css.d.ts` stayed in `@mercury/ui` (it declares `*.css` for the
  stylesheet import; the foundation needs no CSS ambient). The salvaged `Accordion` was hardened to
  React 19's nullable-`useRef().current` (the same `if (ref.current)` idiom the rest of the library
  already uses) — behaviour unchanged.
- **Landed (mx.2).** The contract layer — all 33 co-located `<Name>.prompt.md` hand-authored in 3
  waves (≤2 authors/wave) via `/mercury-ship mx.2`, grounded in the live `.tsx` + real call sites,
  cross-linked (75 links resolve); the app/library split ratified (`D-8`). Gate-green: coverage
  33/33, no extractor framing, packages typecheck+build + 5 apps build exit 0, barrel byte-identical.
- **Landed (mx.3).** The Storybook host (Movement III opener) — `apps/storybook/` (`@mercury/storybook`)
  on Storybook 10.4.6 (`@storybook/react-vite`), resolving `@mercury/*` from source via a vite alias
  mirroring the apps, a light/`dark-theme` decorator, and three foundation stories (Icon · tokens ·
  Button) writing their controls from the mx.2 contracts. Host **excluded from the per-rung `apps/*`
  gate** (a separate `pnpm sb:build` smoke); co-located `*.stories.tsx` excluded from `@mercury/ui`'s
  own `tsc` (`D-9`); `ds-bundle/` relocated under the host as the `/design-sync` `localDir`. Gate-green
  (Director-verified, independent re-run): packages typecheck+build, five apps build, barrel
  byte-identical, `sb:build` registers exactly the 3 stories, INV-8 proven load-bearing by a net-zero
  mutation spot-check.
- **Landed (mx.4).** Component stories — a co-located CSF3 `<Name>.stories.tsx` for every component
  (35 homes + `Foundations/Tokens` = 36) + the **focused-trio** additive growth (`Card` `title`/`actions`
  · new `ListRow` · new `MoneyInput`; barrel +4, additions-only) + the `sb:typecheck` gate addition
  (`D-10`). Gate-green 2026-06-29 (`/mercury-ship mx.4`, commit `5d075477`).
- **Landed (mx.5).** Effector-powered stories — a host-home `Effector/<Adapter>` story for all six
  `@mercury/effector` adapters (`theme · toast · createForm · strength · createCooldown · formatter`),
  each wiring live Effector state into the real `@mercury/ui` component(s); the `@mercury/ui` surface
  **frozen byte-identical** (no barrel change), zero host-config edit, 42 `sb:build` homes (36 + 6).
  Gate-green 2026-06-29 (`/mercury-ship mx.5`, `D-11`).
- **Next.** The Movement-III tail was re-scoped (Operator-ruled 2026-06-29): **`mx.6` (apps-side
  Pages) is DROPPED** ("skip apps"). The new-tail triads are **authored**: **`mx.7`** — import the
  Claude-Design bundle's net-new components into `@mercury/ui`, a **5-batch epic** (`mx.7.1`–`mx.7.5`;
  30 net-new + 2 folds; the overlay batch split 7.4 = the overlay-floor + `Dialog`/`AlertDialog`/
  `Popover`, 7.5 = the menus/hover/nav). Each batch ships through an **Operator → Agent → Agent** loop
  with the Operator in the seat between batches. Then **`mx.8`** (enrich the stories) and **`mx.9`**
  (one comprehensive showcase app replacing the retired apps). **`mx.7.1` is BUILT** (gate-green 2026-06-30;
  Fork A → `Separator` net-new + `Divider` kept; barrels 107→160, 0 removed; +15 components). **`mx.7.3` was
  Operator-SPLIT 2026-06-30** into 7.3.1 (DateField) / 7.3.2 (Calendar) / 7.3.3 (the 4 selection composites + 2
  folds); **`mx.7.3.1`** (DateField) is ✅ BUILT 2026-06-30 (BUILD-GRADE; composes `@mercury/core`'s new
`useDateField`; the connection-death deaths surfaced the write-ready-dispatch discipline, x.md §5 LAW-1b);
**`mx.7.3.2`** (Calendar) is ✅ BUILT 2026-06-30 (BUILD-GRADE; reuses the same date foundation via a sibling `useCalendar`, INV-6 intact); the frontier is **`mx.7.3.3`** (the 4 selection composites + 2 folds).
  Open forks for the later batches: the bundle's git fate · the overlay-floor ADR (7.4) · **the date-lib dependency
  (7.3.1 + 7.3.2 — grounded: no ready `@mercury/core` hook, arm (a)=from-scratch build; Operator rules per
  machine)** · mx.8's palette mechanism. Design flows DOWN from Claude Web only — `/design-sync` forbidden.
- **Deferred / open.** Widening `@mercury/core`'s public barrel beyond `cx` + `date` (the deeper
  foundation lives in core as files, surfaced when a consumer needs it); whether design tokens later
  migrate into `@mercury/core`; the `.design-sync` pipeline re-alignment (`mx.7` — its
  `config.json` targets `@mercury/ui`, unaffected by the `mercury-ds` deletion). See the roadmap's
  **Seams & open decisions**.
