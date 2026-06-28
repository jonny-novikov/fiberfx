# PasswordStrength — a labelled password-strength meter

A small strength meter for a password field: a `size="sm"` Progress bar plus a tone-colored word label.
Presentational — pass a precomputed `score`, `label`, and `variant`. Reach for it under a password input
on a sign-up or reset screen. Import: `import { PasswordStrength } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `score` | `number` | — (required) | 0–100; drives the Progress bar `value`. |
| `label` | `string` | — | The strength word (e.g. "Weak" / "Strong"); rendered only when set. |
| `variant` | `StrengthVariant` | `"negative"` | Bar + label color (see the enum language). |
| `className` | `string` | — | Extra class merged onto the root `<div>`. |

`StrengthVariant` = `"negative" \| "caution" \| "positive"`.

The component takes **no other `…rest`** and is **not** `forwardRef`.

## The enum language

`variant` maps 1:1 onto the inner `Progress` variant (`TO_PROGRESS`) and onto the label color
(`.mx-pwstr__lbl--<variant>`), over the **status families** (canon §6):

- `negative` — the `negative` family (the default — weak).
- `caution` — the `caution` family (fair).
- `positive` — the `positive` family (strong).

There is **no `brand`/`info`** here — strength is a three-step good/bad scale, narrower than the full
Progress variant set.

## Composition

- **Composes:** [Progress](../Progress/Progress.prompt.md) — renders one `<Progress value={score}
  size="sm">` as the strength track, mapping `StrengthVariant` → `ProgressVariant`.
- **Composed by:** [AuthLayout](../../layout/AuthLayout/AuthLayout.prompt.md) — the sign-up screen shows
  it beneath the password [Input](../../inputs/Input/Input.prompt.md); it pairs with
  [Checklist](../../data-display/Checklist/Checklist.prompt.md) on the password flow. *(Sibling contracts
  authored across mx.2; links resolve at set completion.)*

## Examples

```tsx
// Fed by @mercury/effector's passwordStrength() (score + label + variant)
{password.value && <PasswordStrength score={strength.score} label={strength.label} variant={strength.variant} />}
// showcase/src/pages/patterns/AuthFlowPage.tsx
```

## Notes

- **Presentational** — it computes nothing; the `passwordStrength()` helper in `@mercury/effector`
  derives all three of `score` / `label` / `variant`. Don't infer strength inside the component.
- The label renders only when `label` is set; a bare `<PasswordStrength score={…} />` shows just the bar.
- The inner Progress is fixed at `size="sm"` — the meter height is not configurable.
- Status-family map: `negative → negative` · `caution → caution` · `positive → positive`.
