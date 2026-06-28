# MX.4 · acceptance stories

Given/When/Then for [`mx.4.md`](./mx.4.md). Each story is in Connextra form, names the deliverable it
realizes and the invariant(s) it proves, and states concrete, checkable criteria — "done" is a closure
over these checks, not prose. **Coverage:** K-1 → S-1, S-2; K-2 → S-3; K-3 → S-4; K-4 → S-5; K-5 → S-6;
K-6 → S-7, S-8, S-9, S-10.

## S-1 · Every component has a story (K-1)
*As a **design-system browser**, I want a story for every component, so that the Storybook documents
the whole library, not a sample.*
**Given** the 33 component folders under `packages/mercury-ui/src/components/<group>/<Name>/` plus the
two new ones (`data-display/ListRow`, `inputs/MoneyInput`), **when** a reviewer counts
`*.stories.tsx`, **then** every folder has **exactly one** — `count(*.stories.tsx) == count(component
folders) == 35` (the 31 authored this rung + Button + Icon from mx.3 + ListRow + MoneyInput) — **and**
each is a CSF3 file importing only real `@mercury/ui` exports. *(Proves INV-4 coverage + INV-5
presence.)*

## S-2 · Story controls restate the contract, not invention (K-1)
*As an **AAW implementor**, I want each story's controls to restate the component's `<Name>.prompt.md`,
so that the story and the contract never drift.*
**Given** any component story, **when** a reviewer checks each `argTypes` entry against the component's
`.prompt.md` and `.tsx`, **then** every control name and option set is present in both, enum option
arrays are typed by the component's exported union (so an invented member is a compile error — e.g.
`const TONES: AlertTone[] = [...]`), `leading`/`trailing`/ReactNode slots are driven by a story arg
rendering a real `<Icon/>` (never a raw control, per the Button exemplar), **and** no story contains
the string `window.MercuryUI` or `_ds_bundle` or uses a prop the source does not define. *(Proves
INV-5.)*

## S-3 · Data-prop stories carry real-call-site sample data (K-2)
*As a **design reviewer**, I want the data-prop components shown with realistic data, so that Table /
Chart / Stat / Select / Slider / Segmented / Tabs / Accordion / Pagination / Checklist / ListRow read
as they do in the apps.*
**Given** a data-prop component's story, **when** a reviewer reads its `render`, **then** the sample
data is shaped to the component's prop type **and** is a usage that exists at the cited real call site
(`apps/showcase` or `codemojex-node/apps/economy`) named in a trailing comment; **and** a component
with **no** app call site (Accordion · Pagination · Search · Textarea · Toggle) is grounded in its
`.tsx` and says so in a comment. *(Proves INV-5.)*

## S-4 · Card gains additive header props, existing Cards unchanged (K-3)
*As a **panel author**, I want a Card header with a title and right-aligned actions, so that I stop
hand-rolling the `ecn-card-title` + flex-header pattern in every panel.*
**Given** `Card.tsx` with new optional `title?: ReactNode` and `actions?: ReactNode`, **when** a Card
is rendered with `title` and/or `actions`, **then** a header row renders above `children` (title left,
actions right; `justify:space-between, align:center`); **and** when both are absent **no** header
renders, so an existing `<Card>` call site (no `title`/`actions`) is byte-identical; **and** `CardProps`
is exported under the same name (no new export name), `Card.prompt.md` documents the two new props, and
`Card.stories.tsx` has a header story. *(Proves INV-1 no-new-export + INV-7 + INV-8.)*

## S-5 · ListRow ships as a new additive component (K-4)
*As a **mobile-screen author**, I want a reusable `ListRow`, so that the settings/activity row lives in
`@mercury/ui` instead of `chrome/Row.tsx`.*
**Given** a new folder `data-display/ListRow/` with `ListRow.tsx` · `index.ts` · `ListRow.prompt.md`
(hand-authored) · `ListRow.stories.tsx` · `.mx-listrow*` styles, **when** the gate runs, **then** the
barrel exports `ListRow` and `ListRowProps` (additively), the component renders the mobile
settings/activity shape (`leading` · `label` · `description?` · `value?`/`trailing?` · optional
`onClick` → interactive `<button>`), its story renders, and the contract grounds in `ListRow.tsx` + the
cited `apps/mobile/src/chrome/{Row,ActivityList}.tsx` call sites. *(Proves INV-1 + INV-5 + INV-7 +
INV-8.)*

## S-6 · MoneyInput ships as a new additive component (K-5)
*As a **fintech-screen author**, I want a reusable `MoneyInput`, so that the currency-amount field lives
in `@mercury/ui` instead of the hand-rolled `.em-amt` block.*
**Given** a new folder `inputs/MoneyInput/` with `MoneyInput.tsx` · `index.ts` · `MoneyInput.prompt.md`
(hand-authored) · `MoneyInput.stories.tsx` · `.mx-*` styles, **when** the gate runs, **then** the
barrel exports `MoneyInput` and `MoneyInputProps` (additively), the component renders a `currency`
prefix (default `"$"`) + a decimal-mode numeric input + `label`/`hint`/`error` like `Input` with
controlled `value`/`onChange`, its story renders, and the contract grounds in `MoneyInput.tsx` + the
cited `apps/mobile/src/screens/Send.tsx` call site. *(Proves INV-1 + INV-5 + INV-7 + INV-8.)*

## S-7 · The barrel grows additively — additions only (K-6)
*As a **downstream consumer**, I want the public surface to only grow, so that nothing I import
breaks.*
**Given** the `@mercury/ui` barrel before and after mx.4, **when** the additions-only barrel-diff runs
(`diff <(git show HEAD:…/index.ts | grep -oE 'export .*') <(grep -oE 'export .*' …/index.ts)`) **and**
the resolved export set is compared, **then** the diff shows **only added lines** (the two new
`export *` lines), **0 removed/renamed**, and the new export names are **exactly** `ListRow`,
`ListRowProps`, `MoneyInput`, `MoneyInputProps` (Card adds no new export name). *(Proves INV-1.)*

## S-8 · The product apps + packages still build (K-6)
*As a **Director**, I want the additive growth to leave the apps untouched, so that the rung ships
without a regression.*
**Given** the new components + Card props + 33 new stories, **when** the per-rung gate runs
`pnpm --filter "./packages/*" typecheck`, `pnpm --filter "./packages/*" build`, and
`pnpm --filter "./apps/*" --filter "!@mercury/storybook" build`, **then** all exit 0 — the three
packages typecheck/build and the **five** product apps build (the storybook app excluded). *(Proves
INV-2.)*

## S-9 · The library gate ignores the stories; the host needs no edit (K-6)
*As a **package maintainer**, I want the co-located stories to stay out of the library `tsc` and the
host glob to already cover them, so that the fan-out adds zero gate/host wiring.*
**Given** the 33 new co-located `*.stories.tsx` under `packages/mercury-ui/src/components/`, **when**
`pnpm --filter @mercury/ui typecheck`/`build` run, **then** both exit 0 because the mx.3
`packages/mercury-ui/tsconfig.json` `**/*.stories.tsx` exclude (`D-9`) already holds — **and** `git
diff` shows **no** file changed under `apps/storybook/` (the mx.3 glob
`packages/mercury-ui/**/*.stories.@(tsx|ts)` already matches every new story). *(Proves INV-3 +
INV-6.)*

## S-10 · The Storybook registers every story (K-6)
*As a **design-system browser**, I want every component visible in the built Storybook, so that the
host is the complete library reference.*
**Given** the complete fan-out, **when** the Director runs `pnpm sb:build`, **then** it exits 0 and
registers **36** story homes — the 35 component stories (one per component folder, including ListRow +
MoneyInput) plus the host-local `Foundations/Tokens` story — **and** each renders under the mx.3
light/`dark-theme` decorator (a `ListRow`/`MoneyInput`/`Card`-header story flips dark with the tokens).
*(Proves INV-4 + INV-8.)*
