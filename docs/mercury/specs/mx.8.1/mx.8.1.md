# mx.8.1 · Storybook enrichment — the foundations slice (palette · roundings globals · variant audit · foundations-in-context scenes)

> **Status: 📐 SPECCED — the FIRST slice of the mx.8 epic (foundations); RISK NORMAL; the `@mercury/ui`
> surface is FROZEN byte-identical.** mx.8 ("enrich the Storybook stories" — palette · roundings · variant
> switching · actions · real-world scenes) is whole-library and SOLID-FORWARD; the Operator scoped this
> increment to the **`foundations`** group, so mx.8 becomes an **epic** and **mx.8.1 is its first slice**
> (the mx.7 → 7.1/7.2/7.3.x shape). This slice DERIVES the shared mechanism from
> [`../mx.8/mx.8.md`](../mx.8/mx.8.md) (§6 the token/decorator recipes, §7 the invariants) and pins the
> **foundations specifics** — it does not restate mx.8's §6 tables.
>
> **The decisions this slice is authored TO (RULED — not re-litigated here):**
> - **[Operator] Palette + Roundings = TOOLBAR GLOBALS, BRAND-ONLY** (mx.8 Fork-1 arm (a) + the §6.1
>   brand-only sub-note). Two `globalTypes` — `palette` + `radius` — beside the shipped `theme` global, one
>   extended decorator re-points the `--bg-brand` family + the `--radius-2…-32` steps on the one wrapper.
>   **Brand-only:** the `--bg-active` family is NOT re-pointed — the canon's iris = identity / indigo =
>   interaction split holds (links/controls stay indigo).
> - **[Operator] Scenes = FOUNDATIONS-IN-CONTEXT** — real editorial/content screens where the foundations
>   primitives (Heading · Text · Divider · Separator · Icon) LEAD, composing a few already-shipped
>   `@mercury/ui` components (Card · Button · ListRow · Badge · Avatar) for realism; each grounded in a cited
>   real screen/pattern. Not pure-foundations specimens.
> - **[Director] Rung id = mx.8.1** (mx.8 is the parent epic). The cross-cutting globals (D1/D2) build
>   **host-wide** — re-skinning every story is their nature — and are proven **book-wide** (INV-6 probes a
>   `--bg-brand` surface, Button, a `--radius` surface, Card, and an `--radius-full` surface, Avatar, all
>   shipped). The variant audit (D3) + the scenes (D4) scope to **foundations only**.
> - **[Director, grounded] Actions (mx.8 K-4) = DEFERRED, N/A this slice.** The five foundations `.tsx`
>   declare **no** `on[A-Z]` interaction handler — Icon/Divider/Separator/Heading/Text are pure
>   presentational primitives — so there is nothing to spy and mx.8's Fork-5 (the actions host-dependency)
>   cleanly defers to a later interactive-group slice (mx.8.2+). **No new host dependency this rung.** Stated
>   transparently in Scope · Out (a real finding, not a shortcut).
> - **[Steward] Homes:** scenes live host-home at `apps/storybook/stories/scenes/`; the variant audit EXTENDS
>   the co-located `foundations/<Name>/<Name>.stories.tsx`; the audit surface is per-component `argTypes`.
> - **[inherited mx.8] Design flows DOWN** — no `/design-sync`, no `DesignSync`, no push to Claude Web.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · parent epic (the shared mechanism):
[`../mx.8/mx.8.md`](../mx.8/mx.8.md) + [`../mx.8/mx.8.llms.md`](../mx.8/mx.8.llms.md) · acceptance:
[`mx.8.1.stories.md`](./mx.8.1.stories.md) · build brief: [`mx.8.1.llms.md`](./mx.8.1.llms.md) · approach:
[`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md).

---

## Goal

After mx.8.1, the Storybook carries **two new brand-only toolbar globals — `Palette` and `Roundings`** — that
extend the shipped mx.3 `theme` decorator so one control re-skins **every** story at once (re-pointing the
`--bg-brand` family and the `--radius-2 … --radius-32` steps on the single scoped wrapper, `--bg-active` and
`--radius-full` left intact); the **five foundations component stories expose their full exported-union
control surface** (the one real gap — Heading's `as`/`HeadingTag` control — is added; Text · Icon · Divider ·
Separator are verified already-complete); and a host-home **`Scenes/`** group composes **≥2**
foundations-in-context editorial screens from real `@mercury/ui` exports, each grounded in a cited screen. The
whole diff is host config (`preview.tsx`), the foundations story enrichment, the new scene stories, and this
triad — the **`@mercury/ui` barrel is byte-identical to HEAD** and no component `.tsx`/`index.ts`/`.prompt.md`/
style is edited. The load-bearing proof (INV-6): the globals **measurably drive the tokens** on a book-wide
`--bg-brand`/`--radius` surface — a no-op decorator is a LOUD failure.

## Rationale (5W)

- **Why** — A design-system Storybook earns trust when a viewer can *interrogate* the surface — does the library
  hold together under a different brand ramp (palette)? under sharper/rounder corners (roundings)? across every
  variant of a primitive (the audit)? assembled into a real screen (scenes)? The foundations are the
  type / rule / glyph layer every other component composes, so they are the right first slice to make browsable;
  and because they declare no interaction handler, deferring the actions dimension here is honest, not a gap.
- **What** — Two brand-only cross-cutting toolbar globals (`palette`, `radius`) + one extended decorator; the
  foundations variant/options audit (Heading's `as` top-up, the other four verified full-union) with the Icon
  `name` NO-INVENT posture stated truthfully; ≥2 host-home foundations-in-context scenes; and the gate,
  including the book-wide INV-6 render-check that the globals drive the tokens.
- **Who** — *Authored by* Claude Code as Director-led architect (this triad) + the mx.8.1 build. *Consumed by*
  (1) Mercury contributors + the Claude Design agent browsing the foundations under different palettes/
  roundings; (2) the later mx.8 slices (mx.8.2+), which inherit these host-wide globals and activate the
  actions dimension on the interactive groups; (3) mx.9 (the showcase), which composes the scenes into the
  shipped site.
- **When** — Now — mx.8.1 is the first slice of the mx.8 epic, decomposed by the Operator to the `foundations`
  group; it ships ahead of the interactive-group slices that carry the actions dimension.
- **Where** — `apps/storybook/.storybook/preview.tsx` (the globals + the extended decorator),
  `apps/storybook/stories/scenes/` (new), the five
  `packages/mercury-ui/src/components/foundations/<Name>/<Name>.stories.tsx` (audited — stories only, no
  surface), and `docs/mercury/specs/mx.8.1/`.

## Scope

**In.**
- **D1 — the `Palette` global (brand-only).** A `palette` `globalType` (the six real ramps + a "Brand (iris)"
  default) + the extended decorator re-pointing the `--bg-brand` family per mx.8 §6.1, using only ramp steps
  the chosen ramp defines. `--bg-active` is **not** re-pointed (brand-only).
- **D2 — the `Roundings` global.** A `radius` `globalType` (Sharp / Default / Round) + the extended decorator
  overriding `--radius-2 … --radius-32` per mx.8 §6.2; `--radius-full` is **never** overridden.
- **D3 — the foundations variant/options audit (the five stories).** Each foundations story exposes its full
  exported-union control surface. Heading gains the missing `as`/`HeadingTag` control; Text/Icon/Divider/
  Separator are verified already-complete (topped up only if a gap surfaces at build, flagged). The Icon
  `name` NO-INVENT comment is corrected to state the set is **manually** verified (see INV-8).
- **D4 — the foundations-in-context scenes.** ≥2 host-home `apps/storybook/stories/scenes/*.stories.tsx`,
  foundations-led, composing **only** real `@mercury/ui` exports, each grounded in a cited real screen/pattern.
- **D5 — the gate is green AND the globals drive the tokens.** The full gate ladder + the book-wide INV-6
  render-check + the byte-identical barrel diff.
- The cross-cutting globals (D1/D2) build **host-wide** (they re-skin every story — their nature) and are
  proven **book-wide** on the shipped `--bg-brand`/`--radius` surfaces (Button · Card · Avatar).

**Out.**
- **Actions (mx.8 K-4) — DEFERRED, N/A this slice.** The five foundations `.tsx` declare no `on[A-Z]`
  interaction handler (pure presentational primitives), so there is nothing to spy; mx.8's Fork-5 (the actions
  host-dependency) defers to a later interactive-group slice (mx.8.2+). **No new host dependency this rung**
  (no `storybook/test` / `@storybook/addon-actions` install; `main.ts`/`package.json`/`pnpm-lock.yaml`
  untouched). The actions dimension activates when a slice reaches the actions/inputs/selection groups.
- Any `@mercury/ui` surface change — no new export, no component `.tsx`/`index.ts`/`.prompt.md`/style edit
  (the barrel is byte-frozen; the only `mercury-ui/src/**` edits are `foundations/*/*.stories.tsx`).
- The non-foundations component groups' story enrichment (later mx.8 slices).
- The showcase application composing the scenes (mx.9); effector-wired scenes (mx.5's `stories/effector/` —
  mx.8.1 scenes are presentational, no `@mercury/effector`).
- `/design-sync`, the `DesignSync` MCP, any push to Claude Web (design flows DOWN).
- Editing the roadmap/design/epic (the Director folds the mx.8/mx.8.1 rows + a `D-` per ruled decision at
  ship).

## Deliverables

Each is a provable unit (the check that proves it is its Invariant; the story that accepts it is its US).

- **mx.8.1-D1 — the `Palette` toolbar global + decorator (brand-only).** `apps/storybook/.storybook/
  preview.tsx` gains a `palette` `globalType` (items: `Brand (iris)` default · `indigo` · `green` · `orange` ·
  `plum` · `red`) and the extended decorator applies the mx.8 §6.1 remap of the `--bg-brand` family to the
  chosen ramp on the story wrapper, using only steps the ramp defines (`-3`/`-9`/`-11` for all six; `-10` only
  for iris/indigo, else the `-9` fallback). `--bg-active` is untouched. Composes with the existing `theme`
  global on the same wrapper. (≙ mx.8 K-1.)
- **mx.8.1-D2 — the `Roundings` toolbar global + decorator.** `preview.tsx` gains a `radius` `globalType`
  (`Sharp` · `Default` default · `Round`) and the extended decorator overrides `--radius-2 … --radius-32` on
  the wrapper per the mx.8 §6.2 preset (Sharp ⇒ `0px`; Default ⇒ no override; Round ⇒ enlarged). `--radius-full`
  is **never** overridden. (≙ mx.8 K-2.)
- **mx.8.1-D3 — the foundations variant/options audit.** The five
  `foundations/<Name>/<Name>.stories.tsx` expose the full exported-union control surface: **Heading** gains the
  `as` control (options = the `HeadingTag` union `["h1","h2","h3","h4","h5","h6","div"]`, typed by
  `HeadingTag`); **Text** (`TextVariant` × the accent union), **Icon** (`name` set × `size` × `strokeWidth`),
  **Divider** (`orientation` × `label`), **Separator** (`orientation` × `label` × `decorative`) are verified
  complete. The Icon story's NO-INVENT comment is corrected to reflect that `name` is manually verified against
  the `ICONS` keys (`IconName` widens to `string`; INV-8). The mx.4 grid/state stories are kept. (≙ mx.8 K-3.)
- **mx.8.1-D4 — the foundations-in-context scenes.** ≥2 host-home CSF3 scene stories under
  `apps/storybook/stories/scenes/` (`title: "Scenes/<Name>"`, no `component:` field, the `Tokens` shape),
  foundations-led (Heading · Text · Divider · Separator · Icon carry the screen) and composing a few real
  `@mercury/ui` exports (Card · ListRow · Badge · Avatar · Button) for realism. Each imports **only**
  `@mercury/ui` (+ `react`/`@storybook/react-vite`) and carries a lead comment naming the cited real
  screen/pattern (e.g. `apps/mobile/src/screens/Profile.tsx` and the read-only seed
  `packages/mercury-ds/project/ui_kits/mercury_app/screens.jsx`). (≙ mx.8 K-5.)
- **mx.8.1-D5 — the gate is green AND the globals drive the tokens (book-wide).** The full gate ladder exits
  0; the barrel is byte-identical; the NO-INVENT/partial-ramp greps are empty; and the INV-6 render-check
  proves — on a `--bg-brand` surface (Button) and a `--radius` surface (Card) plus the `--radius-full`
  exclusion (Avatar) — that a chosen palette/roundings **measurably changes** the computed style (a no-op
  decorator is a LOUD failure). (≙ mx.8 K-6.)

**Coverage:** mx.8.1-D1 → US1 · mx.8.1-D2 → US2 · mx.8.1-D3 → US3 · mx.8.1-D4 → US4 · mx.8.1-D5 → US5.

## Invariants

Runnable checks (run from `mercury/`). Each is the gate that proves its property, not prose.

- **mx.8.1-INV1 — the barrel is byte-identical (the master invariant, strongest form).**
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` → **empty**.
  mx.8.1 adds no `@mercury/ui` export.
- **mx.8.1-INV2 — the `@mercury/ui` production surface is untouched; only foundations stories + host config
  change.** `git diff --name-only` shows **no** `packages/mercury-ui/src/**` edit **except**
  `components/foundations/*/*.stories.tsx`; every other changed path is `apps/storybook/.storybook/preview.tsx`,
  `apps/storybook/stories/scenes/**`, or `docs/mercury/specs/mx.8.1/**`. No component `.tsx`/`index.ts`/
  `.prompt.md`/`styles/**` edit; no `.storybook/main.ts`, `package.json`, or `pnpm-lock.yaml` edit (K-4
  deferred → no actions dep). Any unavoidable non-story `mercury-ui` change is flagged + surfaced, never silent.
- **mx.8.1-INV3 — `sb:typecheck` clean (the authoritative NO-INVENT gate).** `pnpm sb:typecheck` exits 0 — the
  host `tsc` is the only one that checks the enriched stories + scenes (the library `tsc` excludes
  `**/*.stories.tsx`, mx.3 D-9). Every option array typed by a real **literal** exported union rejects an
  invented member here (see INV-8 for the Icon caveat); every scene import resolves to a real barrel export.
- **mx.8.1-INV4 — `sb:build` registers the prior homes unchanged + the new `Scenes/*` homes.** `pnpm sb:build`
  exits 0; the built index lists every prior component/foundation/effector home **unchanged** (the foundations
  basic stories are enriched *in place*, not added — the component-home count does not move) and adds the new
  `Scenes/<Name>` homes.
- **mx.8.1-INV5 — packages typecheck/build + the product apps build, undisturbed.**
  `pnpm --filter "./packages/*" typecheck` = 0 · `pnpm --filter "./packages/*" build` = 0 ·
  `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` = 0. The app set is glob-driven and
  reconciled at build (the `apps/*` dirs currently include `echomq · fx-demo · marketing-site · mobile ·
  website` beside the excluded `storybook` host) — the count is not pinned; mx.8.1 must not regress the app
  build.
- **mx.8.1-INV6 — the globals DRIVE the tokens, proven BOOK-WIDE (gate-liveness; a no-op is a LOUD failure).**
  The proof is POSITIVE, on a brand/radius surface, not "it compiles": with `Palette = green`, a `--bg-brand`
  surface (`Button variant="primary"`) computes the **green-9** triplet `rgb(48, 164, 108)`, **not** iris-9
  `rgb(91, 91, 214)`; with `Roundings = Sharp`, a `--radius-8` surface (a `Card`) computes
  `border-radius: 0px`, **not** `8px`, **while** an `Avatar` (`--radius-full`) stays `9999px` (the full-radius
  exclusion). The probes ride `--bg-brand`/`--radius` surfaces because the foundations primitives do **not**
  read those families (Heading/Text default to `--fg-primary`, `accent` reads `--<ramp>-11` directly; Icon
  reads `currentColor`; Divider/Separator read `--border-*`) — so a bare foundations story showing **no**
  change under Palette/Roundings is EXPECTED, not a decorator no-op. A decorator that registers a picker but
  never overrides the variable fails this check. (Exercised at ship via a computed-style probe / play function;
  the spec fixes the expected values.)
- **mx.8.1-INV7 — actions are deferred on a grounded fact, not skipped (no new host dep).** The foundations
  declare no interaction handler:
  `grep -rnE "on[A-Z][A-Za-z]*\??:" packages/mercury-ui/src/components/foundations/*/*.tsx` over the prop
  interfaces → **empty** (no handler contract to spy). And no actions dependency is added: `git diff`
  touches **no** `apps/storybook/package.json` / `pnpm-lock.yaml` / `.storybook/main.ts`, and
  `grep -rn "storybook/test\|@storybook/addon-actions\|\bfn(" apps/storybook` shows no new actions wiring.
- **mx.8.1-INV8 — NO-INVENT + token discipline + design-flows-DOWN, with the enforcement stated truthfully.**
  Every ramp/radius/token name in the decorator + stories is real (traced from
  `packages/mercury-ui/src/styles/tokens.css`); the exported **literal** unions (`HeadingSize` · `HeadingWeight`
  · `HeadingAlign` · `HeadingTag` · `TextVariant` · `SeparatorOrientation` · `DividerProps["orientation"]` ·
  the Heading/Text `accent` unions) are typecheck-narrowed — an invented option fails INV-3. **Icon's `name` is
  the exception:** `IconName = keyof (ICONS: Record<string, ReactNode>)` widens to `string`, so its NO-INVENT
  enforcement is a **manual set-equality** check, not the type. Greps (run at ship over the touched paths), all
  **empty**: `grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/storybook/stories/scenes apps/storybook/.storybook` ·
  `grep -rn "window.MercuryUI\|_ds_bundle\|design-sync\|DesignSync" apps/storybook/stories apps/storybook/.storybook`
  · `grep -rnE "\-\-(green|orange|plum|red)-(10|4)\b" apps/storybook/.storybook` (the partial-ramp guard) · and
  the Icon set-equality `comm -3 <(the sorted ICON_NAMES array) <(the sorted ICONS keys)` → empty.

## Definition of Done

- [ ] **mx.8.1-D1** — `preview.tsx` carries the `palette` `globalType` + the brand-only `--bg-brand` remap on
  the extended decorator; `--bg-active` untouched; no `--(green|orange|plum|red)-(10|4)` emitted (US1; INV6,
  INV8).
- [ ] **mx.8.1-D2** — `preview.tsx` carries the `radius` `globalType` + the `--radius-2 … --radius-32` override;
  `--radius-full` untouched (US2; INV6, INV8).
- [ ] **mx.8.1-D3** — the five foundations stories expose their full exported-union control surface; Heading's
  `as` control is added and typed by `HeadingTag`; the Icon `name` comment states manual verification (US3;
  INV3, INV8).
- [ ] **mx.8.1-D4** — ≥2 host-home foundations-led scenes compose only real `@mercury/ui` exports and each
  cites a real screen/pattern; `sb:build` registers the new `Scenes/*` homes (US4; INV4, INV8).
- [ ] **mx.8.1-D5** — the full gate ladder exits 0; the barrel diff is empty; the INV-6 book-wide render-check
  is POSITIVE (green ⇒ `rgb(48,164,108)`; Sharp ⇒ Card `0px`, Avatar `9999px`) (US5; INV1, INV2, INV5, INV6).
- [ ] **Actions deferred, grounded** — the foundations-handler grep is empty and no actions dep is added (the
  K-4 deferral is a finding, not a skip) (US5; INV7).
- [ ] **Voice / framing** — no perceptual or interior-state verb on a software component; components
  re-skin / override / resolve / compute / render; no first person outside the stories' Connextra "I want".

Stories: [mx.8.1.stories.md](./mx.8.1.stories.md)  ·  Agent brief: [mx.8.1.llms.md](./mx.8.1.llms.md)  ·  Index: [mx.8.md](../mx.8/mx.8.md)  ·  Approach: [../../../aaw/aaw.specs-approach.md](../../../aaw/aaw.specs-approach.md).
