# Input — the single-line text field

A labeled single-line text entry with optional leading/trailing adornments, a hint line, and a
validation-error state. Reach for it for any one-line value — email, password, a number, a search box,
a workspace name. Import: `import { Input } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | `string` | — | Text label above the field; renders a ` *` marker when `required`. |
| `hint` | `string` | — | Helper copy below the field. Shown only when there is no `error`. |
| `error` | `string` | — | Error message below the field; sets `aria-invalid` + the error styling. Takes precedence over `hint`. |
| `leading` | `ReactNode` | — | Prefix slot inside the field — usually an `<Icon />`. |
| `trailing` | `ReactNode` | — | Suffix slot inside the field. |
| `disabled` | `boolean` | — | Native; fades the field and blocks entry. |
| `required` | `boolean` | — | Native; also renders the ` *` marker beside the label. |
| `id` | `string` | auto (`useId`) | Ties the `<label htmlFor>` to the `<input>`; auto-generated when omitted. |
| …rest | `Omit<InputHTMLAttributes<HTMLInputElement>, "size">` | — | `type`, `placeholder`, `value`/`defaultValue`, `onChange`, `onBlur`, `min`, `step`, `inputMode`, `name`, `aria-*`, `className` pass through to the `<input>` (`forwardRef` to it). The native `size` attr is intentionally dropped. |

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — in the `leading`/`trailing` adornment
  slot (`leading={<Icon name="search" size={14} />}`).
- **Composed by:** [AuthLayout](../../layout/AuthLayout/AuthLayout.prompt.md) (the auth-screen
  fields), and the calibration/sign-in forms that lay out a column of fields. *(Sibling contracts
  authored across mx.2; links resolve at set completion.)*

## Examples

```tsx
// Basic — labeled email
<Input label="Email" type="email" placeholder="you@company.com" />
// showcase/src/pages/components/InputPage.tsx

// With an Icon adornment
<Input type="search" placeholder="Search documentation" leading={<Icon name="search" size={14} />} />
// showcase/src/pages/components/InputPage.tsx

// Hint vs. error state
<Input label="Workspace" placeholder="acme" hint="3–32 characters" />
<Input label="Subdomain" defaultValue="mercury" error="That subdomain is already taken" />
// showcase/src/pages/components/InputPage.tsx

// Controlled number field in a calibration form
<Input
  label="Diamonds per USD" hint="10💎 = $1" type="number"
  min={1} step={1} inputMode="decimal"
  value={dpu.value} error={dpu.error}
  onChange={onNum(dpu.onChange)} onBlur={dpu.onBlur}
/>
// codemojex-node/apps/economy/src/components/CalibrationForm.tsx
```

## Notes

- **No enum props** — `type` is the native HTML attribute (passed through), not a Mercury style enum,
  so there is no enum-language section. The only stylistic state is `error`: its presence flips the
  field to the **`negative`** status family and sets `aria-invalid="true"`; the `error` text takes the
  place of `hint`.
- **Accessibility** — the field is wrapped in its `<label>` and tied by `id` (auto via `useId` when
  not supplied), so the label, hint, and error are programmatically associated without extra wiring.
- The native `size` attribute is omitted from the prop type to avoid colliding with the design
  system's sizing vocabulary; pass sizing through layout/tokens instead.
