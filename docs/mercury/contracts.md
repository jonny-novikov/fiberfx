# Mercury component contracts — the format note (`D-7`)

The **frozen template** for a component's co-located `<Name>.prompt.md`. Every `@mercury/ui` component
carries one; it is the **authoritative usage surface** (canon
[`mercury.design.md`](./mercury.design.md) §4/§6), read by the Claude Design agent, by Mercury
contributors, and by Movement III's Storybook stories. It is **hand-authored**, never the design-sync
stub. The method is the AAW *contract set* — [`../aaw/aaw.architect-approach.md`](../aaw/aaw.architect-approach.md).

The reference exemplars are
[`Button.prompt.md`](../../mercury/packages/mercury-ui/src/components/actions/Button/Button.prompt.md)
and [`Icon.prompt.md`](../../mercury/packages/mercury-ui/src/components/foundations/Icon/Icon.prompt.md)
— a composing pair (Button composes Icon; Icon is composed-by Button). New contracts imitate their
shape exactly.

## A contract is a hypothesis, closed by feedback

Each contract is a claim about how the component is used, authored **against the source** and
**reconciled against three truths** before it is trusted:

1. **The implementation** — every prop documented exists in the component's `.tsx`; every default and
   type matches. The `.tsx` is truth, not the generated seed (which can lag).
2. **The real call sites** — every `## Examples` snippet is a usage that exists in `apps/showcase` or
   `codemojex-node/apps/economy`, cited by a trailing comment. No example is invented to read well.
3. **The sibling contracts** — every cross-reference resolves; the vocabulary (token families, shared
   props) agrees across the set.

A mismatch edits the contract. A mismatch in the *implementation* (a prop the apps use that the source
lacks) is a **delta surfaced to the Operator**, never silently smoothed.

## The six sections (order is load-bearing)

```markdown
# <Name> — <one-line role>

<One sentence: what it is and when to reach for it.> Import: `import { <Name> } from "@mercury/ui"`.

## Props
| Prop | Type | Default | Notes |
|---|---|---|---|
<every prop from <Name>.tsx — required first. Type as written in the source; default as written.>
<for a fixed enum, the union members; for a slot, `ReactNode`. Note native-attr pass-through.>

## The enum language
<the variant/size/tone props and the token families (canon §6) they resolve to. Omit if the component
has no enum props.>

## Composition
- **Composes:** [Sibling](<relative path to its .prompt.md>) (which slot / why), …
- **Composed by:** [Sibling](<relative path>) (the context), …
<the "feeds each other" edge. Cross-link by REAL relative path between co-located contracts, e.g.
actions/Button → foundations/Icon is `../../foundations/Icon/Icon.prompt.md`. A named sibling with no
contract yet is a gap made visible — list it; it resolves when the set is complete.>

## Examples
<2–4 grounded snippets. Each is a real usage, cited:>
```tsx
<Button variant="destructive" leading={<Icon name="trash" size={14} />}>Delete</Button>
// showcase/src/pages/components/ButtonPage.tsx
```

## Notes
<a11y, state behavior, gotchas (e.g. the React-19 nullable-`useRef().current` idiom), and — for a
component with no app call site — the line "(source-grounded; no app call site)".>
```

## Conventions

- **Grounding** — props from the live `.tsx`; examples from real call sites (cite the file). The five
  components with **no** app usage (`Textarea` · `Search` · `Toggle` · `Accordion` · `Pagination`) are
  grounded in source alone and say so.
- **Cross-links** — relative paths between co-located `<Name>.prompt.md`, so a reader (and a docs
  tool) can traverse the set. The barrel and the groups give the path: `<group>/<Name>/<Name>.prompt.md`.
- **No extractor framing** — never `window.MercuryUI`, never `_ds_bundle`. The contract is authored for
  a developer/agent composing `@mercury/ui`, not for a runtime global.
- **Tokens, not values** — name the token family (`--bg-brand`, the status families) the enum resolves
  to; never a raw hex/RGB.

## Coverage

33 components across 9 groups (canon §4.1). The set is authored exemplar-first, then in waves; the
gate is total coverage (`*.prompt.md` count == `*.tsx` count) with every contract reconciled. See
[`specs/mx.2/mx.2.llms.md`](./specs/mx.2/mx.2.llms.md) for the per-component grounding inventory.
