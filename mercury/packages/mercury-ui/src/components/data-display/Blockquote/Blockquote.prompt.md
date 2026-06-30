# Blockquote — a quotation set off by a leading rule

A quoted passage in upright, secondary ink behind a leading rule, with an optional attribution line
in DM Mono. Reach for it to lift a quotation out of running prose. Import:
`import { Blockquote } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `size` | `"sm" \| "md" \| "lg"` (`BlockquoteSize`) | `"md"` | Type size, line height, and the inline padding. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` (`BlockquoteAccent`) | — | Recolours the rule (`--<ramp>-9`) and the attribution ink (`--<ramp>-11`). |
| `cite` | `ReactNode` | — | Attribution line, rendered below in DM Mono (`--font-secondary`). |
| `children` | `ReactNode` | — | The quoted passage. |
| …rest | `HTMLAttributes<HTMLQuoteElement>` | — | `id`, `className`, `aria-*`, … pass through to the `<blockquote>` (the native string `cite` attribute is omitted in favour of the `ReactNode` prop). |

## The enum language

- `size` resolves to `.mx-blockquote--<size>` → the type ramp (14/16/18px) and the leading padding.
- `accent` resolves to `.mx-blockquote--accent-<id>`: the leading rule takes `--<ramp>-9`, the
  attribution footer takes `--<ramp>-11`. With no `accent` the rule is `--border-strong` and the
  attribution is `--fg-tertiary`. The quoted text stays `--fg-secondary`.

## Composition

- **Composes:** nothing — a leaf type primitive.
- **Pairs with:** [Text](../../foundations/Text/Text.prompt.md) — Text carries running prose (including a
  lighter inline `quote` variant); Blockquote is the standalone block quotation with a leading rule and
  attribution. The two share the six-ramp `accent` vocabulary.

## Examples

```tsx
<Blockquote cite="— The BCS law">
  The only values that cross a boundary are identities, and messages about identities.
</Blockquote>

<Blockquote size="lg" accent="iris">A larger pull quote in the iris ramp.</Blockquote>
```

## Notes

- Renders semantic `<blockquote>` + `<footer>`; the attribution is `cite` as a `ReactNode` (the native
  HTML `cite` URL attribute is intentionally omitted to avoid the name clash).
- The leading rule uses `border-inline-start`, so it flips correctly under RTL.
- (source-grounded; no app call site — a net-new mx.7.2 import.)
