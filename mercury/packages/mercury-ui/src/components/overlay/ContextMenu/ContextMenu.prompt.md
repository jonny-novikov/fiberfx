# ContextMenu — the pointer-anchored menu

A menu opened by a right-click on the wrapped region, anchored at the pointer. Non-modal. Import:
`import { ContextMenu } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | `ReactNode` | — (required) | The right-click surface — the wrapped region opens the menu at the pointer. |
| `items` | `ContextMenuItem[]` | — (required) | The menu rows, in order (see the item shape below). |
| `width` | `number` | `220` | Panel width (px). |

`ContextMenuItem`: `{ type?: "item" | "label" | "separator"; label?: ReactNode; icon?: IconName;
shortcut?: string; onSelect?: () => void; disabled?: boolean; danger?: boolean }`. A plain `item` runs
`onSelect` and closes; `label`/`separator` are presentational; `danger` recolours the row to the
negative family. The surface is exactly these three props — no `…rest`, no `forwardRef` (the component
owns its wrapper + panel refs for the anchoring floor).

## The enum language

There is **no accent prop** — `danger` is the sole recolour, and it is token-based: `.mx-ctx__item--danger`
reads `--fg-negative` (ink) + `--bg-negative-subtle` (hover), so it themes light/dark through the token
flip. The panel opens at the pointer via the floor's `useAnchoredPosition({ point })`, which clamps to
the viewport (no manual edge math). The panel is portaled + `position: fixed`, escaping any
`overflow`/stacking context; the `.mx-ctx` surface reads `--bg-elevated` / `--border-secondary` /
`--shadow-300` at radius `--radius-12`.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) (a row's leading glyph); wraps arbitrary
  `children` as the right-click surface.
- **Related:** [Separator](../../foundations/Separator/Separator.prompt.md) (the visual model for a
  `separator` row), [Dropdown](../Dropdown/Dropdown.prompt.md) (the trigger-anchored sibling — a
  button opens it rather than a right-click), [Popover](../Popover/Popover.prompt.md).
- **Composed by:** net-new this rung — no app call site yet.

## Examples

```tsx
// A right-click menu over a file row — a destructive last action
<ContextMenu
  items={[
    { type: "label", label: "Edit" },
    { type: "item", label: "Copy", icon: "copy", shortcut: "⌘C", onSelect: copy },
    { type: "item", label: "Download", icon: "download", onSelect: download },
    { type: "separator" },
    { type: "item", label: "Delete", icon: "trash", danger: true, onSelect: remove },
  ]}
>
  <FileRow name="report.pdf" />
</ContextMenu>
// (source-grounded; no app call site)
```

## Notes

- **The wrapped region is the surface** — the `children` are rendered inside a wrapper that intercepts
  `contextmenu` (preventing the browser default) and opens the panel at `{ clientX, clientY }`.
- **Dismissal** — an outside press or `Escape` closes it (the dismiss floor); additionally, a local
  `scroll` listener dismisses while open, so a scrolled page never leaves a menu pinned to a stale
  point.
- **Keyboard** — the panel takes focus on open; `ArrowUp`/`ArrowDown` move between rows, skipping
  `disabled` rows; `Escape` closes.
- **a11y** — the panel is `role="menu"`, rows are `role="menuitem"`. A `disabled` row carries
  `aria-disabled` and is excluded from arrow-nav.
- **React-19 nullable ref** — the anchoring/dismiss floor guards the wrapper + panel refs (`null`
  while closed).
