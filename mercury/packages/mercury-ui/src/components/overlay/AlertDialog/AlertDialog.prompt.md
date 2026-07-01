# AlertDialog — the blocking confirmation

A blocking confirmation that demands an explicit choice: a title, a prompt, and a cancel/confirm
action pair. Unlike [Dialog](../Dialog/Dialog.prompt.md), a backdrop press does **not** dismiss — the
operator must pick. Reach for it before an irreversible action (delete, discard, sign out). Import:
`import { AlertDialog } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `open` | `boolean` | — (required) | Mounts + portals the confirmation when `true`; renders `null` when `false`. |
| `title` | `ReactNode` | — | The heading (a `Heading`); wires `aria-labelledby`. |
| `description` | `ReactNode` | — | The prompt; wires `aria-describedby`. |
| `children` | `ReactNode` | — | Extra content between the description and the actions. |
| `confirmLabel` | `string` | `"Confirm"` | The confirm action label. |
| `cancelLabel` | `string` | `"Cancel"` | The cancel action label. |
| `destructive` | `boolean` | — | Styles the confirm action as `Button variant="destructive"`. |
| `onConfirm` | `() => void` | — | Invoked when the confirm action is pressed. |
| `onCancel` | `() => void` | — | Invoked on cancel, `Escape`, or the cancel action. |
| …rest | `HTMLAttributes<HTMLDivElement>` | — | `id`, `data-*`, `aria-*`, `className` pass through to the panel (`forwardRef` to the panel `<div>`). `title` is excluded (it is the `ReactNode` heading above). |

## The enum language

There is no size ramp — the confirmation is a fixed 420px card. The one visual switch is `destructive`:

- `destructive` **unset** → the confirm action is `Button variant="primary"` (brand).
- `destructive` **set** → the confirm action is `Button variant="destructive"` (the `negative` status
  family) — for delete/remove.

The panel reuses the `.mx-modal` surface at radius `--radius-16`; the backdrop is a `--bg-backdrop`
scrim.

## Composition

- **Composes:** [Heading](../../foundations/Heading/Heading.prompt.md) (the `title`) and two
  [Button](../../actions/Button/Button.prompt.md)s (`secondary` cancel + `primary`/`destructive`
  confirm).
- **Related:** [Dialog](../Dialog/Dialog.prompt.md) (the open-ended sibling — arbitrary body,
  backdrop-dismissable), [Modal](../Modal/Modal.prompt.md).
- **Composed by:** net-new this rung — no app call site yet.

## Examples

```tsx
// A destructive confirmation
<AlertDialog
  open={open}
  title="Delete project?"
  description="This permanently deletes the project and all of its data."
  confirmLabel="Delete permanently"
  destructive
  onConfirm={remove}
  onCancel={close}
/>
// (source-grounded; no app call site)

// A neutral confirm with extra content
<AlertDialog open={open} title="Sign out?" onConfirm={signOut} onCancel={close}>
  <Checkbox checked={all} onChange={setAll} label="Sign out of all devices" />
</AlertDialog>
// (source-grounded; no app call site)
```

## Notes

- **Dismissal is deliberate** — a backdrop press does **not** dismiss (the floor's `useDismiss` is
  passed `outsideClick: false`); only `Escape` or the cancel action calls `onCancel`. This is the
  contract difference from `Dialog`.
- **a11y** — `role="alertdialog"` + `aria-modal="true"`; `title`/`description` wired to
  `aria-labelledby`/`aria-describedby`. Focus is **trapped** and lands on the **confirm** action on
  open (via the floor's `initialFocus`), returning to the trigger on close.
- **React-19 nullable ref** — the floor hooks guard `ref.current`; the confirm ref is forwarded
  straight to the `Button` (which itself forwards to its `<button>`).
- **SSR-safe** — portals into `document.body` via `<Portal>`; renders `null` when `!open` or when
  `document` is undefined.
