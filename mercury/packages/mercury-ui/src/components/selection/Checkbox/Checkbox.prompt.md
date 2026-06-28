# Checkbox — the boolean opt-in control

A single labelled checkbox with an optional tri-state (indeterminate) middle. Reach for it for a
standalone yes/no choice — a consent, a "remember me", a row in a multi-select list. Import:
`import { Checkbox } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `checked` | `boolean` | `false` | Controlled checked state. |
| `onChange` | `(checked: boolean) => void` | — | Fires with the **new boolean** (not the event). |
| `label` | `ReactNode` | — | Text beside the box; any node (e.g. a terms `Link`). Renders only when non-null. |
| `indeterminate` | `boolean` | `false` | The dash (middle) state — set imperatively on the native input. |
| `disabled` | `boolean` | — | Dims to `0.45` + `not-allowed`. |
| `name` | `string` | — | Native form field name. |
| `value` | `string` | — | Native form field value. |
| `id` | `string` | — | Wires the `<label htmlFor>` to the native `<input id>`. |

The control is a `<label>` wrapping a visually-hidden native `<input type="checkbox">`; it does **not**
`forwardRef` and passes through only the props above (no `…rest`).

## Composition

- **Composes:** nothing — a leaf. (The `label` slot is `ReactNode`, so a consumer may place an inline
  [Link](../../actions/Link/Link.prompt.md) there, but the control renders no fixed sibling.)
- **Composed by:** [AuthLayout](../../layout/AuthLayout/AuthLayout.prompt.md) (the auth-screen
  "remember me"), [Card](../../data-display/Card/Card.prompt.md) (a form's opt-in row). *(Sibling
  contracts authored across mx.2; links resolve at set completion.)*

## Examples

```tsx
// Auth "remember me"
<Checkbox checked={remember} onChange={setRemember} label="Remember me" />
// showcase/src/pages/patterns/SignInPage.tsx

// A column of opt-ins, with one disabled
<Checkbox label="Remember this device for 30 days" checked={remember} onChange={setRemember} />
<Checkbox label="Send me product updates" checked={updates} onChange={setUpdates} />
<Checkbox label="Can't change this" disabled />
// showcase/src/pages/components/SelectionPage.tsx
```

## Notes

- **`onChange` carries the boolean**, not the DOM event — wire it straight to a `useState` setter
  (`onChange={setRemember}`).
- **`indeterminate`** has no HTML attribute, so it is set on the input via a ref + `useEffect`; the
  source guards the React-19 nullable ref (`if (ref.current) ref.current.indeterminate = …`). The dash
  paints over the brand fill (`--bg-brand`); `checked` paints the check glyph in `--fg-on-brand`.
- **Idle vs. on:** the box sits on `--bg-primary` with a `--border-primary` inset ring; checked/
  indeterminate fill `--bg-brand`; focus adds the `--ring-focus` halo. a11y is the native checkbox —
  give it a `label` (or pair an external `id`/`htmlFor`).
