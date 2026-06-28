# Alert — an inline status banner

A tone-colored message block with a glyph, an optional title, body content, an optional actions row, and
an optional dismiss button. Reach for it for an inline notice on a page or panel — a warning, a success
confirmation, a danger condition. Import: `import { Alert } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `tone` | `AlertTone` | `"info"` | Color + glyph + ARIA role (see the enum language). |
| `title` | `ReactNode` | — | Bold heading line (`<h4>`). |
| `children` | `ReactNode` | — | The message body. |
| `dismissible` | `boolean` | — | Renders a `×` dismiss button (top-right). |
| `onDismiss` | `() => void` | — | Called when the dismiss button is clicked. |
| `actions` | `ReactNode` | — | An actions row under the message (usually `Button`s). |

`AlertTone` = `"info" \| "success" \| "warning" \| "danger"`.

The component takes **no `…rest`** and is **not** `forwardRef`.

## The enum language

`tone` resolves to a `.mx-alt--<tone>` recipe over the **status families** (canon §6) — note Alert's
tone names are semantic and map onto the canonical families:

- `info` → the `info` family; glyph `i`; `role="status"`.
- `success` → the `positive` family; glyph `✓`; `role="status"`.
- `warning` → the `caution` family; glyph `!`; `role="status"`.
- `danger` → the `negative` family; glyph `×`; **`role="alert"`** (assertive — announced immediately).

## Composition

- **Composes:** [Button](../../actions/Button/Button.prompt.md) — in the optional `actions` slot (a
  `ReactNode`); `title`/`children` are open slots too. With no actions it composes nothing.
- **Composed by:** [Table](../../data-display/Table/Table.prompt.md) — the margin panel renders an Alert
  beneath its Table as a derived warning; it sits inside [Card](../../data-display/Card/Card.prompt.md)
  panels. *(Sibling contracts authored across mx.2; links resolve at set completion.)*

## Examples

```tsx
// Derived from the table's data — tone + title switch on a computed condition
<Alert tone={anyNeg ? "danger" : "warning"} title={anyNeg ? "Pool liability exceeds net revenue" : "Store-fee margin squeeze"}>
  {anyNeg ? "The pool owed outruns net revenue on at least one channel…" : "Mobile keeps less of each guess than desktop…"}
</Alert>
// codemojex-node/apps/economy/src/components/MarginTable.tsx

// The four tones, title + body
<Alert tone="info" title="Scheduled maintenance">…</Alert>
<Alert tone="success" title="Payment received">…</Alert>
<Alert tone="warning" title="API key rotating soon">…</Alert>
<Alert tone="danger" title="Deploy failed">Build #4821 failed on step "test:e2e". Check logs for the stack trace.</Alert>
// showcase/src/pages/components/AlertPage.tsx
```

## Notes

- **`danger` is assertive** — it renders `role="alert"` (announced immediately); the other three render
  `role="status"` (polite). Choose `danger` only for a real error condition.
- The glyph is `aria-hidden` (decorative) — the accessible meaning comes from `title` + body, so keep
  the title meaningful.
- `dismissible` only renders the `×` button; wire `onDismiss` to actually remove the Alert — the
  component does not self-hide.
- Status-family map: `info → info` · `success → positive` · `warning → caution` · `danger → negative`.
