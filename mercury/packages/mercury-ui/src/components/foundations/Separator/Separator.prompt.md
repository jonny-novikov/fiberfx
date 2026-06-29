# Separator — a dividing rule

A thin rule that divides content — horizontal or vertical, with an optional centered label. The
Claude-Design sibling of [Divider](../Divider/Divider.prompt.md), carrying a richer surface
(`orientation` · `label` · `size` · `decorative`). Reach for it to break a stack or a toolbar into
sections. Import: `import { Separator } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `orientation` | `"horizontal" \| "vertical"` (`SeparatorOrientation`) | `"horizontal"` | Rule direction (see the enum language). |
| `label` | `ReactNode` | — | Centered label (horizontal only) — turns the plain rule into a "— or —" splitter. |
| `size` | `number \| string` | — | Length: width for horizontal, height for vertical. A `number` is treated as px. Defaults to filling the container. |
| `decorative` | `boolean` | `true` | `true` → `role="none"` (purely visual); `false` → `role="separator"` + `aria-orientation` for AT. |
| `className` | `string` | — | Extra classes merged onto the root. |
| …rest | `HTMLAttributes<HTMLDivElement>` | — | Native attrs pass through; `aria-orientation`/`role` are managed by `decorative`. |

## The enum language

`orientation` selects the element recipe: `horizontal` is `.mx-separator` (a 1px rule, or the
`.mx-separator--label` flex row when `label` is set); `vertical` is `.mx-separator--v`, an inline 1px
rule that stretches to the row height. The rule color resolves to `--border-secondary`; a `label`
renders in the `--fg-tertiary` text token. A custom `size` rides the `--mx-sep-size` custom property, so
the length stays out of the color system. Tokens only — no raw values.

## Composition

- **Composes:** nothing — a leaf.
- **Sibling:** [Divider](../Divider/Divider.prompt.md) — the original rule primitive. Both stay
  exported; `Separator` adds the `decorative`/`size`/labelled-vertical surface under the Claude-Design
  name, while `Divider` keeps its `label`/`orientation` API. Pick `Separator` for the richer surface or
  the AT-meaningful `decorative={false}` rule.
- **Composed by:** menu groups, toolbars, and form sections that need a divider between groups.

## Examples

```tsx
// Plain rule + labelled splitter
<Separator />
<Separator label="or" />

// An AT-meaningful horizontal rule of a fixed width
<Separator decorative={false} size={240} />

// Vertical inline rule inside a toolbar row
<div style={{ display: "flex", alignItems: "center", gap: 12, height: 24 }}>
  <span>Edit</span>
  <Separator orientation="vertical" decorative={false} />
  <span>Delete</span>
</div>
```

## Notes

- **`decorative`** is the AT switch: leave it `true` (the default) for a purely visual rule; set it
  `false` when the rule genuinely separates groups, which emits `role="separator"` +
  `aria-orientation`.
- **Width** — a horizontal separator is `width: 100%` and fills its container unless `size` is set; a
  vertical one stretches to the row height (`align-self: stretch`).
- A `label` is horizontal-only; it is ignored for `orientation="vertical"`.
- (source-grounded; no app call site — a net-new mx.7.1 import.)
