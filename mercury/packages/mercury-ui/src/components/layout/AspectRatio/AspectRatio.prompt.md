# AspectRatio — a fixed width-to-height ratio box

Constrains its content to a fixed ratio (media embeds, image frames, video, map tiles). The box fills
its container's width and derives its height from `ratio`. Import:
`import { AspectRatio } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `ratio` | `number` | `16 / 9` | width / height (`16/9`, `1`, `4/3`, …). |
| `children` | `ReactNode` | — | The content; it fills the box absolutely (`inset: 0`). |
| …rest | `HTMLAttributes<HTMLDivElement>` | — | `id`, `className`, `style`, `aria-*`, … pass through to the root `<div>`. |

## The enum language

No enum props. `ratio` is a free numeric value applied to the CSS `aspect-ratio` property as a non-color
dynamic inline style; the wrapper structure (`position`, `overflow: hidden`, the absolute inner) lives in
`.mx-aspect`.

## Composition

- **Composes:** nothing — a layout wrapper; the child is any content.
- **Wraps:** media (`<img>`, `<video>`, `<iframe>`) and placeholders such as
  [Skeleton](../../feedback/Skeleton/Skeleton.prompt.md); pairs with
  [Avatar](../../data-display/Avatar/Avatar.prompt.md) for square (`ratio={1}`) image frames.

## Examples

```tsx
<AspectRatio ratio={16 / 9}>
  <img src={cover} alt="" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
</AspectRatio>

<AspectRatio ratio={1}>
  <Skeleton width="100%" height="100%" radius={0} />
</AspectRatio>
```

## Notes

- The child is absolutely positioned to fill the box; give an `<img>`/`<video>` `objectFit: "cover"` to
  crop without distortion. Overflow is clipped.
- (source-grounded; no app call site — a net-new mx.7.2 import.)
