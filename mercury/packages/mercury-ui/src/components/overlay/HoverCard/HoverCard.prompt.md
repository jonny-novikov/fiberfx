# HoverCard — the hover/focus preview card

A non-modal card revealed on hover **or** focus of its anchor — a profile peek, a definition, a rich
preview. Composes the overlay-floor's `useAnchoredPosition` (portaled `position: fixed`, so it escapes
any `overflow`/stacking context) with local open/close timers. Distinct from `Tooltip` (a static,
CSS-only label) and `Popover` (click-triggered, dismiss-managed). Import: `import { HoverCard } from
"@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | `ReactNode` | — (required) | The anchor. Must be **focusable** (a `Link`/`Avatar`/`button`) so keyboard focus — not only hover — opens the card. |
| `content` | `ReactNode` | — (required) | The floating card body. |
| `placement` | `HoverCardPlacement` (`"top" \| "bottom" \| "left" \| "right"`) | `"bottom"` | Which side the card anchors to. |
| `openDelay` | `number` | `250` | Delay before opening on hover/focus (ms). |
| `closeDelay` | `number` | `150` | Delay before closing on leave/blur (ms). |
| `width` | `number` | `280` | Card width (px). |

No `…rest`, no `forwardRef` — the component owns the anchor + card refs for the positioning floor.

## The enum language

`placement` is a positional enum (a bare side), feeding the floor's `useAnchoredPosition`; it is not a
token recipe. The `.mx-hovercard` surface reads `--bg-elevated` / `--border-secondary` / `--shadow-300`
at `--radius-12` (the shared hover-card recipe). There is no `accent`/`variant` — the card is a neutral
surface holding arbitrary `content`.

## Composition

- **Composes:** a focusable `children` anchor — commonly a
  [Link](../../actions/Link/Link.prompt.md) — plus arbitrary `content`.
- **Related:** [Tooltip](../Tooltip/Tooltip.prompt.md) — a static, CSS-only label (interactive card vs
  static hint); [Popover](../Popover/Popover.prompt.md) — click-triggered and dismiss-managed;
  [LinkPreview](../LinkPreview/LinkPreview.prompt.md) — the URL-preview specialization of the same card.
- **Composed by:** net-new this rung — no app call site yet.

## Examples

```tsx
// A profile peek on a link
<HoverCard content="Jane Doe · Product design · San Francisco">
  <Link href="/users/jane">@jane</Link>
</HoverCard>
// (source-grounded; no app call site)

// Left-anchored, snappier open
<HoverCard placement="left" openDelay={120} width={320} content="Quick preview.">
  <Link href="/docs">Docs</Link>
</HoverCard>
// (source-grounded; no app call site)
```

## Notes

- **Focus opens it, not only hover** — `onFocus`/`onBlur` on the anchor span open/close the card, so a
  keyboard path exists. The invariant holds only when `children` is focusable: wrap a control, not inert
  text.
- **Non-modal** — no focus trap, no outside-press/`Escape` dismiss floor, no page lock (contrast
  `Dialog`). The card closes on leave/blur after `closeDelay`; moving the pointer onto the card keeps it
  open (the card carries its own hover handlers, bridging the anchor→card gap).
- **Portaled** — the card mounts at `document.body` (`position: fixed`), escaping `overflow: hidden` /
  stacking ancestors; positioning recomputes on scroll/resize while open.
- **a11y** — the card is `role="dialog"`. Give `content` a heading or accessible label when substantive.
- **React-19 nullable ref** — the open/close timer ref is guarded before every `clearTimeout` and
  cleared on unmount.
