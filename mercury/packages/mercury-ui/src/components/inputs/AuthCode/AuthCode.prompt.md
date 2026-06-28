# AuthCode — the split one-time-code entry

A row of single-character cells for entering a one-time / verification code, with auto-advance,
backspace-to-previous, full-paste distribution, and an `onComplete` callback when the last cell fills.
Reach for it for an OTP / 2FA / email-verification step. Import: `import { AuthCode } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `string` | — (required) | The controlled code so far; distributed across the cells (`value[i]`). |
| `onChange` | `(value: string) => void` | — (required) | Fired with the **string** code on every edit, paste, and backspace. |
| `onComplete` | `(value: string) => void` | — | Fired once the code reaches `length` characters (on type or paste). |
| `length` | `number` | `6` | Number of cells / the target code length. |
| `allow` | `"numeric" \| "alphanumeric"` | `"numeric"` | Allowed characters; also sets each cell's `inputMode` (`numeric` vs `text`). |
| `error` | `string` | — | Error message below the row; flips the row to the error styling. |
| `disabled` | `boolean` | — | Fades the row and blocks entry. |

## Composition

- **Composes:** nothing — a leaf (it manages a row of native `<input>` cells directly).
- **Composed by:** [AuthLayout](../../layout/AuthLayout/AuthLayout.prompt.md) — the verify-code
  auth screen. *(Sibling contracts authored across mx.2; links resolve at set completion.)*

## Examples

```tsx
// Six-cell numeric code with completion + error
<AuthCode value={code} onChange={setCode} onComplete={complete} length={6} error={error} />
// showcase/src/pages/patterns/AuthFlowPage.tsx
```

## Notes

- **Closed prop set** — `AuthCode` does **not** spread native attrs and is **not** a `forwardRef`
  component; the seven props above are the entire surface.
- **No enum props that resolve to a token family** — `allow` is a *behavioral* enum (it picks the
  character filter + `inputMode`), not a stylistic one, so there is no enum-language section. The only
  stylistic state is `error`.
- **Input behavior** — typing advances to the next cell and focuses it; Backspace on an empty cell
  moves back and clears the previous; a paste is sanitized against `allow`, distributed across the
  cells, and focuses the next empty position; non-matching characters are stripped.
- **Accessibility** — each cell carries `aria-label={`Digit ${i + 1}`}`. Focus is managed via the
  React-19 ref-callback idiom (`(refs.current ??= [])[i] = el`) with `refs.current?.[…]` guards.
