# Dialog — the blocking dialog with a description slot

A focused, blocking surface: a divider header with a title and a supporting description, a body, and a
footer for actions. A richer [Modal](../Modal/Modal.prompt.md) — it adds the `description` slot, a
`showClose` control, and a hardened a11y floor (focus trap + return, `aria-labelledby`/
`aria-describedby`). Reach for it for a form, an invite, or any focused interruption that needs a
heading and a description. Import: `import { Dialog } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `open` | `boolean` | — (required) | Mounts + portals the dialog when `true`; renders `null` when `false`. |
| `onClose` | `() => void` | — | Fired by the backdrop press, the close control, and `Escape`. |
| `title` | `ReactNode` | — | The heading (a `Heading`); when set, wires `aria-labelledby`. |
| `description` | `ReactNode` | — | A supporting line under the title; when set, wires `aria-describedby`. |
| `children` | `ReactNode` | — | The dialog body. |
| `footer` | `ReactNode` | — | Trailing action row — usually `Button`s. |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Max-width ramp (see the enum language). |
| `showClose` | `boolean` | `true` | Render the corner close control (an `IconButton`). |
| …rest | `HTMLAttributes<HTMLDivElement>` | — | `id`, `data-*`, `aria-*`, `className` pass through to the panel (`forwardRef` to the panel `<div>`). `title` is excluded (it is the `ReactNode` heading above). |

## The enum language

`size` resolves to the `.mx-dialog--<size>` max-width ramp (canon §6) — a dimensional scale, not a
status family:

- `sm` — 420px; a tight confirm.
- `md` — 496px (the base width, no modifier class).
- `lg` — 640px; a wider form.

The panel reuses the `.mx-modal` surface (`--bg-elevated` / `--border-secondary` / `--shadow-500`) at
radius `--radius-20`; the backdrop is a `--bg-backdrop` scrim.

## Composition

- **Composes:** [Heading](../../foundations/Heading/Heading.prompt.md) (the `title`),
  [IconButton](../../actions/IconButton/IconButton.prompt.md) (the `showClose` control,
  `icon="close"` / `label="Close"`), and [Button](../../actions/Button/Button.prompt.md)s in the
  `footer`.
- **Related:** [Modal](../Modal/Modal.prompt.md) (the leaner sibling — no description slot, no focus
  trap), [AlertDialog](../AlertDialog/AlertDialog.prompt.md) (a fixed confirm/cancel shape).
- **Composed by:** net-new this rung — no app call site yet.

## Examples

```tsx
// Invite dialog — title + description + footer Buttons + a form body
<Dialog
  open={open}
  onClose={close}
  title="Invite teammates"
  description="They will receive an email with a link to join the workspace."
  footer={
    <>
      <Button variant="secondary" onClick={close}>Cancel</Button>
      <Button onClick={submit}>Send invite</Button>
    </>
  }
>
  <Input label="Emails" placeholder="ada@example.com" value={emails} onChange={setEmails} />
</Dialog>
// (source-grounded; no app call site)

// A tight confirm — size="sm", no close control
<Dialog open={open} onClose={close} size="sm" showClose={false} title="Discard changes?"
  footer={<Button variant="destructive" onClick={discard}>Discard</Button>}>
  Your edits will be lost.
</Dialog>
// (source-grounded; no app call site)
```

## Notes

- **Dismissal** — a backdrop press, the close control, and `Escape` all call `onClose`; a press inside
  the panel does not dismiss (the floor's `useDismiss` reads the panel subtree + box). The listeners
  are attached only while `open`.
- **a11y** — `role="dialog"` + `aria-modal="true"`; `title`/`description` are wired to
  `aria-labelledby`/`aria-describedby` via stable ids. Focus is **trapped** while open (Tab wraps
  last→first) and **returns** to the trigger on close — the hardening `Modal` does not carry. The
  panel is `tabIndex={-1}` so focus has a fallback target when the body has no focusable descendant.
- **React-19 nullable ref** — the floor hooks guard `ref.current` (the panel is `null` while closed);
  the merged panel ref is populated by a callback ref.
- **SSR-safe** — portals into `document.body` via `<Portal>`; renders `null` when `!open` or when
  `document` is undefined.
- **Header gates the divider** — with no `title` and no `description` there is no header block and no
  divider; the body keeps its top padding. `showClose` is independent (absolutely placed).
