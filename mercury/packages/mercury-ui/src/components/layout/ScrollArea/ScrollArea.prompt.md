# ScrollArea — a scroll container with custom scrollbars

A bounded scroll region with Mercury's thin, rounded scrollbars. Reach for it for a long list, a wide
table, or a code block that should scroll within a fixed box. Import:
`import { ScrollArea } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `scrollbars` | `"vertical" \| "horizontal" \| "both"` (`ScrollAreaScrollbars`) | `"vertical"` | Which axes scroll. |
| `size` | `"sm" \| "md" \| "lg"` (`ScrollAreaSize`) | `"md"` | Scrollbar thickness (8/10/12px). |
| `maxHeight` | `number \| string` | — | Cap height — required for `vertical`/`both` to actually scroll (number → px). |
| `width` | `number \| string` | — | Container width (number → px). |
| `children` | `ReactNode` | — | The scrolled content. |
| …rest | `HTMLAttributes<HTMLDivElement>` | — | `id`, `className`, `style`, `aria-*`, … pass through to the root `<div>`. |

## The enum language

- `scrollbars` resolves to `.mx-scrollarea--<scrollbars>` → the overflow axes (`vertical` =
  `overflow-y: auto`; `horizontal` = `overflow-x: auto`; `both` = `overflow: auto`).
- `size` resolves to `.mx-scrollarea--<size>` → the webkit scrollbar width/height. The thumb is
  `--border-primary` (→ `--border-strong` on hover) on a transparent track; the Firefox `scrollbar-color`
  reads the same neutral border tokens.

## Composition

- **Composes:** nothing — a layout wrapper around any content.
- **Wraps:** long lists and [Table](../../data-display/Table/Table.prompt.md) — give a wide Table a
  `scrollbars="horizontal"` ScrollArea, or a tall list a `vertical` one with a `maxHeight`.

## Examples

```tsx
<ScrollArea maxHeight={240}>
  <LongList />
</ScrollArea>

<ScrollArea scrollbars="horizontal" width={400}>
  <WideTable />
</ScrollArea>
```

## Notes

- `vertical`/`both` only scroll once a `maxHeight` bounds the box; `horizontal` needs content wider than
  `width` (or the container).
- The custom scrollbar is a webkit pseudo-element cosmetic with a Firefox `scrollbar-width: thin`
  fallback; it degrades to the native scrollbar elsewhere. No runtime style injection — the rules ship in
  the stylesheet.
- (source-grounded; no app call site — a net-new mx.7.2 import.)
