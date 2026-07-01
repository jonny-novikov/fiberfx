# mx.8.1 · stories — acceptance (Specification by Example)

The Operator's acceptance face of [`mx.8.1.md`](./mx.8.1.md). One Connextra story per deliverable, each with
concrete Given/When/Then (name the observable), an INVEST line naming the invariant(s) it exercises, and a
Priority/Size/Implements line. A gate specifies its own liveness — a no-op does not satisfy its letter.

---

## mx.8.1-US1 — the Palette global re-skins the book, brand-only

As a **Mercury contributor** browsing the foundations, I want a **Palette toolbar control** that re-skins the
whole book to any of the six real brand ramps, so that the library's cohesion under a rebrand is verifiable
from one control, with no story edit.

**Acceptance criteria**
- **Given** the Storybook is open on any story, **When** `Palette` is set to `green`, **Then** a `--bg-brand`
  surface (a `Button variant="primary"`) computes the green-9 triplet `rgb(48, 164, 108)`, and the interaction
  surfaces stay indigo (`--bg-active` is not re-pointed — the iris/indigo split holds).
- **Given** `Palette = Brand (iris)` (the default), **When** the story renders, **Then** no override is applied
  and the same surface computes iris-9 `rgb(91, 91, 214)`.
- **Given** a status ramp (`green`/`orange`/`plum`/`red`) is selected, **When** the decorator resolves the
  `--bg-brand` family, **Then** only steps the ramp defines are used (`-3`/`-9`/`-11`, with the `-9` fallback
  for `-10`) — **no** `--(green|orange|plum|red)-10` / `-4` custom property is emitted.

INVEST — Independent (one toolbar global, no story edit), Negotiable (default label is latitude), Valuable
(the rebrand interrogation), Estimable (one `preview.tsx` block), Small, Testable (a computed-style probe on
Button); encodes mx.8.1-INV6, mx.8.1-INV8.

Priority: High · Size: S · Implements deliverables: mx.8.1-D1.

## mx.8.1-US2 — the Roundings global re-scales corners, circles preserved

As a **Mercury contributor**, I want a **Roundings toolbar control** (Sharp / Default / Round) that re-scales
the corner radius across the book, so that every primitive is reviewable under sharper or rounder corners while
the circular affordances stay round.

**Acceptance criteria**
- **Given** any story, **When** `Roundings` is set to `Sharp`, **Then** a `--radius-8` surface (a `Card`)
  computes `border-radius: 0px`, **while** an `Avatar` (`--radius-full`) stays `9999px`.
- **Given** `Roundings = Default`, **When** the story renders, **Then** no radius override is applied (the live
  `8px`).
- **Given** the decorator's radius override, **When** its keys are inspected, **Then** it overrides only
  `--radius-2 … --radius-32` and **never** `--radius-full`.

INVEST — Independent (one global), Negotiable (the Sharp/Round preset values are implementor latitude),
Valuable (the corner interrogation), Estimable, Small, Testable (a computed-style probe on Card + Avatar);
encodes mx.8.1-INV6, mx.8.1-INV8.

Priority: High · Size: S · Implements deliverables: mx.8.1-D2.

## mx.8.1-US3 — every foundations primitive is switchable across its full surface

As the **Claude Design agent** auditing the foundations, I want every foundations story to expose its full
exported-union control surface, so that any primitive is switchable across its every variant from the Controls
panel and an invented option is caught.

**Acceptance criteria**
- **Given** the Heading story, **When** the Controls panel opens, **Then** an `as` control lists the
  `HeadingTag` union (`h1`…`h6`, `div`) and `size` lists all nine levels (`1`…`9`).
- **Given** the Text / Divider / Separator / Icon stories, **When** the Controls panel opens, **Then** each
  lists its full option set (`TextVariant` (11) · `orientation` · `decorative` · the icon `name` set), matching
  its exported surface.
- **Given** a story option array typed by a real **literal** exported union, **When** an invented member is
  added, **Then** `sb:typecheck` fails; **but** the Icon `name` set is enforced by a manual set-equality check
  against the `ICONS` keys (its type widens to `string`), and the story comment states that verification
  truthfully — not "a compile error".

INVEST — Independent (per-story argTypes), Negotiable (control widget kind), Valuable (the variant
interrogation), Estimable (one real gap — Heading `as`), Small, Testable (`sb:typecheck` + the set-equality
grep); encodes mx.8.1-INV3, mx.8.1-INV8.

Priority: High · Size: M · Implements deliverables: mx.8.1-D3.

## mx.8.1-US4 — the foundations lead a real screen

As the **mx.9 showcase author**, I want ≥2 host-home scenes where the foundations primitives lead a real
editorial/content screen, so that the foundations are reviewable assembled into a real screen before they
compose the shipped site.

**Acceptance criteria**
- **Given** the Storybook nav, **When** a `Scenes/<Name>` story opens, **Then** the screen is carried by the
  foundations primitives, with a few real `@mercury/ui` components (Card · ListRow · Badge · Avatar · Button)
  for realism.
- **Given** a scene file, **When** its imports are inspected, **Then** it imports **only** `@mercury/ui`
  (+ `react` / `@storybook/react-vite`) — no `@mercury/effector`, no app import, no bundle /
  `window.MercuryUI` / `_ds_bundle` reference — and a lead comment names the cited real screen/pattern.
- **Given** the built index, **When** `sb:build` completes, **Then** the new `Scenes/<Name>` homes are
  registered and the prior component homes are unchanged.

INVEST — Independent (host-home, cross-component), Negotiable (the exact roster), Valuable (foundations in
context), Estimable (≥2 scenes), Small, Testable (`sb:build` + the import/hex greps); encodes mx.8.1-INV4,
mx.8.1-INV8.

Priority: Medium · Size: M · Implements deliverables: mx.8.1-D4.

## mx.8.1-US5 — the gate is green, the globals are live, the deferral is grounded

As a **design-system reviewer**, I want the full gate green with the barrel byte-identical and the globals
proven to actually drive the tokens, so that the slice is acceptable at the boundary without re-reading the
diff, and the actions deferral reads as a grounded finding, not a skip.

**Acceptance criteria**
- **Given** HEAD, **When** the gate runs, **Then** `sb:typecheck` · `sb:build` · `pnpm --filter "./packages/*"
  typecheck` + `build` · `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` all exit 0, and
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` is empty.
- **Given** a non-default Palette or Roundings selection, **When** the computed style is probed, **Then** it
  **measurably changes** on the book-wide surfaces (`Palette = green` ⇒ `rgb(48,164,108)`; `Roundings = Sharp`
  ⇒ Card `0px`, Avatar `9999px`) — a decorator that registers a picker but never overrides the variable FAILS.
- **Given** the foundations `.tsx`, **When** the handler grep runs, **Then**
  `grep -rnE "on[A-Z][A-Za-z]*\??:" packages/mercury-ui/src/components/foundations/*/*.tsx` is empty and no
  actions dependency is added (`apps/storybook/package.json` / `pnpm-lock.yaml` / `.storybook/main.ts`
  unchanged) — the K-4 deferral is a finding.

INVEST — Independent (the gate closes the slice), Negotiable (the probe harness), Valuable (cheap acceptance at
the boundary), Estimable, Small, Testable (the gate ladder + the render-check + the deferral grep); encodes
mx.8.1-INV1, mx.8.1-INV2, mx.8.1-INV5, mx.8.1-INV6, mx.8.1-INV7.

Priority: High · Size: S · Implements deliverables: mx.8.1-D5.

---

Coverage: D1→US1 · D2→US2 · D3→US3 · D4→US4 · D5→US5.  Spec: [mx.8.1.md](./mx.8.1.md) · Agent brief: [mx.8.1.llms.md](./mx.8.1.llms.md).
