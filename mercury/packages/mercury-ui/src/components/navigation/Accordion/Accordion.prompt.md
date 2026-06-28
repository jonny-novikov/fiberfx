# Accordion — the collapsible disclosure stack

An uncontrolled stack of titled, expandable panels — `single` mode keeps one open, `multiple` lets many
open at once. Reach for it for an FAQ, a settings group, or any vertical list of disclosures. Import:
`import { Accordion } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `AccordionItemData[]` | — (required) | The panels. Each is `{ value: string; title: ReactNode; content: ReactNode; disabled?: boolean }`. |
| `type` | `"single" \| "multiple"` | `"single"` | `single` keeps one item open; `multiple` allows many. |
| `defaultValue` | `string \| string[]` | — | Initially-open value(s) for the uncontrolled stack. |
| `collapsible` | `boolean` | `true` | In `single` mode, allow the open item to collapse to none. |
| `className` | `string` | — | Merged onto the root `.mx-acc` (via `cx`). |
| …rest | `HTMLAttributes<HTMLDivElement>` (minus `defaultValue`) | — | Native div attrs pass through; `forwardRef` to the `<div>`. |

`AccordionProps extends Omit<HTMLAttributes<HTMLDivElement>, "defaultValue">` — `defaultValue` is
re-typed to the item-value shape above, so it does not collide with the native attribute.

## The enum language

`type` is a behaviour switch, not a token recipe — it gates how `open` state folds (`single` collapses
the others; `multiple` accumulates). There are no variant/size/tone props, so no token family applies;
the panels style from the surface tokens (`--bg-*`, `--border-secondary`) of the `.mx-acc` recipe.

## Composition

- **Composes:** nothing — a leaf. `title` and `content` are open `ReactNode` slots you fill; the caret is
  an inline SVG.
- **Composed by:** no current call site — a candidate for settings panels and FAQ sections.

## Examples

```tsx
// Single (default) — one panel open at a time, first open initially
<Accordion
  items={[
    { value: "what", title: "What is Mercury?", content: <p>A token-driven React design system.</p> },
    { value: "how", title: "How do I theme it?", content: <p>Flip a token set on an ancestor.</p> },
    { value: "more", title: "Where are the docs?", content: <p>In each component's contract.</p> },
  ]}
  defaultValue="what"
/>
// (source-grounded; no app call site)

// Multiple — several panels open together, with a disabled row
<Accordion
  type="multiple"
  items={[
    { value: "a", title: "Shipping", content: <p>Ships in 2–3 days.</p> },
    { value: "b", title: "Returns", content: <p>30-day window.</p> },
    { value: "c", title: "Archived", content: <p>Unavailable.</p>, disabled: true },
  ]}
/>
// (source-grounded; no app call site)
```

## Notes

- **(source-grounded; no app call site)** — no app composes `Accordion`; the snippets above are the
  minimal valid usage built from `Accordion.tsx`.
- **Uncontrolled** — open state lives inside the component, seeded by `defaultValue`. In `single` mode
  with `collapsible={false}`, the last-open item cannot be closed by re-clicking it.
- **The React-19 nullable-`useRef().current` idiom** — the trigger refs are held in
  `useRef<(HTMLButtonElement | null)[]>([])`, and **every** access guards the nullable `.current`
  first: the ref callback does `if (triggers.current) triggers.current[i] = el`, and roving focus does
  `triggers.current?.[next]?.focus()`. Mirror that guard rather than dereferencing `.current` directly.
- **a11y** — arrow-key roving focus (`ArrowUp`/`ArrowDown`/`Home`/`End`) skips `disabled` rows; each
  trigger carries `aria-expanded` + `aria-controls` to its `role="region"` panel.
