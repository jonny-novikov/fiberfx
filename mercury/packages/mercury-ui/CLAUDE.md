# @mercury/ui — the component library

Token-driven, **presentational** React components, **Claude-Design grouped**:
`src/components/<group>/<Name>/`. Depends on `@mercury/core`. Builds to `dist/` (vite lib + `tsc`) but
is consumed **from source** by the apps in dev. Default light theme; `dark-theme` on an ancestor flips
every token.

See the program CLAUDE.md ([`../../CLAUDE.md`]) for the AAW loop + the standing laws.

## The layout

Nine groups — `actions · foundations · inputs · selection · feedback · data-display · navigation ·
overlay · layout`. Each component folder holds three files:
`<group>/<Name>/{<Name>.tsx, index.ts, <Name>.prompt.md}`. The public barrel `src/index.ts` re-exports
every component **and** re-exports `cx`/`date`/the shared types from `@mercury/core`.

## The master invariant — the barrel holds

Every name exported from `src/index.ts` before a change is still exported after it (additions OK;
**removals/renames break the five apps**). The barrel uses `export *` per folder, so a text-diff of
`index.ts` is insufficient — resolve the full export set when unsure (the mx.1 check used TS
`getExportsOfModule`).

## Add / change a component

1. **`<group>/<Name>/<Name>.tsx`** — `forwardRef`, extend the HTML attrs, style via the private
   `.mx-*` className + tokens. Never inline a raw token value; never a utility class. Mind React 19's
   nullable `useRef().current` — guard with `if (ref.current)` (the idiom `Checkbox`/`Accordion` use).
2. **`index.ts`** = `export * from "./<Name>";`.
3. **`<Name>.prompt.md`** — the **hand-authored** contract (`D-7`; format at
   [`../../../docs/mercury/contracts.md`]): role · `## Props` (grounded in the `.tsx`) ·
   `## The enum language` (variants → token families) · `## Composition` (cross-link the siblings it
   feeds, by relative path) · `## Examples` (real call sites, cited) · `## Notes`. A generated
   design-sync stub is a seed, never the contract.
4. Add the export to **`src/index.ts`** (additive — never remove/rename an existing name).
5. Styles: a `.mx-*` rule in `src/styles/` (`mercury.css` / `additions.css`), `@import`ed by
   `styles/index.css`.

## Token discipline

Components style through **enum props** (`variant` / `size` / `tone`); your own layout uses
`rgb(var(--token))` (canon §6 — surfaces · text · borders · status families · ramps). The `.mx-*`
classes are **private**; a consumer never authors them.

Gate: `pnpm --filter @mercury/ui typecheck && pnpm --filter @mercury/ui build` + the barrel-diff.
