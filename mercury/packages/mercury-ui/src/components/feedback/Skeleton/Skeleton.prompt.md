# Skeleton — a pulsing content placeholder

A muted, pulsing block that holds the shape of content while it loads, reducing layout shift on
arrival. Reach for it to mirror the geometry of incoming text, media, or an avatar; reach for
`Spinner` for a busy spot with no shape. Import: `import { Skeleton } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `width` | `number \| string` | `"100%"` | Number → px; string → any CSS length. Also the diameter when `circle`. |
| `height` | `number \| string` | `16` | Number → px; string → any CSS length. Ignored when `circle`. |
| `radius` | `number` | `6` | Corner radius in px. Ignored when `circle`. |
| `circle` | `boolean` | — | Render a circle of diameter `width` (for avatars). |
| …rest | `HTMLAttributes<HTMLSpanElement>` | — | `id`, `className`, `style`, … pass through to the root `<span aria-hidden>`. |

## The enum language

No enum props — the shape is given by the dimension props (`width`/`height`/`radius`/`circle`) as
non-color inline styles. The surface token (`--bg-tertiary`) and the 1.5s pulse animation live in the
`.mx-skeleton` class.

## Composition

- **Composes:** nothing — a leaf placeholder.
- **Pairs with:** [Spinner](../Spinner/Spinner.prompt.md) — Skeleton holds layout for content with a
  known shape; Spinner marks an indeterminate busy spot. Compose several Skeletons to mirror a card or
  list row while it loads.

## Examples

```tsx
<Skeleton width={240} />

<Skeleton circle width={40} />

<div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
  <Skeleton width="60%" height={20} />
  <Skeleton />
  <Skeleton width="80%" />
</div>
```

## Notes

- `aria-hidden` — a placeholder carries no content, so it is hidden from assistive tech; announce the
  load with a sibling `Spinner` or a live region.
- Honours `prefers-reduced-motion`: the pulse is dropped to a steady muted block.
- (source-grounded; no app call site — a net-new mx.7.2 import.)
