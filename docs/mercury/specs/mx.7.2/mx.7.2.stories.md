# mx.7.2 · acceptance stories

Given/When/Then for [`mx.7.2.md`](./mx.7.2.md). Connextra form; each names its deliverable + invariant(s).
**Coverage:** K-1 → S-1..S-10 ; K-2 → S-11 ; K-3/K-4 → S-1..S-10 ; K-5 → S-12 ; K-6 → S-1+S-9 ; K-7 → S-13 ;
K-8 → S-14. Every component story proves INV-2 (live idiom) + INV-6 (D-7 contract) unless noted.

## S-1 · Callout is a distinct inline emphasis block (not Alert)
*As a **docs author**, I want a `Callout` whose `intent` maps to the semantic token families, so that I can mark
a note in the reading flow.* **Given** `feedback/Callout/`, **when** `<Callout intent="caution" variant="soft">`
renders, **then** it styles via `.mx-callout` reading `--bg-caution`/`--fg-caution`/`--border-caution`, the
contract cross-links `Alert` (distinct role), and `Alert` is untouched. *(Proves INV-1 distinctness + INV-2.)*

## S-2 · Spinner is a token-driven loader with an a11y label
*As a **feedback author**, I want a `Spinner` with a `label`, so that loading is announced.* **Given**
`feedback/Spinner/`, **when** `<Spinner size="md" label="Loading" />` renders, **then** it spins 360°/1s via
`.mx-spinner`, `label` is the accessible name, `accent` is class-driven (no `mercAccent`), and the contract
cross-links `Skeleton` + `Button.loading`. *(Proves INV-2 + INV-4.)*

## S-3 · Skeleton is a pulse placeholder
*As a **loading-state author**, I want a `Skeleton` block, so that I can placeholder content.* **Given**
`feedback/Skeleton/`, **when** it renders with width/height/radius, **then** it pulses (1.5s opacity) via
`.mx-skeleton`, using dynamic non-color inline sizing (no color literal). *(Proves INV-2.)*

## S-4 · Blockquote is a quote rule
*As a **content author**, I want a `Blockquote`, so that I can set off a quotation.* **Given**
`data-display/Blockquote/`, **when** it renders, **then** `.mx-blockquote` draws a border-inline-start rule from
`--border-secondary`, `cite` is supported, `accent` is class-driven. *(Proves INV-2 + INV-4.)*

## S-5 · DataList renders term/description pairs
*As a **detail-view author**, I want a `DataList` of `items`, so that I can show key/value pairs.* **Given**
`data-display/DataList/`, **when** `<DataList items={…} orientation="horizontal" />` renders, **then** it emits a
`<dl>` via `.mx-datalist`, and the contract cross-links `Stat`/`Table`. *(Proves INV-2.)*

## S-6 · Code is inline/block DM-Mono code
*As a **docs author**, I want a `Code` primitive, so that I can show code inline or as a block.* **Given**
`data-display/Code/`, **when** `<Code block>` renders, **then** `.mx-code` uses `--font-secondary` (DM Mono) on
`--bg-tertiary`, `variant`/`block` switch treatments, and the contract cross-links `Kbd`. *(Proves INV-2.)*

## S-7 · Kbd is a keycap
*As a **docs author**, I want a `Kbd`, so that I can show a keyboard key.* **Given** `data-display/Kbd/`, **when**
`<Kbd>⌘K</Kbd>` renders, **then** `.mx-kbd` draws a keycap, `size` scales it, and the contract cross-links `Code`.
*(Proves INV-2.)*

## S-8 · AspectRatio constrains a ratio box
*As a **media author**, I want an `AspectRatio`, so that content holds a fixed ratio.* **Given** `layout/AspectRatio/`,
**when** `<AspectRatio ratio={16/9}>` renders, **then** `.mx-aspect` uses CSS `aspect-ratio` (dynamic inline,
non-color — allowed), and the contract cross-links `Avatar`/`Card` media. *(Proves INV-2.)*

## S-9 · Collapsible is a single disclosure (not Accordion), composing the live Icon
*As a **layout author**, I want a `Collapsible` with controlled + uncontrolled open state, so that I can toggle one
section.* **Given** `layout/Collapsible/`, **when** `<Collapsible title="Details" defaultOpen>` toggles, **then**
`.mx-collapsible` shows/hides children, the chevron is the **live `Icon`** (a real glyph, not invented),
`open`/`onOpenChange` drive controlled use, the contract cross-links `Accordion` (distinct), and `Accordion` is
untouched. *(Proves INV-1 distinctness + INV-5.)*

## S-10 · ScrollArea is a custom-scrollbar region
*As a **layout author**, I want a `ScrollArea`, so that overflow scrolls with a styled bar.* **Given**
`layout/ScrollArea/`, **when** `<ScrollArea scrollbars="vertical" maxHeight={240}>` renders, **then**
`.mx-scrollarea` styles the webkit scrollbar from tokens, `scrollbars` picks the axes, `maxHeight`/`width` are
dynamic inline (non-color). *(Proves INV-2.)*

## S-11 · The barrel grows +10 additively (K-2)
**Given** the barrel before/after, **when** the resolved export set is compared, **then** it is a superset — 0
removed, 0 renamed — +10 names (+ `Props`). *(Proves INV-1.)*

## S-12 · The 1:1 story↔folder invariant holds (K-5)
**Given** the 10 new folders, **when** `pnpm sb:typecheck` + `sb:build` run, **then** `sb:typecheck` exits 0,
`count(*.stories.tsx) == count(component folders)`, and `sb:build` registers prior + 10. *(Proves INV-7.)*

## S-13 · The token/font reconcile is additive-only (K-7)
**Given** `tokens.css` + fonts, **when** `git diff` is read, **then** any change is an added line, never a changed
value. *(Proves INV-8.)*

## S-14 · The gate is green; design flowed DOWN (K-8)
**Given** the 10 components, **when** the gate runs (packages typecheck/build · `echomq`+`mobile` build ·
`sb:typecheck` · `sb:build`), **then** all exit 0, the barrel-diff is 0 removed/renamed, the idiom/hex/`mercAccent`/
framing greps are empty, and no `/design-sync`/`DesignSync` ran. *(Proves INV-9 + INV-10.)*
