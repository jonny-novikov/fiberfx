# Radio — the one-of-many choice

A single labelled radio button; group several under a shared `name` so the consumer holds the selected
value. Reach for it for a mutually-exclusive choice — a billing cadence, a plan tier. Import:
`import { Radio } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `string` | — (required) | This option's value; echoed back by `onChange`. |
| `checked` | `boolean` | `false` | Whether this is the selected option (`selected === value`). |
| `onChange` | `(value: string) => void` | — | Fires with **this radio's `value`** (not a boolean, not the event). |
| `label` | `ReactNode` | — | Text beside the ring; renders only when non-null. |
| `name` | `string` | — | The group key — radios sharing a `name` are mutually exclusive. |
| `disabled` | `boolean` | — | Dims to `0.45` + `not-allowed`. |
| `id` | `string` | — | Wires `<label htmlFor>` to the native `<input id>`. |

The control is a `<label>` wrapping a visually-hidden native `<input type="radio">`; it does **not**
`forwardRef` and passes through only the props above (no `…rest`).

## Composition

- **Composes:** nothing — a leaf.
- **Composed by:** [Card](../../data-display/Card/Card.prompt.md) (a settings/billing form, as a radio
  group). *(Sibling contract authored across mx.2; link resolves at set completion.)*

## Examples

```tsx
// A radio group — same `name`, the parent holds the selected value
<Radio name="billing" value="monthly"   label="Monthly"            checked={billing === "monthly"}   onChange={setBilling} />
<Radio name="billing" value="quarterly" label="Quarterly"          checked={billing === "quarterly"} onChange={setBilling} />
<Radio name="billing" value="yearly"    label="Yearly — save 20%"  checked={billing === "yearly"}    onChange={setBilling} />
// showcase/src/pages/components/SelectionPage.tsx
```

## Notes

- **There is no `RadioGroup` wrapper** — composition is the pattern: give every radio the same `name`,
  set `checked={selected === value}`, and let `onChange(value)` drive one `useState`.
- **`onChange` carries this radio's `value` string**, so the same setter serves every option in the
  group.
- **Tokens:** the ring sits on `--bg-primary` with a `--border-primary` inset; `checked` fills the ring
  to `--bg-brand` and scales the dot in; focus adds the `--ring-focus` halo. a11y is the native radio.
