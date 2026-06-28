# Link — the inline text affordance

A brand-coloured inline affordance that renders an `<a>` when `href` is set and a `<button>` otherwise,
so one component covers both navigation and in-app actions ("Forgot password?", "Create an account",
"Back to sign in", "Resend code"). Presentational — the caller owns the navigation or the click. Import:
`import { Link } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `href` | `string` | — | When set (and not `disabled`), renders an `<a>`; otherwise a `<button>`. |
| `onClick` | `(e: MouseEvent) => void` | — | Click handler — fires in either anchor or button mode. |
| `disabled` | `boolean` | `false` | Non-interactive; forces button mode and applies `is-disabled`. |
| `size` | `"sm" \| "md"` | `"md"` | Text size (see the enum language). |
| `muted` | `boolean` | `false` | Tertiary colour instead of the brand colour. |
| `leading` | `ReactNode` | — | Content before the label (wrapped in `mx-link__icon`) — a glyph or an `<Icon />`. |
| `trailing` | `ReactNode` | — | Content after the label (wrapped in `mx-link__icon`). |
| `type` | `"button" \| "submit" \| "reset"` | `"button"` | Native button type — used only in button mode. |
| `target` | `string` | — | Anchor target — applied only when an `<a>` renders. |
| `rel` | `string` | — | Anchor rel — applied only when an `<a>` renders. |
| `className` | `string` | — | Extra classes merged onto the root. |
| `children` | `ReactNode` | — | The label — rendered in `mx-link__lbl` only when `!= null`. |
| `aria-label` | `string` | — | Accessible name; pass it for an icon-only link. |

Not a `forwardRef` / `…rest` component — the prop set above is the whole surface (no native-attr
pass-through beyond the listed anchor/button attributes).

## The enum language

- `size` → the text ramp: `md` is `mx-link--md` (14px), `sm` is `mx-link--sm` (13px). Pair `sm` with a
  matching small adjacent control (it is the size used throughout the auth footers).
- `muted` toggles the colour token: default is `--fg-brand`; `muted` (and the disabled state) resolve to
  `--fg-tertiary`. Focus shows the `--ring-focus` ring; hover underlines. Colour comes from tokens, never
  a raw value.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — in the `leading` / `trailing` slot
  (`mx-link__icon`); the slot takes any `ReactNode`, so a plain glyph span works too (the auth screens
  pass `<span aria-hidden>←</span>`).
- **Composed by:** [AuthLayout](../../layout/AuthLayout/AuthLayout.prompt.md) (the screen `footer` —
  "Create an account", "Back to sign in") and inline prose / form rows ("Forgot password?", "Resend
  code").

## Examples

```tsx
// Sizes
<Link href="#">Default link</Link>
<Link href="#" size="sm">Small link</Link>
// showcase/src/pages/components/LinkPage.tsx

// Muted + icon slots
<Link href="#" muted>Privacy policy</Link>
<Link leading={<span aria-hidden="true">←</span>}>Back to sign in</Link>
<Link trailing={<span aria-hidden="true">→</span>}>Continue</Link>
// showcase/src/pages/components/LinkPage.tsx

// As a button (no href) — an in-app action, disabled while cooling down
<Link size="sm" disabled={remaining > 0} onClick={() => resendCooldown.start(30)}>
  {remaining > 0 ? `Resend in ${remaining}s` : "Resend code"}
</Link>
// showcase/src/pages/patterns/AuthFlowPage.tsx

// In an AuthLayout footer
<Link size="sm">Forgot password?</Link>
// showcase/src/pages/patterns/AuthFlowPage.tsx
```

## Notes

- **Anchor vs button** is decided at render: `href` set and not `disabled` → `<a>` (with `target` /
  `rel`); otherwise a `<button type={type}>`. A disabled link is always a `<button disabled>`, never a
  dead `<a>` — so `disabled`/`onClick` work even with an `href` omitted.
- **`target` / `rel` apply only in anchor mode**; `type` applies only in button mode. Mixing them is
  harmless — the unused ones are dropped.
- **Icon-only link** — pass `aria-label`; an `Icon` in the slot is `aria-hidden`, so the accessible name
  must live on the link itself.
- The label span renders only when `children != null`, so a link can be slot-only (an arrow with no
  text).
