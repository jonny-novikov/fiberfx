# Label — the form-caption primitive

A field caption: semibold text with an accent-tinted required marker, a muted `(optional)` tag, and an
optional hint line, in three sizes. Reach for it to caption any input. Import:
`import { Label } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `htmlFor` | `string` | — | Associates the label with an input `id` (native `LabelHTMLAttributes`). |
| `required` | `boolean` | — | Renders the `*` required marker (tinted by `accent`). |
| `optional` | `boolean` | — | Renders a muted `(optional)` tag. |
| `disabled` | `boolean` | — | Dims the label (`is-disabled`) and sets `not-allowed`. |
| `size` | `"sm" \| "md" \| "lg"` (`LabelSize`) | `"md"` | Caption text size. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | `"red"` | Ramp that tints the required `*` (reads `--<ramp>-11`). |
| `hint` | `ReactNode` | — | A muted helper line below the caption (`--fg-tertiary`). |
| `children` | `ReactNode` | — | The caption text. |
| …rest | `LabelHTMLAttributes<HTMLLabelElement>` | — | `id`, `className`, `aria-*`, … pass through to the `<label>`. |

## The enum language

- `size` resolves to `.mx-label--<sm\|md\|lg>` — the caption text size (12 / 13 / 14px), with the
  `(optional)` tag and hint one step down.
- `accent` resolves to `.mx-label--accent-<id>`, which tints the required `*` via `--<ramp>-11`. The
  default `red` reads `--red-11`. Tokens only — no inline color.
- The caption is semibold (`--fw-semi-bold`) in DM Sans (`--font-primary`); the hint + `(optional)` tag
  read `--fg-tertiary`.

## Composition

- **Composes:** nothing — a leaf.
- **Captions:** [Input](../Input/Input.prompt.md), [Textarea](../Textarea/Textarea.prompt.md),
  [Select](../Select/Select.prompt.md) — pass the input's `id` to `htmlFor` so the caption and control
  are associated.
- **Composed by:** form rows and field groups across the apps.

## Examples

```tsx
// A required field caption with a hint, associated to its input
<Label htmlFor="email" required hint="We never share it.">Email address</Label>
<Input id="email" type="email" />

// An optional field, large size
<Label htmlFor="bio" optional size="lg">Bio</Label>

// A disabled caption
<Label htmlFor="locked" disabled>Locked</Label>
```

## Notes

- **Association** — set `htmlFor` to the input's `id`; clicking the caption then focuses the control.
- **Required marker** — the `*` is `aria-hidden`; signal the required state to AT on the input itself
  (`required` / `aria-required`), since color/marker alone is not an accessible signal.
- `accent` recolors only the required `*`, not the caption text.
- (source-grounded; no app call site — a net-new mx.7.1 import.)
