# Tooltip — the hover label wrapper

A CSS-driven tooltip that wraps a trigger element and reveals a small label on hover/focus. Reach for it
to caption an icon button or a terse control. Import: `import { Tooltip } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `content` | `ReactNode` | — (required) | The tooltip label shown on hover. |
| `children` | `ReactNode` | — (required) | The trigger element the tooltip wraps. |

No `…rest`, no `forwardRef` — the surface is exactly these two props. The component renders a
`.mx-tooltip-wrap` span around `children` with the `.mx-tooltip` label beside it.

## The enum language

No enum props — there are no `variant`/`size`/`tone` controls. The bubble styles from the surface
tokens (`--bg-*`, `--fg-*`) of the `.mx-tooltip` recipe; visibility is pure CSS off the wrapper's
hover/focus state.

## Composition

- **Composes:** the `children` trigger — in the showcase, a
  [Button](../../actions/Button/Button.prompt.md). Any focusable control works.
- **Composed by:** app pages — the showcase `ModalPage` ("Tooltip (bonus)" section). *(An app call site,
  not a `@mercury/ui` component contract, so there is no sibling link.)*

## Examples

```tsx
// Caption a secondary action
<Tooltip content="Copy link to clipboard">
  <Button variant="secondary">Share</Button>
</Tooltip>

// Caption a ghost action
<Tooltip content="You've got mail">
  <Button variant="ghost">Inbox</Button>
</Tooltip>
// showcase/src/pages/components/ModalPage.tsx
```

## Notes

- **CSS-only reveal** — there is no controlled `open` prop, no portal, and no positioning logic; the
  label is a sibling span shown on the wrapper's `:hover`/`:focus-within`. It can clip inside an
  `overflow: hidden` ancestor (unlike `Modal`, which portals out).
- **a11y** — the label carries `role="tooltip"`; it is not wired via `aria-describedby`, so for an
  icon-only trigger also give the control its own accessible name (`aria-label`).
- **Inline wrapper** — `.mx-tooltip-wrap` is a `<span>`, so the trigger sits inline; wrap a single
  control, not block layout.
