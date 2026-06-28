# MX.2 · The contract layer — hand-author every component's `<Name>.prompt.md`

> **Status: ✅ BUILT — 33/33 contracts authored, gate-green 2026-06-28 (commit pending).** The first rung of **Movement II (the authored
> contract layer)**, and a re-sequencing: the Storybook movement (host · stories · deploy) shifts down
> to **Movement III (`mx.3`–`mx.6`)**. mx.1 left 33 grouped component folders with `<Name>.tsx` +
> `index.ts` but **zero contracts**; the design canon (§4, §6) already names a co-located
> `<Name>.prompt.md` the *authoritative* usage contract. mx.2 authors it — by hand, per component —
> and ratifies that the apps stay pure composers.
>
> **Risk: LOW.** No runtime code changes — mx.2 adds documentation (`.prompt.md`) and, if the audit
> finds one, an additive hoist. The master invariant (the barrel-diff) is untouched by docs and only
> grows under a hoist. The hazard is **fidelity**: a contract that misstates a prop misleads every
> human and agent that builds from it ([the contract-set discipline](../../../aaw/aaw.architect-approach.md)).
>
> **The decisions this rung rules** (canon §7): `D-7` (the contract format + grounding standard),
> `D-8` (the app/library split is ratified — the marginal hoist candidates stay internal).
>
> **As-built (2026-06-28, BUILD-GRADE).** All 33 contracts authored in 3 waves (≤2 authors/wave) via
> `/mercury-ship mx.2`. Gate green: coverage 33/33 · 75 cross-links resolve · no extractor framing ·
> `pnpm --filter` typecheck + build (4 pkgs) + apps build (5) exit 0 · barrel byte-identical (docs add
> no exports). The build-context inventory ([`mx.2.llms.md`](./mx.2.llms.md)) under-listed some props
> (notably `AuthLayout` by 10 brand-panel props; richer `Stat`/`Progress`/`Alert`/`Chart` surfaces) —
> each contract documents the **live `.tsx`** (source is truth; the inventory may lag, per lag-1). No
> source↔contract conflict found; `AuthLayout` correctly composes `Alert` (real edge) and excludes
> `Segmented` (page chrome, not a composition edge).

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · method:
[`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (the contract set) ·
acceptance: [`mx.2.stories.md`](./mx.2.stories.md) · build context: [`mx.2.llms.md`](./mx.2.llms.md).

## 0 · The slice — what mx.2 builds, and why contracts before Storybook

mx.1 adopted the Claude-Design layout — `src/components/<group>/<Name>/<Name>.tsx` + `index.ts`, 33
folders across 9 groups — but **deferred the contract** the canon promised beside each component
(canon §4: *"`<Name>.prompt.md` — the usage contract … props, variants, examples"*; §6: *"Each
component's `<Name>.prompt.md` + `<Name>.d.ts` is the authoritative contract"*). The generated stubs
that survive in `mercury/ds-bundle/components/<group>/<Name>/<Name>.prompt.md` are **extractor
output** — they open *"Use via `window.MercuryUI.Button` (bundle loaded from `_ds_bundle.js`)"* — a
runtime-shape note, not an authored contract: no rationale, no cross-reference, no grounding in how
the surface is actually composed.

mx.2 **hand-authors** the contract for each component, using the AAW architect's *contract set*
method ([aaw.architect-approach.md](../../../aaw/aaw.architect-approach.md)): each contract is a
**hypothesis** about how the component is used, **fed by** its siblings (it cross-links the
components it composes and the token families it honors) and **closed by feedback** — reconciled
against three truths: the component's own `.tsx` source, the *real* call sites in
`apps/showcase` + `codemojex-node/apps/economy`, and the sibling contracts it references.

Contracts come **before** the Storybook (Movement III) because a story is a rendered restatement of
a contract: `<Name>.stories.tsx` writes its `argTypes` and its variant grid from the same prop
language the contract fixes. Author the contract once, by hand, grounded; the stories then have a
single source to track.

## 1 · Goal

Every `@mercury/ui` component folder carries a **hand-authored `<Name>.prompt.md`** — grounded in
its real `.tsx` API and at least one real app call site, cross-referencing the siblings it composes
and the token vocabulary it speaks — and the app/library split is **ratified by audit**: any
genuinely-reusable UI found in the two reference apps is hoisted into `@mercury/ui` (additively, with
its own contract), and the marginal candidates are recorded as kept-internal. No component behavior,
prop, or token change. The master invariant holds.

## 2 · Rationale (5W)

- **Why.** The contract is the surface a human or a design/coding agent builds from. mx.1 shipped the
  components without it and left a generated stub in its place — a stub written for a runtime global,
  not for a builder. An unverified or extractor-shaped contract misleads every design produced from
  it. Hand-authoring, grounded and cross-linked, is the fix the canon already called for.
- **What.** 33 `<Name>.prompt.md` files (one per component folder), each: a one-line role; the prop
  contract grounded in the `.tsx`; the enum/variant language tied to the token families (canon §6);
  a **Composition** section that links the siblings it feeds and is fed by; **Examples** drawn from
  real call sites; and a11y/gotcha notes. Plus an **exemplar + a format note** (the template the set
  imitates), and an **audit** ratifying the app/library split.
- **Who.** *Authored by* Claude Code as Director-led architect (the exemplar) + author waves (the
  rest), per the contract-set method. *Consumed by* — (1) the Claude Design agent (every on-brand
  design it generates), (2) Mercury contributors choosing/Composing a component, (3) Movement III's
  Storybook stories, (4) any AAW implementor building UI on Mercury.
- **When.** Now — the opener of Movement II, gating on mx.1's grouped structure (met) and gated-by
  nothing else. It unblocks Movement III (the Storybook reads these contracts).
- **Where.** Co-located: `mercury/packages/mercury-ui/src/components/<group>/<Name>/<Name>.prompt.md`,
  beside each `<Name>.tsx`. The format note lives at `docs/mercury/contracts.md`; the audit's verdict
  is recorded as `D-8` in the canon §7. Grounding sources: `apps/showcase/src/**` +
  `codemojex-node/apps/economy/src/**`.

## 3 · Invariants (runnable checks)

- **INV-1 · The barrel holds.** Docs add no exports; a hoist adds exports only (additive). The
  barrel-diff (canon §2) shows **0 removed/renamed**.
- **INV-2 · Total coverage.** Every component folder under `src/components/<group>/<Name>/` has a
  `<Name>.prompt.md`. Mechanical: the count of `*.prompt.md` equals the count of `<Name>.tsx` (33/33).
- **INV-3 · Grounded, not invented.** Every prop a contract documents exists in that component's
  `.tsx` interface; every example imports only real `@mercury/ui` exports and uses only real props.
  No example cites `window.MercuryUI` or a prop the source does not define.
- **INV-4 · Cross-references resolve.** Every component a contract names in its Composition section
  resolves to a real sibling contract path; every token family it cites exists in canon §6.
- **INV-5 · The split is ratified.** The audit lists every app-housed UI element that *could* be
  reusable with a keep/hoist verdict; a hoist (if any) lands the component in `@mercury/ui` with a
  contract and leaves the app composing it — **no app houses a reusable component** (canon §2
  corollary).
- **INV-6 · The gate is green.** `pnpm -r typecheck` + `pnpm -r build` (4 packages) and
  `pnpm --filter "./apps/*" build` (5 apps) exit 0 — a contract-only rung must not perturb the build.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **exemplar contract** (`Button.prompt.md`) + the **format note** (`docs/mercury/contracts.md`) — section order, depth, grounding + cross-link standard | INV-3/INV-4 on the exemplar; the note fixes the template the set imitates |
| K-2 | **33 hand-authored `<Name>.prompt.md`**, grouped, grounded, cross-linked | INV-2 + INV-3 + INV-4; each reconciled against `.tsx` + ≥1 real call site |
| K-3 | The **app/library split audit** + verdicts (`D-8`) — `showcase` Demo/PropsTable, `economy` Mono ruled keep/hoist | INV-5; recorded in canon §7 |
| K-4 | Canon + dashboard updated — `D-7` (format), `D-8` (split), Movement re-sequence reflected | the roadmap, progress, design agree (one-authority) |

## 5 · The method (how the set is authored)

Per [aaw.architect-approach.md](../../../aaw/aaw.architect-approach.md) (*the contract set*):

1. **Exemplar first.** Author `Button.prompt.md` to the bar — it is the richest surface (six variants,
   three sizes, leading/trailing slots, loading/disabled states; used in both apps). The format note
   freezes its shape: role line · `## Props` (grounded table) · `## The enum language` (variants ↔
   token families) · `## Composition` (feeds / fed-by cross-links) · `## Examples` (real call sites,
   cited) · `## Notes`.
2. **Fan out in waves** (≤2 heavy authors concurrent), one group or a few components at a time, each
   author applying the exemplar and the format note, grounding every prop in the `.tsx` and every
   example in a call site from the two inventories.
3. **Reconcile.** Each contract is checked against the three truths (source · call sites · siblings);
   a mismatch in the *source* (a prop the apps use that the contract or even the `.tsx` lacks) is a
   **delta surfaced to the Operator**, not a silent edit.

The grounding is the two call-site inventories captured this rung: `apps/showcase` covers 24
components with full variant spreads; `economy` covers the data/inputs surface richest of all
(`Chart`, `Stat`, `Table`, `Slider`, `Select`, `Tag`). Five components have **no** app call site
(`Textarea`, `Search`, `Toggle`, `Accordion`, `Pagination`) — they are grounded in `.tsx` source
alone, and the contract says so.

## 6 · Dependencies

- **Hard-gates on:** `mx.1` (the grouped structure + the salvaged components — met).
- **Unblocks:** Movement III (`mx.3` Storybook host onward) — every `<Name>.stories.tsx` writes its
  `argTypes`/variant grid from the contract this rung fixes.
- **Touches:** `mercury/packages/mercury-ui/src/components/**/<Name>.prompt.md` (new docs);
  `docs/mercury/contracts.md` (new); `docs/mercury/mercury.design.md` §7 (`D-7`/`D-8`);
  the roadmap + progress (the re-sequence). A hoist (if the audit finds one) also touches the
  hoisted component's source + the app that composed it.
