# mx.7.1 · acceptance stories

Given/When/Then for [`mx.7.1.md`](./mx.7.1.md). Connextra form; each names the deliverable + the invariant(s)
it proves. **Coverage:** K-1 → S-1..S-5 ; K-2 → S-6 ; K-3/K-4 → S-1..S-5 ; K-5 → S-7 ; K-6 → S-3 ; K-7 → S-8 ;
K-8 → S-9.

## S-1 · Heading is a translated DM-Mono display primitive (K-1, K-3, K-4)
*As a **page author**, I want a `Heading` that renders the canon's DM-Mono display face at the large sizes, so
that section titles carry the Mercury type identity.*
**Given** `packages/mercury-ui/src/components/foundations/Heading/` (4 files), **when** `<Heading size={3}>`
renders, **then** it emits the right `<h*>` (or `as`), styles via `.mx-heading` classes (no inline color, no raw
hex), picks `--font-secondary` (DM Mono) at the display sizes, resolves `accent` via `.mx-heading--accent-*`
(no `mercAccent` import), and its `Heading.prompt.md` is hand-authored (mx.2 sections, cross-links `Text`).
*(Proves INV-2 + INV-4 + INV-5.)*

## S-2 · Text is the body-copy primitive (K-1, K-3, K-4)
*As a **content author**, I want a `Text` primitive whose `variant` maps to the `--fg-*` token families, so that
body copy is theme-driven.*
**Given** `foundations/Text/`, **when** `<Text variant="secondary">` renders, **then** it styles via
`.mx-text--secondary` reading `rgb(var(--fg-secondary))` (no inline literal), supports `italic`/`align`/`accent`
(class-driven), and carries a hand-authored contract cross-linking `Heading`. *(Proves INV-2 + INV-4 + INV-5.)*

## S-3 · Separator lands net-new without renaming Divider (K-1, K-6)
*As a **layout author**, I want a `Separator` with the bundle's vertical/labelled/`decorative` API, so that I have
the Claude-Design rule primitive — **without losing `Divider`**.*
**Given** the live barrel exports `Divider`, **when** mx.7.1 adds `Separator` (Fork A arm (a)), **then** `Divider`
is **unedited and still exported** (no rename — master invariant), `Separator` exports additively with
`orientation`/`label`/`size`/`decorative` styling via `.mx-separator` + `--border-secondary`, and the two
contracts cross-link. *(Proves INV-1 + the Fork-A ruling.)*

## S-4 · IconButton reuses the button tokens, icon-only + always-round (K-1, K-3, K-4)
*As an **actions author**, I want an icon-only `IconButton` sharing `Button`'s variant/size language, so that an
icon action is consistent with text buttons and accessible.*
**Given** `actions/IconButton/`, **when** `<IconButton icon={…} label="Close" variant="ghost" />` renders,
**then** it styles via `.mx-icon-btn` reading the shared button tokens, `shape="circle"` is `--radius-full`,
`label` becomes `aria-label` (icon-only a11y), the `variant`/`size` unions equal `ButtonProps`', and the contract
cross-links `Button`+`Icon`. *(Proves INV-2 + INV-5.)*

## S-5 · Label is the form-caption primitive (K-1, K-3, K-4)
*As a **form author**, I want a `Label` with required/optional markers and a hint, so that field captions are
consistent.*
**Given** `inputs/Label/`, **when** `<Label htmlFor="email" required hint="We never share it">` renders, **then**
it emits `<label htmlFor>`, the required `*` reads `--red-11` via `.mx-label__req` (no `mercAccent`), `optional`
renders muted, `hint` is `--fg-tertiary`, and the contract cross-links the inputs it captions. *(Proves INV-2 +
INV-4 + INV-5.)*

## S-6 · The barrel grows +5 additively (K-2)
*As a **downstream consumer**, I want every prior export preserved, so that nothing I import breaks.*
**Given** the `@mercury/ui` barrel before/after, **when** the resolved export set is compared (TS
`getExportsOfModule`, not a text-diff), **then** it is a **superset** — 0 removed, 0 renamed — with exactly the 5
new component names + their `Props` added. *(Proves INV-1.)*

## S-7 · The 1:1 story↔folder invariant holds (K-5)
*As a **Storybook maintainer**, I want each new component to carry exactly one co-located story, so that the mx.4
invariant stays intact.*
**Given** the 5 new folders, **when** `pnpm sb:typecheck` + `pnpm sb:build` run, **then** `sb:typecheck` exits 0
(the NO-INVENT story gate), `count(*.stories.tsx) == count(component folders)`, and `sb:build` registers exactly
the prior homes + 5. *(Proves INV-6.)*

## S-8 · The token/font reconcile is additive-only (K-7)
*As a **token owner**, I want no existing token value changed, so that the rest of the library is undisturbed.*
**Given** `tokens.css` + the font layer, **when** `git diff` is read, **then** any change is an **added** line (the
DM Sans 600 `@font-face`, only if a component needs weight 600), never a changed value. *(Proves INV-7.)*

## S-9 · The gate is green; design flowed DOWN (K-8)
*As a **Director**, I want the full package gate green and no design push, so that the batch ships clean.*
**Given** the 5 translated components, **when** the gate runs — `pnpm --filter "./packages/*" typecheck`/`build` ·
`pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` · `pnpm sb:typecheck` · `pnpm sb:build` — **then**
every command exits 0, the barrel-diff is 0 removed/renamed, the idiom/hex/`mercAccent`/framing greps are empty,
and **no** `/design-sync`/`DesignSync` invocation occurred. *(Proves INV-1 + INV-8 + INV-9.)*
