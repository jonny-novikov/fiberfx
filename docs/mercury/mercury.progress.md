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
connection-death-resilient mars waves, x.md §5 LAW-1b). **`mx.7.3.2`** (Calendar) is now ✅ **BUILT 2026-06-30** (BUILD-GRADE; composes `@mercury/core`'s new `useCalendar` sibling composable, A2 arm a reusing the mx.7.3.1 date layer; barrel +1; a REAL aaw Trio + Apollo grid-machine verify in write-ready waves — Apollo's pass survived a parent-process death via recover-from-tree, x.md §5 LAW-1b). **`mx.7.3.3`** (the 4 selection composites + 2 folds) is now ✅ **BUILT 2026-07-01** (Duo+; compose the live `Checkbox`/`Radio`, A1; folds widen `Textarea`/`ToggleGroup`; barrel +4/−0 → 65 folders) — **closing the mx.7 import epic**; the frontier moves to **`mx.9`** (the showcase). **Solo mx.7.x reconcile (2026-06-30): CLEAN** — `mx.7.1`+`mx.7.2`
committed (`5f4847f1`/`acf538dd`), gate-green, §9-reconciled (barrel 107→160, 0 removed); the 7.3 split is
coherent; the date foundation is grounded (9 `internal/date-time` machinery files; the curated `useDateField`
composes them) and **INV-6 holds** (`@internationalized/date` lives on `@mercury/core`, never `@mercury/ui`) →
`mx.7.3.1` cleared to build. **`mx.9` was Operator-SPLIT 2026-07-02** into `mx.9.1`–`mx.9.5` (the
layered-engine axis; forks A–E RULED; the `mx.9.1`/`mx.9.2` triads BUILD-READY, `mx.9.3`–`mx.9.5`
SOLID-FORWARD; the Squad verifier mandate lands at the `mx.9.5` closer). **`mx.9.1` (the spine) is now
✅ BUILT 2026-07-02** (Duo+, pass-1 clean; the 7-file `apps/showcase` scaffold byte-mirroring `apps/echomq`
+ the `storybook/test` no-op shim wired in the vite alias; `dev:showcase` :5176; the apps gate 2→3 with the
barrel byte-identical; LAW-1a alias-mutation net-zero; the lockfile importer block deferred to the sibling
program's commit — regenerable). **`mx.9.2` (the derived registry + shell) is now ✅ BUILT 2026-07-02**
(Duo+, pass-1 clean; the two-glob derived registry — 65-parity, the number in the check, never the code —
+ grouped sidebar/topbar + the persisted route/theme (`mx-showcase.*.v1`) + static Stories/Docs stubs;
INV-5 held, zero loader calls; the S-1 probe run twice incl. the Director's adversarial unknown-group pass;
LAW-1a REGISTRY-rename mutation net-zero). **`mx.9.3` (the live-stories surface) is now ✅ BUILT
2026-07-02** (Trio; the ship-time re-sharpen census corrected the seed's algorithm — args merge, meta
render, no `parameters` — and FORK-1 decorators RULED Arm A; **the shim liveness gate PROVEN twice**:
65/65 modules mounted boundary-catch-free with the 11 `storybook/test` importers named, both adversarial
probes run twice, a behavioral mutation on the merge law caught by the sweep itself). **`mx.9.4` (the
contract surface) is now ✅ BUILT 2026-07-02** (Trio, pass-1 clean; the ship-time construct inventory over
all 65 contracts KILLED five seed assumptions — continuation-JOINING (475 lines/65 files), the xref rule
(~200 relative links → non-navigating spans), `*italic*`, the mask-first sentinel pass (bold wraps code
34/65), escaped pipes; FORK-1 grain RULED Arm A — nested sub-tabs, the route untouched; the renderer +
exact-depth cutter + the wired four-view DocsPanel land in `apps/showcase/src/**` only; Mars 13/13 + the
Director 8-witness corpus sweep with raw-derived expectations; three mutations total caught + net-zero;
the enum-less empty state proven on the real `Switch`; five contracts' `\|`-in-code-prose noted as a
CommonMark-faithful hygiene residual) — **`mx.9.5` (the closer) is ✅ BUILT 2026-07-02 (Squad + Apollo,
BUILD-GRADE): the mx.9 showcase epic is COMPLETE and Movement III CLOSES. The frontier is `mx.10` (the
vite 6→7 + pnpm `catalog:` toolchain lift — now ✅ BUILT 2026-07-02) or `mx.8.3+` (the remaining Storybook enrichment
slices) — an Operator sequencing call.** Forward
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
  mx.7   ✅ BUILT     ████████████████████  IMPORT the Claude-Design bundle's net-new components → @mercury/ui · 5-batch epic (30 net-new + 2 folds) COMPLETE 2026-07-01 · design flows DOWN only
    7.1  ✅ BUILT     ████████████████████  foundational primitives — Heading·Text·Label·IconButton·Separator (+5) — gate-green 2026-06-30
    7.2  ✅ BUILT     ████████████████████  feedback/display+layout — Callout·Spinner·Skeleton·Blockquote·DataList·Code·Kbd·AspectRatio·Collapsible·ScrollArea (+10) — gate-green 2026-06-30
    7.3  🪟 SPLIT     ────────────────────  input/selection composites — Operator-split 2026-06-30 into 7.3.1/7.3.2/7.3.3 (date pair shed one machine each)
    7.3.1 ✅ BUILT     ████████████████████  DateField — segmented spinbutton (+1) · composes @mercury/core useDateField (A2 arm a) · barrel 50→51 · REAL aaw Trio, 2 mars waves (LAW-1b) — gate-green 2026-06-30
    7.3.2 ✅ BUILT     ████████████████████  Calendar — month-grid picker (+1) · composes @mercury/core useCalendar (A2 arm a) · barrel +1 · grid machine — REAL aaw Trio + Apollo, write-ready waves (LAW-1b) — gate-green 2026-06-30
    7.3.3 ✅ BUILT     ████████████████████  selection composites — CheckboxGroup·CheckboxCards·RadioGroup·RadioCards (+4) + folds Textarea(+size)/ToggleGroup(+accent/disabled) · Duo+ · A1 compose·A3 fold · barrel +4/−0 → 65 folders · LAW-1a mutation — gate-green 2026-07-01 (/mercury-ship mx.7.3.3) · CLOSES the mx.7 import epic
    7.4  ✅ BUILT     ████████████████████  overlay-floor (@core, headless: trap·dismiss·anchored) + Dialog·AlertDialog·Popover (+3, @ui) + effector bridge (createDisclosure + scroll-lock singleton) · Squad · Apollo a11y (1 block remediated) · barrels @ui+3/@core+floor/@effector+disclosure · gate-green 2026-07-01 (showcase = commit #2)
    7.5  ✅ BUILT     ████████████████████  menus/hover/nav (consume the floor) — Dropdown·ContextMenu·HoverCard·LinkPreview·Menubar·TabNav (+6) · Squad + Apollo adversarial-a11y BUILD-GRADE · barrel +6/−0 → 61 folders · floor composed no re-roll · navigation/ ruled — gate-green 2026-07-01 (/mercury-ship mx.7.5)
  mx.8   🪟 EPIC      ░░░░░░░░░░░░░░░░░░░░  enrich the stories — palette · roundings · variants · actions · scenes · now an EPIC, sliced by group (@mercury/ui surface frozen)
    8.1  ✅ BUILT     ████████████████████  foundations slice — Palette+Roundings brand-only toolbar globals (host-wide) · foundations variant audit (Heading `as` gap filled) · 2 foundations-in-context scenes (Profile·Article) · barrel byte-identical · K-4 deferred — gate-green 2026-07-01 (/mercury-ship mx.8.1)
    8.2  ✅ BUILT     ████████████████████  actions slice — Button·IconButton·Link variant audit (already full, mx.4) · K-4 ACTIVATED zero-dep fn() spy (SB10.4.6 core storybook/test; Fork-5 dissolved) · Scenes/Confirm · preview.tsx inherited/unedited · barrel byte-identical — gate-green 2026-07-01 (/mercury-ship mx.8.2)
    8.3+ 📋 PLANNED   ░░░░░░░░░░░░░░░░░░░░  remaining interactive groups' audit + scenes (selection · inputs · feedback · …), one per slice, inheriting the zero-dep fn() pattern, as mx.7.4/7.5 land the library
  mx.9   ✅ BUILT     ████████████████████  ONE comprehensive showcase app (library · docs · API · do/don't · recipes) — 9.1–9.6 all BUILT 2026-07-02 (layered-engine axis; forks A–E RULED; Squad+Apollo closer; 9.6 = visual parity + the regression harness) — Movement III CLOSES
    9.1  ✅ BUILT     ████████████████████  the spine — apps/showcase scaffold (echomq-mirror alias + storybook/test shim) · sanity page · dev:showcase :5176 · apps gate 2→3 · Duo+ · LAW-1a alias mutation — gate-green 2026-07-02 (/mercury-ship mx.9.1)
    9.2  ✅ BUILT     ████████████████████  derived registry + shell — two lazy globs (INV-6, 65 derived) · grouped sidebar/topbar · persisted route+theme (mx-showcase.*.v1) · static Stories/Docs stubs (INV-5: zero loader calls) · Duo+ pass-1 clean · LAW-1a REGISTRY mutation — gate-green 2026-07-02 (/mercury-ship mx.9.2)
    9.3  ✅ BUILT     ████████████████████  live-stories surface — CSF interpreter (StoryBlock typed+CORRECTED: args merge · meta render · decorators Arm A) + THE SHIM LIVENESS GATE PROVEN (65/65; 11 importers named; probes ×2; behavioral mutation caught) · Trio pass-1 clean — gate-green 2026-07-02 (/mercury-ship mx.9.3)
    9.4  ✅ BUILT     ████████████████████  contract surface — zero-dep typed renderer + exact-depth cutter (five seed assumptions KILLED: continuation-join · xref spans · italics · mask-first · escaped pipes) · four views RULED Arm A (nested sub-tabs) · 8-witness corpus sweep over all 65 · Trio pass-1 clean — gate-green 2026-07-02 (/mercury-ship mx.9.4)
    9.5  ✅ BUILT     ████████████████████  the closer — seed-skinned chrome (308→388-line sheet, token-expressed, Arm A; F1–F4 declined) · dual-theme fully-correct (indigo-3 unused in chrome) · whole-epic INV-1..9 + S-9/S-10 re-run green · Movement III CLOSES · Squad+Apollo BUILD-GRADE — gate-green 2026-07-02 (/mercury-ship mx.9.5)
    9.6  ✅ BUILT     ████████████████████  visual parity + the visual-regression harness — completes 9.5's deferred :5176 pixel pass (the 9.5 skin was fitted to the WRONG donor; the build gate is visually blind) + a Playwright harness (apps/showcase/visual, reusable `pnpm --filter @mercury/showcase visual`) · 2 Mars waves to stylistic parity w/ static/showcase.html BOTH themes (A mono-heading + D crosshatch fixed app-side · sidebar brand/dots · inset solid topbar · Home overview 65/9/3 derived · eyebrow/title/lede header) · live probe Actions→Button · 6 apps/showcase/src files + tooling, barrel byte-identical, 0 hex — gate-green 2026-07-02 (Director+Mars)

Toolchain · beneath the ladder (orthogonal to the Movements)
  mx.10  ✅ BUILT     ████████████████████  pnpm catalog: single-source + vite 6→7 (7.3.6) + vitest 3→4 (4.1.9) + TS ~5.9.3 tilde-pin + jest-dom RETIRED · 13 manifests (4 apps incl showcase + 8 pkgs + root; codemojex OUT) · +@types/node on @mercury/core (vitest-4 exposed a latent NodeJS.Timeout) · barrel byte-identical · Duo · INV-1..8 green — gate-green 2026-07-02 (/mercury-ship mx.10)
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
**`mx.7.3.2`** (Calendar) is ✅ BUILT 2026-06-30 (BUILD-GRADE; reuses the same date foundation via a sibling `useCalendar`, INV-6 intact); **`mx.7.4`** (the overlay-floor + `Dialog`/`AlertDialog`/`Popover` + the effector disclosure bridge) is ✅ BUILT 2026-07-01 (Squad; Apollo a11y; +3 @ui / +floor @core / +disclosure @effector); **`mx.7.5`** (menus/hover/nav — `Dropdown·ContextMenu·HoverCard·LinkPreview·Menubar·TabNav`, +6) is ✅ BUILT 2026-07-01 (Squad + Apollo adversarial-a11y BUILD-GRADE; the 7.4 floor composed no-re-roll; barrel → 61 folders; `navigation/` group ruled). **`mx.7.3.3`** (the 4 selection composites + 2 folds) is ✅ BUILT 2026-07-01 (Duo+; the groups + `*Cards` **compose** the live `Checkbox`/`Radio` — A1; the folds **widen** `Textarea`(+`size`)/`ToggleGroup`(+`accent`/group-`disabled`) with 0 barrel delta; barrel +4/−0 → **65 folders**; LAW-1a mutation `accent="chartreuse"`→TS2322). **The mx.7 import epic is now COMPLETE** — 30 net-new + 2 folds across all 5 batches (7.1/7.2/7.3.{1,2,3}/7.4/7.5). Next candidates (Operator sequence `mx.9 → mx.8.3+`): `mx.9` (the showcase app — the Movement-III destination; a fresh pre-build blockers analysis is on file), or `mx.8.3+` (the remaining interactive-group story slices — the shipped library, incl. these composites, is ready to enrich). **`mx.9` is now SPLIT (Operator-ruled 2026-07-02, the layered-engine axis)** into `mx.9.1` (the spine) → `mx.9.2` (the derived registry + shell) → `mx.9.3` (the live stories + the shim liveness gate) → `mx.9.4` (the contract surface) → `mx.9.5` (chrome + dual-theme acceptance + the whole-epic closure; Squad + Apollo); forks A–E RULED (`apps/showcase`/`@mercury/showcase` · the conventional vite app on the source alias with the seed-skinned chrome, `loader.js` REJECTED · the prototypes stay untracked seeds · zero new dependency); the `mx.9.1`/`mx.9.2` triads are BUILD-READY, `mx.9.3`–`mx.9.5` SOLID-FORWARD. **`mx.9.1` (the spine) is ✅ BUILT 2026-07-02** (`/mercury-ship mx.9.1`, Duo+ pass-1 clean: the seven-file scaffold built byte-exact from the write-ready brief — the echomq-mirror alias + tsconfig `paths`, the six-export `storybook/test` shim, the `light-theme` sanity page proving alias + tokens with core's `dist/` absent; `pnpm install` importer-only — resolved 579 / downloaded 0 / added 0 external; the apps gate 2→3 `showcase·echomq·mobile`, barrel byte-identical, consume-down greps clean with the `--exclude-dir=node_modules` reconcile folded; LAW-1a alias-mutation net-zero; the lockfile carries an entangled sibling delta so the importer block ships with the sibling's commit, regenerable) — **the frontier is `mx.9.2`** (the derived registry + shell; its Mars dispatch inherits the scoped-gate + grep corrections). **`mx.9.2` (the derived registry + shell) is ✅ BUILT 2026-07-02** (`/mercury-ship mx.9.2`, Duo+ pass-1 clean — the architect leg collapsed on the WRITE-READY triad after an all-MATCH Director ground-truth reconcile: `registry.ts` transcribed from the brief (two lazy `import.meta.glob` over the real tree; 65-parity derived, the number in the check, never the code), `shell/{Sidebar,Topbar,ComponentPage,Home}` + the persisted route/theme (`mx-showcase.route.v1`/`mx-showcase.theme.v1`, boot-applied before mount), static Stories/Docs stubs — INV-5 held with zero `loadStories(`/`loadPrompt(` call sites and every story/prompt chunk code-split lazy; the S-1 liveness probe ran TWICE (Mars `foundations/__Probe__` + the Director's adversarial `zz-probe/` unknown-group pass exercising the appended-derived path), both present→absent with `packages/**` clean; three flagged realizations Director-accepted (in-src `vite-env.d.ts` for the vite types · strict-safe `parse()` · Home `main`→`section` landmark); the `@mercury/*`-scoped build gate of record green with the pre-existing `@echo/fx` wasm failure left named; LAW-1a `REGISTRY`-rename mutation → TS2724 → net-zero) — **the frontier is `mx.9.3`** (the live-stories surface: the first loader invocation, the CSF interpreter, and the shim liveness gate across all 65 modules). **`mx.9.3` (the live-stories surface) is ✅ BUILT 2026-07-02** (`/mercury-ship mx.9.3`, Trio, pass-1 clean: the SOLID-FORWARD triad was re-sharpened at ship by Venus — the census over all 65 story files KILLED three authoring-time assumptions (`parameters.summary` bundle-invented 0/65 · `render` DOMINANT 65/65 files incl. 3 meta-level · the seed's `story.args`-only read renders every `Playground` empty ⇒ the merge law `{...meta.args, ...story.args}` is binding) and resolved the non-story-export filter (none exist — named exports = stories); FORK-1 (5 meta-level decorator files) Operator-RULED Arm A (support exactly the censused `(Story) => JSX` length-1 shape); Mars built `src/lib/storyRender.tsx` (~160 lines: `parseCsfModule`/`StoryCard`/`StoriesPanel`, resolution inside the boundary, entry-keyed lazy effect, no MOD_CACHE port) + wired the stub + additive `showcase-story*` tokens-only css; **THE SHIM LIVENESS GATE PROVEN TWICE** (Mars sweep + the Director's independent stronger-witness sweep: 65/65 boundary-catch-free, the 11 importers by name, merged-args/meta-render/both-decorator DOM witnesses, `fn()` click no-op, containment); probes ×2 each (`spyOn`/`screen` both LOUD at import-analysis; contained render throw at jsdom level); the behavioral LAW-1a mutation (drop the merge) failed 4/5 Director tests incl. the sweep itself (`inputs/Select` `undefined.map`) → reverted net-zero; the `:5176` visual + network-panel checks stated as the honest manual residuals) — the frontier moved to `mx.9.4`. **`mx.9.4` (the contract surface) is ✅ BUILT 2026-07-02** (`/mercury-ship mx.9.4`, Trio, pass-1 clean: the SOLID-FORWARD triad re-sharpened at ship — Venus's construct inventory over ALL 65 contracts (mechanical greps + three end-to-end reads) KILLED five seed assumptions (the seed's flat list loop would corrupt EVERY contract — 475 1–3-space continuation lines join into their `li`; all ~200 links are relative `.prompt.md` xrefs → the Operator-confirmed non-navigating-span rule; `*italic*` real in 16 files; bold WRAPS code in 34/65 ⇒ the mask-first sentinel inline pass, code atomic; `\|` load-bearing in 50/65 table cells) and pinned the out-of-scope constructs to the paragraph-fallback law (content never silently drops); FORK-1 (the epic §7-A four-view grain) Operator-RULED **Arm A** — a nested sub-tab row inside the Docs tab, view state local per entry, the persisted route/`App.tsx`/`Tab` union untouched, mx.9.5 owes the two rows distinct skinning; Mars built `lib/markdown.tsx` (303 lines: the typed React-element renderer + the exact-depth `section` cutter + census-bound `DOC_CUTS`) + `shell/DocsPanel.tsx` (124 lines: 4-state union, keyed remount, one fetch four selections) + the 6-line ComponentPage wire + 132 append-only `showcase-md-*` css lines — `packages/**` untouched, barrel byte-identical, `package.json` unchanged (Fork E); evidence = Mars 13/13 behavioral witnesses + the Director's independent 8-witness corpus sweep with RAW-DERIVED expectations per file (heading/table/pre/li counts outside fences, leakage checks outside code, every continuation fragment canonicalized-contained in a `li`, the cutter law Props 65/65 + enum-language null for exactly the census 9, TabNav `###`-inside-Props, the mask-first synthetic, the xref split, Switch's real enum-less empty state, the single-fetch law, the loaderless no-contract state); THREE mutations caught + reverted net-zero (Mars: continuation-join, naive pipe-split; Director: `###`-terminates-cutter — content-verified since the file is untracked); the NUL-byte craft guard proved out TWICE (the sentinel authored via write tooling lands literal NULs — `perl /\x00/` after every such write); five contracts' `\|`-inside-code-prose (Stat/Alert/PasswordStrength/Progress/Label) NOTED as a CommonMark-faithful authoring artifact, a hygiene candidate, not a renderer gap; the `:5176` four-view visual pass stays the manual residual) — **the frontier is `mx.9.5`** (the closer: seed-skinned chrome + dual-theme acceptance + the whole-epic INV-1..9 / S-9/S-10 re-run; ELEVATED — **Squad + Apollo**; Movement III closes with it). **`mx.9.5` (the closer) is ✅ BUILT 2026-07-02** (`/mercury-ship mx.9.5`, Squad + Apollo, BUILD-GRADE pass-1: the SOLID-FORWARD triad re-sharpened at ship — Venus's seed census confirmed the bundle-shell `app.css` donor is 100% token-expressed while all four fork candidates (F1 inverse-muted · F2 script face · F3 brand-glow shadow · F4 syntax hues) source ONLY from the `apps/website` marketing decoration → **Operator-RULED Arm A, the clean token skin — F1–F4 declined, zero new token/dep**; Mars grew `showcase.css` 308→**388** (the eight-region skin — scrollbar · sticky translucent topbar · subtle-tint active nav · 1080px reading column with the heading-300 `-size`/`-lh` PAIR · shadow-100 card + the donor crosshatch stage · tab hovers · docs weights) + absorbed `Home.tsx` static layout into `.showcase-home-*` (the dynamic swatch bg stays inline); TWO gate-invisible precision traps caught in the brief (a bare `var(--text-heading-300)` silent no-op; `--fw-semi-bold` hyphenated) + TWO donor-grounded realizations ratified (the crosshatch paints hatch-first/opaque-base-LAST — the donor's solid-first order would occlude; `.showcase-page` left-aligned per donor); the chrome is **fully dark-correct** (no `--indigo-3`/active/info soft-bg in the sheet — the EXPECTED caveat lands documented-but-unused); the Director's independent gate green (`@mercury/*`-scoped, `@echo/fx` excluded; barrel byte-identical; hex/consume-down/storybook/md greps empty; a net-zero hex-mutation spot-check) + Apollo's two adversarial probes PASS (INV-5 docs trace to the `?raw` `.prompt.md`; INV-4 no reusable component leaked) + the whole-epic INV-1..9 + S-9/S-10 re-run green; scope = exactly `showcase.css` + `Home.tsx` (+ the triad/roadmap/progress fold), the `pnpm-lock.yaml` delta attributed to `codemojex/apps/dashboard` and kept out of the pathspec; the `:5176` human-eye pixel pass the Operator residual by design) — **the mx.9 showcase epic is COMPLETE and Movement III CLOSES.** The frontier moves to `mx.10` (the vite 6→7 + pnpm `catalog:` toolchain lift — now ✅ BUILT 2026-07-02) or `mx.8.3+` (the remaining Storybook enrichment slices) — an Operator sequencing call. **`mx.9.6` (visual parity + the visual-regression harness) is ✅ BUILT 2026-07-02 (Director + Mars, two waves):** mx.9.5 deferred its pixel acceptance to "the `:5176` human-eye pass — the Operator residual by design"; that pass ran and found the app **half-baked** — the mx.9.5 skin had been fitted to the WRONG donor (`packages/mercury-ds/…/app.css`, not the true reference `static/showcase.html`), so its selectors/values never rendered (the build gate is visually blind: `tsc`+`vite` verify CSS *parses*, never that a selector matches the live DOM or a token resolves — a sheet can be 100% green and 0% rendered). mx.9.6 (a) **built the missing pixel gate** — a Playwright harness (`apps/showcase/visual/shoot.mjs`; `pnpm --filter @mercury/showcase visual`; reuses the global browser cache, no download) that shoots the live app + the served reference across route×theme; (b) drove **two Mars waves to stylistic parity** with `static/showcase.html`, harness-verified in BOTH themes — W1 the frame (the 272px grid · sidebar brand + dotted items + tinted active pill · inset solid topbar · the **A** heading-font fix **app-side**, the DS token layer untouched · the **D** crosshatch reordered opaque-first), W2 the content (ComponentPage eyebrow/40px-sans-title/lede · the Home overview: hero + **65/9/3** DERIVED metrics + a `REGISTRY`-derived 9-group card grid); (c) proved the **interaction** with a live probe (Home "Actions" card → "Button", sidebar syncing). Scope = exactly 6 `apps/showcase/src` files + the `visual/` tooling + `package.json`; `packages/**` frozen, barrel byte-identical, 0 raw hex, gate green; the `pnpm-lock.yaml` delta left for the Operator. The durable guardrail — **fold the visual pass into the mercury-ship gate ladder** — is PROPOSE-ONLY (the skill files are Operator-owned). The frontier remains `mx.10` (the vite 6→7 lift) or `mx.8.3+`.
  Open forks for the later batches: the bundle's git fate · the overlay-floor ADR (7.4) · **the date-lib dependency
  (7.3.1 + 7.3.2 — grounded: no ready `@mercury/core` hook, arm (a)=from-scratch build; Operator rules per
  machine)** · mx.8's palette mechanism. Design flows DOWN from Claude Web only — `/design-sync` forbidden.
- **Deferred / open.** Widening `@mercury/core`'s public barrel beyond `cx` + `date` (the deeper
  foundation lives in core as files, surfaced when a consumer needs it); whether design tokens later
  migrate into `@mercury/core`; the `.design-sync` pipeline re-alignment (`mx.7` — its
  `config.json` targets `@mercury/ui`, unaffected by the `mercury-ds` deletion). See the roadmap's
  **Seams & open decisions**.
