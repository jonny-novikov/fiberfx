# LinkPreview — the URL-preview card

The URL-preview specialization of the hover-card family: a non-modal card revealed on hover **or** focus
of an inline link, previewing where the link leads (a title, a description, the destination host).
Composes the overlay-floor's `useAnchoredPosition` (portaled `position: fixed`). Import: `import {
LinkPreview } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | `ReactNode` | — (required) | The anchor — typically a [Link](../../actions/Link/Link.prompt.md). Must be focusable so keyboard focus opens the preview. |
| `content` | `ReactNode` | — (required) | The preview body (a URL card, an embed, a summary). |
| `placement` | `LinkPreviewPlacement` (`"top" \| "bottom"`) | `"bottom"` | Which side the preview anchors to — above/below the link only. |
| `openDelay` | `number` | `300` | Delay before opening on hover/focus (ms). |
| `width` | `number` | `300` | Preview width (px). |

No `…rest`, no `forwardRef`. **There is no `closeDelay` prop** — the preview hides on a fixed 120ms grace
(enough for the pointer to bridge the anchor→card gap).

## The enum language

`placement` is a positional enum restricted to the vertical sides (`top`/`bottom`) — a link preview
tracks the reading line, not the horizontal margins — feeding `useAnchoredPosition`. The `.mx-linkpreview`
surface shares the hover-card recipe (`--bg-elevated` / `--border-secondary` / `--shadow-300` /
`--radius-12`) and keeps its own selector so a consumer can target the preview variant. No
`accent`/`variant`.

## Composition

- **Composes:** an inline [Link](../../actions/Link/Link.prompt.md) (or any focusable inline anchor) plus
  arbitrary `content`.
- **Related:** [HoverCard](../HoverCard/HoverCard.prompt.md) — the general hover/focus card (four
  placements, a `closeDelay`); [Tooltip](../Tooltip/Tooltip.prompt.md) — a static label. LinkPreview is
  HoverCard narrowed to the link-preview case.
- **Composed by:** net-new this rung — no app call site yet.

## Examples

```tsx
// Preview a link's destination
<LinkPreview content="Mercury — a token-driven React design system.">
  <Link href="https://mercury.jonnify.com">the design system</Link>
</LinkPreview>
// (source-grounded; no app call site)

// Above the link, wider
<LinkPreview placement="top" width={360} content="Docs · getting started, tokens, components.">
  <Link href="/docs">Docs</Link>
</LinkPreview>
// (source-grounded; no app call site)
```

## Notes

- **No `closeDelay`** — the preview hides on a fixed 120ms after leave/blur; moving the pointer onto the
  card within that grace keeps it open (the card carries its own hover handlers).
- **Focus opens it** — `onFocus`/`onBlur` on the anchor open/close the preview, so a keyboard path
  exists; the invariant holds only when `children` is focusable (a link).
- **Non-modal, portaled** — no focus trap, no outside-press/`Escape` dismiss; the card mounts at
  `document.body` (`position: fixed`) and recomputes on scroll/resize while open.
- **a11y** — the card is `role="dialog"`.
- **React-19 nullable refs** — the open/close timer refs are guarded before every `clearTimeout` and
  cleared on unmount.
