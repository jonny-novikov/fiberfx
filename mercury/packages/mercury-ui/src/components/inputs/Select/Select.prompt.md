# Select — the native dropdown field

A labeled native `<select>` driven by an `options` array, with a hint line, a validation-error state,
an optional disabled placeholder, and a styled chevron. Reach for it for a single choice from a small,
known set. Import: `import { Select } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `options` | `SelectOption[]` | — (required) | The choices. `SelectOption` = `{ label: string; value: string; disabled?: boolean }`. |
| `label` | `string` | — | Text label above the field; renders a ` *` marker when `required`. |
| `hint` | `string` | — | Helper copy below the field. Shown only when there is no `error`. |
| `error` | `string` | — | Error message below the field; sets `aria-invalid` + the error styling. Takes precedence over `hint`. |
| `placeholder` | `string` | — | When set, renders a leading `disabled hidden` empty-value option as the prompt. |
| `disabled` | `boolean` | — | Native; fades the field and blocks selection. |
| `required` | `boolean` | — | Native; also renders the ` *` marker beside the label. |
| `id` | `string` | auto (`useId`) | Ties the `<label htmlFor>` to the `<select>`; auto-generated when omitted. |
| …rest | `Omit<SelectHTMLAttributes<HTMLSelectElement>, "size">` | — | `value`/`defaultValue`, `onChange` (native event), `name`, `aria-*`, `className` pass through to the `<select>` (`forwardRef` to it). The native `size` attr is intentionally dropped. |

## Composition

- **Composes:** nothing — a leaf (it renders a native `<select>` plus a CSS chevron, no sibling
  component).
- **Composed by:** the calibration/settings forms that lay out a column of fields. *(Sibling contracts
  authored across mx.2; links resolve at set completion.)*

## Examples

```tsx
// Driven by an options array; native event onChange
<Select
  label="Average key price (akp)"
  options={pkgOptions}
  value={pkgValue}
  onChange={(e) => {
    const v = e.target.value;
    const pkg = PACKAGES.find((p) => String(p.keys) === v);
    if (pkg) pickPackage({ keys: pkg.keys, stars: pkg.stars });
  }}
/>
// codemojex-node/apps/economy/src/components/CalibrationForm.tsx
```

## Notes

- **`onChange` is the native event** (`e.target.value`), unlike `Search`/`AuthCode`/`Slider` which pass
  the value directly — `Select` extends the native `<select>` attrs (minus `size`).
- **No enum props** — no enum-language section. The only stylistic state is `error`: its presence
  flips the field to the **`negative`** status family and sets `aria-invalid="true"`; the `error` text
  takes the place of `hint`.
- **The placeholder** is implemented as a disabled, hidden, empty-value `<option>` rendered first — it
  shows as the prompt until a real value is chosen.
- **Accessibility** — wrapped in its `<label>` and tied by `id` (auto via `useId` when not supplied).
