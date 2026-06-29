# IconButton — an icon-only action

A square or round button carrying only an icon — toolbar actions, an overlay close, a row action. It
reuses [Button](../Button/Button.prompt.md)'s variant/size token language and adds a square-box
geometry; it is fully round by default. The required `label` becomes the accessible name. Import:
`import { IconButton } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `icon` | `IconName` | — | The glyph name, from the [Icon](../../foundations/Icon/Icon.prompt.md) set. |
| `label` | `string` | — | **Required** accessible name (there is no visible text). Becomes `aria-label` + `title`. |
| `variant` | `"primary" \| "secondary" \| "outline" \| "ghost" \| "destructive"` (`IconButtonVariant`) | `"secondary"` | Fill + ink — the shared `.mx-btn--<variant>` recipe. |
| `size` | `"sm" \| "md" \| "lg"` (`IconButtonSize`) | `"md"` | Box 32 / 40 / 48px; glyph 16 / 18 / 20px. |
| `shape` | `"circle" \| "square"` (`IconButtonShape`) | `"circle"` | `circle` → `--radius-full`; `square` → `--radius-8` (`--radius-6` at `sm`). |
| `type` | `"button" \| "submit" \| "reset"` | `"button"` | Native button type. |
| `disabled` | `boolean` | — | Native; dims + `not-allowed`. |
| …rest | `ButtonHTMLAttributes` | — | `onClick`, `name`, `aria-*`, `className` pass through (`forwardRef` to the `<button>`). |

## The enum language

`variant` reuses `.mx-btn--<variant>` — the **same** fill/ink token recipe as [Button](../Button/Button.prompt.md):
`primary` (brand fill), `secondary` (subtle surface), `outline` (bordered), `ghost` (text-only),
`destructive` (the negative status family). It carries no `inverse` variant (that is Button's). `size`
sets the square box + glyph px; `shape` sets the radius (`--radius-full` for round). Tokens only.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — the single glyph, sized to the control.
- **Shares tokens with:** [Button](../Button/Button.prompt.md) — the `.mx-btn--<variant>` fill/ink
  surface; an `IconButton` sits beside a text `Button` with matching weight.
- **Composed by:** overlay close affordances, toolbars, and table/list row actions.

## Examples

```tsx
// A round ghost close button (icon-only — label is the accessible name)
<IconButton icon="close" label="Close" variant="ghost" />

// A primary round action and a destructive one
<IconButton icon="plus" label="Add item" variant="primary" />
<IconButton icon="trash" label="Delete" variant="destructive" />

// A square, small, outline button in a dense toolbar
<IconButton icon="search" label="Search" variant="outline" shape="square" size="sm" />
```

## Notes

- **Accessibility** — `label` is required and becomes `aria-label` + `title`; an icon-only control
  needs an accessible name (canon §8). It is the single source — passing `aria-label` in `…rest` does
  not override it.
- It shares Button's tokens but is **not** a Button: no `loading`, `leading`/`trailing`, `fullWidth`,
  or `inverse` — for a labelled action use [Button](../Button/Button.prompt.md).
- The glyph px is derived from `size` (16 / 18 / 20) — pass only `icon`, not an `Icon` element.
- (source-grounded; no app call site — a net-new mx.7.1 import.)
