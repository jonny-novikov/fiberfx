# Kbd — a keyboard keycap

A keycap marking a key the user presses, in DM Mono on a raised surface with a subtle bottom edge.
Reach for it in help text and shortcut hints; compose several for a chord. Import:
`import { Kbd } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `size` | `"sm" \| "md" \| "lg"` (`KbdSize`) | `"md"` | Cap height (18/22/28px) and type size. |
| `children` | `ReactNode` | — | The key label (`⌘`, `Esc`, `K`). |
| …rest | `HTMLAttributes<HTMLElement>` | — | `id`, `className`, `aria-*`, … pass through to the `<kbd>`. |

## The enum language

- `size` resolves to `.mx-kbd--<size>` → the 18/22/28px cap height and the 11/12/14px type size. The cap is
  `--bg-secondary` with a `--border-primary` inset hairline and a `--border-strong` bottom edge; ink is
  `--fg-secondary`.

## Composition

- **Composes:** nothing — a leaf primitive.
- **Pairs with:** [Code](../Code/Code.prompt.md) — Code is a literal of code/text; Kbd is a key a user
  presses. The two share the DM Mono (`--font-secondary`) face.

## Examples

```tsx
Press <Kbd>Esc</Kbd> to close.

<span style={{ display: "inline-flex", gap: 6 }}>
  <Kbd>⌘</Kbd><Kbd>⇧</Kbd><Kbd>P</Kbd>
</span>
```

## Notes

- Renders a semantic `<kbd>`; the cap surface and bottom edge are class-driven, never inline.
- For a multi-key chord, render several `<Kbd>` in an inline flex row with a small gap (no built-in
  separator).
- (source-grounded; no app call site — a net-new mx.7.2 import.)
