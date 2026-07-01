# mx.8.2 · stories — acceptance (Specification by Example)

The Operator's acceptance face of [`mx.8.2.md`](./mx.8.2.md). One Connextra story per deliverable, each with
concrete Given/When/Then (name the observable), an INVEST line naming the invariant(s) it exercises, and a
Priority/Size/Implements line. A gate specifies its own liveness — a no-op does not satisfy its letter.

---

## mx.8.2-US1 — every actions component is switchable across its full surface

As the **Claude Design agent** auditing the actions group, I want every actions story (`Button` · `IconButton` ·
`Link`) to expose its full exported-union control surface, so that each component is switchable across its every
variant/size/shape from the Controls panel and an invented option is caught.

**Acceptance criteria**
- **Given** the `Button` story, **When** the Controls panel opens, **Then** a `variant` control lists the full
  `ButtonVariant` union and `size` lists the full `ButtonSize` union (`sm`/`md`/`lg`); the boolean props render
  as `control: "boolean"` and the slot props (`leading`/`trailing`) stay `control: false`.
- **Given** the `IconButton` story, **When** the Controls panel opens, **Then** `variant` lists
  `IconButtonVariant` (`primary`/`secondary`/`outline`/`ghost`/`destructive`), `size` lists `IconButtonSize`
  (`sm`/`md`/`lg`), and `shape` lists `IconButtonShape` (`circle`/`square`).
- **Given** the `Link` story, **When** the Controls panel opens, **Then** `size` lists `LinkSize` (`sm`/`md`)
  and the boolean/slot props match its exported surface (slots `control: false`).
- **Given** a story option array typed by a real **literal** exported union, **When** an invented member is
  added, **Then** `sb:typecheck` fails. The mx.4 grid/state stories are kept.

INVEST — Independent (per-story argTypes), Negotiable (control widget kind), Valuable (the variant
interrogation), Estimable (three stories, exported unions are truth), Small, Testable (`sb:typecheck` +
Controls inspection); encodes mx.8.2-INV3, mx.8.2-INV8.

Priority: High · Size: M · Implements deliverables: mx.8.2-D1.

## mx.8.2-US2 — the action handlers fire and log, zero new dependency

As a **Mercury contributor** interrogating an actions component, I want each control's handler wired to a `fn()`
spy that logs to the Actions panel, so that I can confirm the control actually fires — using only Storybook's
core, with no new dependency.

**Acceptance criteria**
- **Given** an actions story, **When** its `meta` is inspected, **Then** it imports `fn` from the Storybook
  **core** subpath `storybook/test` and sets `args: { onClick: fn() }` (the handler-arg control stays
  `control: false` — the spy is on `args`, not a widget).
- **Given** the story renders in the running Storybook, **When** the control is activated (a click on the
  rendered `Button`/`IconButton`/`Link`), **Then** an entry appears in the SB **core** Actions panel — the spy
  is wired to the rendered handler (CSF3 auto-spread, or an explicit `onClick={args.onClick}` in a custom
  render); a spy present in `args` but not reaching a rendered handler is a LOUD failure.
- **Given** HEAD, **When** the diff is inspected, **Then** **no** `apps/storybook/package.json` /
  `pnpm-lock.yaml` / `.storybook/main.ts` change is present, and `require.resolve("storybook/test")` /
  `require.resolve("storybook/actions")` resolve from `apps/storybook/` (SB 10.4.6 core) — zero new dependency.

INVEST — Independent (per-story `meta`), Negotiable (the spied handler set), Valuable (confirm the control
fires), Estimable (one import + one `args` line per story), Small, Testable (the running-SB Actions panel + the
zero-dep grep/resolve); encodes mx.8.2-INV6, mx.8.2-INV7.

Priority: High · Size: M · Implements deliverables: mx.8.2-D2.

## mx.8.2-US3 — the actions lead a real screen

As the **mx.9 showcase author**, I want ≥1 host-home scene where the actions components lead a real screen, so
that Button/IconButton/Link are reviewable assembled into a real screen before they compose the shipped site.

**Acceptance criteria**
- **Given** the Storybook nav, **When** the new `Scenes/<Name>` story opens, **Then** the screen is carried by
  the actions components (Button/IconButton/Link lead), with a few real `@mercury/ui` components for realism, and
  it does not collide with `Scenes/Profile` / `Scenes/Article`.
- **Given** the scene file, **When** its imports are inspected, **Then** it imports **only** `@mercury/ui`
  (+ `react` / `@storybook/react-vite`) — no `@mercury/effector`, no app import, no bundle /
  `window.MercuryUI` / `_ds_bundle` reference — and a lead comment names the cited real screen/pattern.
- **Given** the built index, **When** `sb:build` completes, **Then** the new `Scenes/<Name>` home is registered
  and the prior component/scene homes are unchanged.

INVEST — Independent (host-home, cross-component), Negotiable (the exact scene + roster — a fork the Director
ratifies), Valuable (actions in context), Estimable (≥1 scene), Small, Testable (`sb:build` + the import/hex
greps); encodes mx.8.2-INV4, mx.8.2-INV8.

Priority: Medium · Size: M · Implements deliverables: mx.8.2-D3.

## mx.8.2-US4 — the gate is green, the spies live, the dependency count unchanged, the globals re-confirmed

As a **design-system reviewer**, I want the full gate green with the barrel byte-identical, the spies proven to
fire, and zero new dependency, so that the slice is acceptable at the boundary without re-reading the diff, and
the Fork-5 resolution reads as a proven finding.

**Acceptance criteria**
- **Given** HEAD, **When** the gate runs, **Then** `sb:typecheck` · `sb:build` · `pnpm --filter "./packages/*"
  typecheck` + `build` · `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` all exit 0, and
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` is empty.
- **Given** each spied control, **When** it is activated in the running Storybook, **Then** the SB core Actions
  panel logs an entry (a wired-but-dead spy FAILS); and **Given** the diff, **Then** no `package.json` /
  `pnpm-lock.yaml` / `.storybook/main.ts` change is present (`fn` resolves as an SB core subpath).
- **Given** a non-default Palette selection, **When** the computed style is probed on the **actions** surface,
  **Then** `Palette = green` ⇒ a `Button variant="primary"` computes `rgb(48, 164, 108)` — confirming mx.8.1's
  host-wide globals re-skin the actions group with `preview.tsx` **unedited** (inheritance, not a rebuild).

INVEST — Independent (the gate closes the slice), Negotiable (the inspection harness), Valuable (cheap
acceptance at the boundary + the Fork-5 finding), Estimable, Small, Testable (the gate ladder + the running-SB
liveness + the zero-dep resolve + the inherited-globals re-confirm); encodes mx.8.2-INV1, mx.8.2-INV2,
mx.8.2-INV5, mx.8.2-INV6, mx.8.2-INV7.

Priority: High · Size: S · Implements deliverables: mx.8.2-D4.

---

Coverage: D1→US1 · D2→US2 · D3→US3 · D4→US4.  Spec: [mx.8.2.md](./mx.8.2.md) · Agent brief: [mx.8.2.llms.md](./mx.8.2.llms.md).
