# MoneyInput — the currency-amount field

A labeled currency-amount field — a `currency` prefix affix, a decimal-mode numeric entry, and the
same `label`/`hint`/`error` line as [Input](../Input/Input.prompt.md). Reach for it for any money
amount (a send/transfer field, a price, a deposit) instead of hand-rolling a currency span beside a
bare `<input>`. Composes `Input`, supplying the currency in its `leading` slot and defaulting
`inputMode="decimal"`. Import: `import { MoneyInput } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `currency` | `string` | `"$"` | The currency prefix rendered in the `leading` affix (e.g. `$` or `USD`). |
| `label` | `string` | — | Field label above the input (passed to `Input`). |
| `hint` | `string` | — | Helper copy below; shown only when there is no `error` (passed to `Input`). |
| `error` | `string` | — | Error message below; sets `aria-invalid` + the error styling. Takes precedence over `hint` (passed to `Input`). |
| `value` / `onChange` | controlled | — | Numeric/decimal entry; flows through to the inner `<input>` (`forwardRef` points at it). |
| `inputMode` | `InputHTMLAttributes["inputMode"]` | `"decimal"` | The keyboard mode; defaults to `decimal`, overridable. |
| …rest | `Omit<InputHTMLAttributes<HTMLInputElement>, "size">` | — | `placeholder`, `value`/`defaultValue`, `onBlur`, `min`, `step`, `name`, `aria-*` pass through to the `<input>` (mirrors `InputProps`; the native `size` attr is intentionally dropped). |

## The enum language

No enum props — like `Input`, `MoneyInput` has no `variant`/`size`/`tone`. Its single stylistic state
is `error`: its presence flips the field to the **`negative`** status family and sets
`aria-invalid="true"` (inherited from `Input`). The `currency` affix resolves to the `--fg-secondary`
token via `.mx-money__ccy`; never a raw hex.

## Composition

- **Composes:** [Input](../Input/Input.prompt.md) — `MoneyInput` is a thin wrapper that fills `Input`'s
  `leading` slot with the `currency` affix and defaults `inputMode="decimal"`; all of `Input`'s
  label/hint/error/native-attr behavior is inherited.
- **Composed by:** the send/transfer and amount-entry forms (the fintech screens) — the mobile
  Send screen's amount block is the canonical call site below.

## Examples

```tsx
// The Send-screen amount field (controlled)
<MoneyInput
  currency="USD"
  label="Amount"
  hint="Available: $4,218.40 USD"
  value={amount.value}
  error={amount.error}
  onChange={(e) => amount.onChange(e.target.value)}
  onBlur={amount.onBlur}
/>
// absorbs apps/mobile/src/screens/Send.tsx (the `.em-amt` block: `<span className="em-amt-ccy">USD</span>`
// + `<input inputMode="decimal">` + a hint/error line)

// A minimal dollar amount with a placeholder
<MoneyInput label="Deposit" placeholder="0.00" />
```

## Notes

- **Composition over re-implementation** — `MoneyInput` does not re-derive the field chrome; it renders
  an `Input` with `leading={<span className="mx-money__ccy">{currency}</span>}`, so the label, hint,
  error, focus ring, and disabled state are exactly `Input`'s. A change to `Input` flows through.
- **`forwardRef`** — the ref is forwarded to `Input`'s inner `<input>` (mirroring `InputProps`'
  `forwardRef`), so a caller can focus/measure the field.
- **`inputMode` default** — defaults to `"decimal"` (the mobile decimal keypad) and is overridable; the
  component does no formatting/parsing — `value`/`onChange` are the caller's (string) responsibility,
  matching the `Input` contract.
