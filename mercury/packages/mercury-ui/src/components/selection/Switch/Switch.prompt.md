# Switch — the on/off toggle

A labelled sliding track for an immediate, self-contained on/off setting — notifications, a digest, a
feature flag. Reach for it when the change takes effect at once (vs. a Checkbox that stages a form
value). Import: `import { Switch } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `checked` | `boolean` | `false` | Controlled on/off state. |
| `onChange` | `(checked: boolean) => void` | — | Fires with the **new boolean** (not the event). |
| `label` | `ReactNode` | — | Text beside the track; renders only when non-null. |
| `disabled` | `boolean` | — | Dims to `0.45` + `not-allowed`. |
| `name` | `string` | — | Native form field name. |
| `id` | `string` | — | Wires `<label htmlFor>` to the native `<input id>`. |

The control is a `<label>` wrapping a visually-hidden native `<input type="checkbox" role="switch">`; it
does **not** `forwardRef` and passes through only the props above (no `…rest`).

## Composition

- **Composes:** nothing — a leaf.
- **Composed by:** [Card](../../data-display/Card/Card.prompt.md) (a settings row). *(Sibling contract
  authored across mx.2; link resolves at set completion.)*

## Examples

```tsx
// Settings toggles
<Switch label="Notifications" checked={notifications} onChange={setNotifications} />
<Switch label="Email digest"  checked={digest}        onChange={setDigest} />
// showcase/src/pages/components/SelectionPage.tsx
```

## Notes

- **`onChange` carries the boolean**, not the event — wire it to a `useState` setter.
- **Native semantics:** the input is a checkbox with `role="switch"`, so screen readers announce it as
  a switch; the `label` (or an external `id`/`htmlFor`) is the accessible name.
- **Tokens:** the on track is `--bg-brand`, the off track `--slate-7`, the thumb `--slate-1`; focus
  adds the `--ring-focus` halo. The thumb slides via the `mx-sw--off` class — no JS animation.
