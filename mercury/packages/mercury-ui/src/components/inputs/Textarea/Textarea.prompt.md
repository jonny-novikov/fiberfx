# Textarea — the multi-line text field

A labeled multi-line text entry with a hint line, a validation-error state, an optional resize grip,
and a live character counter when `maxLength` is set. Reach for it for free-form prose — a note, a
bio, a message. Import: `import { Textarea } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | `string` | — | Text label above the field; renders a ` *` marker when `required`. |
| `hint` | `string` | — | Helper copy in the footer. Shown only when there is no `error`. |
| `error` | `string` | — | Error message in the footer; sets `aria-invalid` + the error styling. Takes precedence over `hint`. |
| `resizable` | `boolean` | `false` | Allows the user to drag-resize the field (`is-resize`). |
| `rows` | `number` | `4` | Native; the initial visible row count. |
| `maxLength` | `number` | — | Native; also drives the `count/maxLength` footer counter (flags `is-over` at the cap). |
| `value` | `string \| number \| readonly string[]` | — | Native; the controlled value (a `string` value is measured for the counter). |
| `disabled` | `boolean` | — | Native; fades the field and blocks entry. |
| `required` | `boolean` | — | Native; also renders the ` *` marker beside the label. |
| `id` | `string` | auto (`useId`) | Ties the `<label htmlFor>` to the `<textarea>`; auto-generated when omitted. |
| …rest | `TextareaHTMLAttributes<HTMLTextAreaElement>` | — | `placeholder`, `onChange`, `onBlur`, `name`, `aria-*`, `className` pass through to the `<textarea>` (`forwardRef` to it). |

## Composition

- **Composes:** nothing — a leaf.
- **Composed by:** any form surface that needs a multi-line field. *(No app call site yet;
  source-grounded — sibling contracts authored across mx.2.)*

## Examples

```tsx
// Basic — labeled, with a hint
<Textarea label="Bio" placeholder="Tell us about yourself" hint="A sentence or two." />
// (source-grounded; no app call site)

// Counter + error state (maxLength drives the footer counter)
<Textarea label="Message" maxLength={280} value={msg} onChange={(e) => setMsg(e.target.value)} error="Message is required" />
// (source-grounded; no app call site)

// Resizable, taller default
<Textarea label="Notes" rows={6} resizable />
// (source-grounded; no app call site)
```

## Notes

- **No app call site** — the snippets above are constructed from the live interface and labeled
  *(source-grounded; no app call site)*.
- **No enum props** — no enum-language section. The only stylistic state is `error`: its presence
  flips the field to the **`negative`** status family and sets `aria-invalid="true"`; the `error` text
  takes the place of `hint` in the footer.
- **The counter** renders only when `maxLength` is set, and only a `string` `value` is measured
  (`typeof value === "string"`); it adds the `is-over` class once the length reaches the cap.
- **Accessibility** — wrapped in its `<label>` and tied by `id` (auto via `useId` when not supplied).
