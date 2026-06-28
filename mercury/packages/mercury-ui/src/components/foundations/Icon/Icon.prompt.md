# Icon — the inline outline-icon set

A single-element SVG from a fixed, curated icon set — outline style, 24px grid, `currentColor` stroke
(so it inherits the surrounding text color). Reach for it inside buttons, inputs, list rows, and
status affordances. Import: `import { Icon } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | `IconName` | — (required) | One of the fixed set (below). Typed — an unknown name is a compile error. |
| `size` | `number` | `16` | Square px (sets `width` + `height`). 14 inside `sm`/`md` buttons; 20 in nav. |
| `strokeWidth` | `number` | `2` | Stroke weight (the set is drawn at 1.5–2px). |
| …rest | `SVGProps<SVGSVGElement>` | — | `className`, `style`, `onClick`, `aria-*` pass through to the `<svg>`. |

**`IconName` (the set):** `arrow` · `arrow-up-right` · `arrow-down-left` · `check` · `close` · `plus` ·
`minus` · `search` · `star` · `bell` · `cog` · `user` · `users` · `home` · `list` · `mail` · `wallet` ·
`credit-card` · `shield` · `globe` · `help-circle` · `chevron-right` · `chevron-down` · `alert` ·
`info` · `download` · `upload` · `trash` · `refresh` · `copy` · `pause` · `play` · `repeat` ·
`trending-up` · `bank` · `bolt` · `flow` · `batch`.

## The enum language

No variants — color comes from context (`currentColor`), so an `Icon` takes the `--fg-*` token of its
parent. To recolor, set the parent's text color (`style={{ color: "rgb(var(--fg-brand))" }}`) rather
than styling the icon.

## Composition

- **Composes:** nothing — a leaf.
- **Composed by:** [Button](../../actions/Button/Button.prompt.md) (`leading`/`trailing`),
  [Input](../../inputs/Input/Input.prompt.md) + [Search](../../inputs/Search/Search.prompt.md)
  (adornments), [Link](../../actions/Link/Link.prompt.md) (inline). *(Some sibling contracts authored
  across mx.2; the Button link resolves now.)*

## Examples

```tsx
// Standalone — nav + chrome
<Icon name="bolt" size={20} />            // showcase/src/chrome/Sidebar.tsx
<Icon name="star" size={14} />            // showcase/src/chrome/Topbar.tsx

// Inside a Button slot
<Button leading={<Icon name="download" size={14} />}>Download</Button>
// showcase/src/pages/components/ButtonPage.tsx

// As an input adornment
<Input leading={<Icon name="mail" size={14} />} type="email" label="Email" />
// showcase/src/pages/patterns/SignInPage.tsx
```

## Notes

- Renders `aria-hidden="true"` — an `Icon` is decorative. When it is the only content of a control
  (an icon-only button/link), put the accessible name on the **control** (`aria-label`), not the icon.
- `flex-shrink: 0` + `display: block` are baked in, so it never squashes in a flex row.
- The set is fixed in `Icon.tsx`; adding a glyph is a source change (a new `ICONS` entry + the
  `IconName` union grows automatically).
