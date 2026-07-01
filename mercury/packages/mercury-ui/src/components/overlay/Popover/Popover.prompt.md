# Popover — the anchored, non-modal panel

A floating panel anchored to a trigger, holding arbitrary interactive content — a menu of actions, a
filter form, a detail card. Non-modal: it does not lock the page or trap focus; `Tab` may leave it.
Controlled or uncontrolled. Import: `import { Popover } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `trigger` | `ReactNode` | — (required) | The trigger's **content** — a label or icon, **not** an interactive element (Popover renders its own `<button>`; see Notes). |
| `children` | `ReactNode` | — | The panel content. |
| `open` | `boolean` | — | Controlled open state. Omit for uncontrolled. |
| `defaultOpen` | `boolean` | `false` | Initial open state when uncontrolled. |
| `onOpenChange` | `(open: boolean) => void` | — | Notified on every open/close (controlled and uncontrolled). |
| `placement` | `"bottom-start" \| "bottom-end" \| "top-start" \| "top-end"` | `"bottom-start"` | Where the panel anchors relative to the trigger. |
| `width` | `number` | `280` | Panel width (px). |

The surface is exactly these seven props — no `…rest`, no `forwardRef` (the component owns its trigger
and panel refs for the anchoring floor).

## The enum language

`placement` is a positional enum, not a token recipe — it feeds the floor's `useAnchoredPosition`
(`bottom`/`top` side × `start`/`end` cross-axis alignment). The panel is portaled and positioned
`position: fixed`, so it escapes any `overflow`/stacking context. The `.mx-popover` surface reads
`--bg-elevated` / `--border-secondary` / `--shadow-300` at radius `--radius-12`.

## Composition

- **Composes:** arbitrary `children` — commonly [Button](../../actions/Button/Button.prompt.md)s,
  [Link](../../actions/Link/Link.prompt.md)s, or an [Input](../../inputs/Input/Input.prompt.md).
- **Related:** [Tooltip](../Tooltip/Tooltip.prompt.md) (a hover hint, not interactive),
  [Dialog](../Dialog/Dialog.prompt.md) (modal, blocking). The floor Popover exercises
  (`useAnchoredPosition` + `useDismiss`) is the contract mx.7.5's menus compose.
- **Composed by:** net-new this rung — no app call site yet.

## Examples

```tsx
// Uncontrolled — a small action menu
<Popover trigger={<IconButton icon="cog" label="Settings" />}>
  <Button variant="ghost" fullWidth>Rename</Button>
  <Button variant="ghost" fullWidth>Duplicate</Button>
</Popover>
// (source-grounded; no app call site)

// Controlled + placement
<Popover open={open} onOpenChange={setOpen} placement="top-end" width={320}>
  {"Anchored above, aligned to the trigger's end edge."}
</Popover>
// (source-grounded; no app call site)
```

## Notes

- **Pass content, not a control, as `trigger`** — Popover wraps `trigger` in its own `<button
  aria-haspopup="dialog" aria-expanded>`, so nesting an interactive element (a `<button>`/`<a>`)
  inside is invalid HTML. Pass a label or an `Icon`.
- **Dismissal** — an outside press or `Escape` closes it; a press on the trigger is ignored by the
  dismiss floor (so the trigger's `onClick` toggles rather than close-then-reopen).
- **Focus (non-modal)** — focus moves into the panel on open and returns to the trigger on close, but
  it is **not** trapped: `Tab` may move focus out of the panel. Use `Dialog`/`AlertDialog` when you
  need a trap.
- **a11y** — the trigger is a real `<button>` with `aria-haspopup="dialog"` + `aria-expanded`; the
  panel is `role="dialog"` and `aria-controls`-linked while open.
- **React-19 nullable ref** — the anchoring/dismiss floor guards the trigger + panel refs (`null`
  while closed).
