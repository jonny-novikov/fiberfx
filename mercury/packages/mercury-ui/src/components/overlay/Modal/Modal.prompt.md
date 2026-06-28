# Modal — the portalled dialog

A centered dialog rendered into `document.body` over a click-to-dismiss backdrop, with an optional
title bar, a content slot, and a footer for actions. Reach for it for a confirm, an invite, or any
focused interruption. Import: `import { Modal } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `open` | `boolean` | — (required) | Mounts the dialog when `true`; renders `null` when `false`. |
| `onClose` | `() => void` | — | Fired by the backdrop click, the close `×`, and `Escape`. |
| `title` | `ReactNode` | — | Header text; when set, renders the head bar with the close `×`. |
| `footer` | `ReactNode` | — | Action row at the foot — usually `Button`s. |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Max-width ramp (see the enum language). |
| `children` | `ReactNode` | — | The dialog body. |

No `…rest`, no `forwardRef` — the surface is exactly these six props. The dialog is portalled, so it
escapes any overflow/transform ancestor.

## The enum language

`size` resolves to the `.mx-modal--<size>` max-width ramp (canon §6) — a dimensional scale, not a
status family:

- `sm` — 400px max-width; a tight confirm.
- `md` — the base width (no modifier class).
- `lg` — 720px max-width; a wider form.

The dialog surface itself uses `--bg-primary` / `--border-*` / `--shadow-*`; the backdrop is a scrim.

## Composition

- **Composes:** [Button](../../actions/Button/Button.prompt.md) in the `footer` actions; the `children`
  body holds arbitrary content — in the showcase, an [Input](../../inputs/Input/Input.prompt.md) +
  [Checkbox](../../selection/Checkbox/Checkbox.prompt.md).
- **Composed by:** app shells — the showcase `Shell` (`InviteModal` / `DangerModal`). *(An app call
  site, not a `@mercury/ui` component contract, so there is no sibling link.)*

## Examples

```tsx
// Invite dialog — title + footer Buttons + a form body
<Modal
  open={open}
  onClose={closeInvite}
  title="Invite teammates"
  footer={
    <>
      <Button variant="secondary" onClick={() => closeInvite()}>Cancel</Button>
      <Button onClick={() => { closeInvite(); toast.success("Invite sent"); }}>Send invite</Button>
    </>
  }
>
  <Input label="Emails" placeholder="ada@example.com, grace@example.com" value={emails} onChange={…} />
  <Checkbox checked={note} onChange={setNote} label="Send a personal note with the invite" />
</Modal>
// showcase/src/chrome/Shell.tsx

// Small confirm — size="sm", a destructive primary action
<Modal
  open={open}
  onClose={closeDanger}
  size="sm"
  title="Delete project?"
  footer={
    <>
      <Button variant="secondary" onClick={() => closeDanger()}>Cancel</Button>
      <Button variant="destructive" onClick={() => { closeDanger(); toast.error("Project deleted"); }}>
        Delete permanently
      </Button>
    </>
  }
>
  This will permanently delete <strong>Mercury Marketing</strong> and all of its data.
</Modal>
// showcase/src/chrome/Shell.tsx
```

## Notes

- **Dismissal** — backdrop click, the close `×`, and `Escape` all call `onClose`; a click inside the
  dialog stops propagation so it does not dismiss. The `Escape` listener is attached only while `open`.
- **a11y** — `role="dialog"` + `aria-modal="true"`; the close button is `aria-label="Close"`. Note the
  component does **not** implement a focus trap or return-focus — manage focus yourself if you need it,
  and provide a `title` (there is no automatic `aria-labelledby` wiring beyond the visible heading).
- **SSR-safe** — renders `null` when `!open` or when `document` is undefined; otherwise portals into
  `document.body`.
- **Title gates the head** — with no `title` there is no header bar and no `×`, so an action-only modal
  must dismiss via the backdrop, `Escape`, or a footer button.
