# Divider — a separator rule

A thin separator rule; with a `label` it becomes the "— or —" splitter set between a primary and an
alternate action (email vs. SSO sign-in), and with `orientation="vertical"` it is an inline rule that
fills the height of its row. Reach for it to break a stack or a toolbar into sections. Import:
`import { Divider } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | `ReactNode` | — | Centred label; turns the plain rule into a horizontal splitter (rendered uppercase). |
| `orientation` | `"horizontal" \| "vertical"` | `"horizontal"` | Rule direction (see the enum language). |
| `className` | `string` | — | Extra classes merged onto the root. |

Not a `forwardRef` / `…rest` component — these three props are the whole surface. The rendered element
varies: vertical → a `<span role="separator">`; labelled → a `<div role="separator">` of two lines plus
the label; plain → an `<hr>`.

## The enum language

`orientation` selects the element and recipe: `horizontal` is the `mx-divider` rule (`<hr>`, or the
`mx-divider--label` flex row when `label` is set); `vertical` is `mx-divider--v`, an inline 1px rule that
stretches to the row height. The rule colour resolves to `--border-secondary`; a `label` renders in the
`--fg-tertiary` text token, uppercased and letter-spaced. Tokens only — no raw values.

## Composition

- **Composes:** nothing — a leaf.
- **Composed by:** [AuthLayout](../../layout/AuthLayout/AuthLayout.prompt.md) (the "or sign in with
  email" separator) and app forms (the labelled section breaks in the economy calibration panels).

## Examples

```tsx
// Plain + labelled splitter
<Divider />
<Divider label="or" />
<Divider label="or continue with email" />
// showcase/src/pages/components/DividerPage.tsx

// Vertical — inline, fills the row height
<Divider orientation="vertical" />
// showcase/src/pages/components/DividerPage.tsx

// The "or" between SSO and email sign-in
<Divider label="or sign in with email" />
// showcase/src/pages/patterns/AuthFlowPage.tsx

// Labelled section breaks in a calibration form
<Divider label="store fees" />
<Divider label="prize pool" />
// codemojex-node/apps/economy/src/components/CalibrationForm.tsx
```

## Notes

- Every variant carries `role="separator"`; the vertical rule also sets `aria-orientation="vertical"`.
- **Width** — a horizontal divider is `width: 100%`, so it fills its container; in a fixed-width demo the
  call sites wrap it in a full-width parent.
- The label is always uppercased and letter-spaced by the style — pass plain text (`"or"`), not a
  pre-styled node.
