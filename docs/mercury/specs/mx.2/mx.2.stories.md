# MX.2 · acceptance stories

Given/When/Then for [`mx.2.md`](./mx.2.md). Each story names the deliverable it realizes and the
invariant it proves. **Coverage:** K-1 → S-1; K-2 → S-2, S-3, S-4; K-3 → S-5; K-4 → S-6.

## S-1 · The exemplar fixes the shape (K-1)
**Given** 33 component folders with no contract, **when** the architect authors `Button.prompt.md`
and the format note `docs/mercury/contracts.md`, **then** the contract has the six sections in order
(role · Props · enum language · Composition · Examples · Notes), every prop in its table appears in
`actions/Button/Button.tsx`, and the note states the grounding + cross-link standard the rest imitate.
*(Proves INV-3 on the exemplar.)*

## S-2 · Every component has a hand-authored contract (K-2)
**Given** the exemplar and the format note, **when** the set is authored, **then** each folder under
`src/components/<group>/<Name>/` holds a `<Name>.prompt.md`, and the count of `*.prompt.md` equals the
count of `*.tsx` component files (33 = 33). **And** no contract contains the string `window.MercuryUI`
or `_ds_bundle` (it is authored, not extracted). *(Proves INV-2.)*

## S-3 · Contracts are grounded, not invented (K-2)
**Given** a hand-authored contract, **when** a reviewer checks any documented prop against the
component's `.tsx`, **then** the prop exists in the source interface; **and when** they run any
`## Examples` snippet's imports, **then** every imported name is a real `@mercury/ui` export and every
prop passed is one the source defines. A `Button` example shows `variant="destructive"` and
`leading={<Icon name="download" />}` (real, per `showcase/.../ButtonPage.tsx`); none shows an invented
prop. *(Proves INV-3.)*

## S-4 · The set feeds itself (K-2)
**Given** the authored set, **when** a reader opens `actions/Button/Button.prompt.md`, **then** its
Composition section links `Icon` (the `leading`/`trailing` slot) at the real relative path
`../../foundations/Icon/Icon.prompt.md`, **and** `data-display/Table/Table.prompt.md` links the
components its cells render (`Tag`, `Chip`, `Avatar`, `Progress` — per the `economy`/`showcase` table
call sites). Every linked path resolves to a sibling contract; every cited token family
(`--bg-*`, status families) exists in canon §6. *(Proves INV-4.)*

## S-5 · The app/library split is ratified (K-3)
**Given** the two reference apps, **when** the audit runs, **then** it lists each app-housed element
that could be reusable — `showcase` `Demo`/`PropsTable`, `economy` `Mono` — with a keep/hoist verdict
and a one-line reason, recorded as `D-8`. **And** if any element is hoisted, it lands in `@mercury/ui`
with a `<Name>.prompt.md` and the app is repointed to compose it — no app retains a reusable
component. *(Proves INV-5.)*

## S-6 · The build is undisturbed and the canon agrees (K-4)
**Given** a contract-only rung, **when** the gate runs, **then** `pnpm -r typecheck`, `pnpm -r build`
(4 packages), and `pnpm --filter "./apps/*" build` (5 apps) all exit 0, and the barrel-diff shows 0
removed/renamed. **And** the roadmap (Movement re-sequence), the progress dashboard, and the design
canon (`D-7`/`D-8`) state the same facts — the contract is the authoritative surface, co-located,
hand-authored. *(Proves INV-1 + INV-6 + one-authority.)*
