# Code — inline or block monospace code

Monospace code (DM Mono) on a tinted surface. Reach for it to set off a command, identifier, or path
in running text (`inline`), or a multi-line snippet (`block`). Import: `import { Code } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `variant` | `"soft" \| "solid" \| "outline" \| "ghost"` (`CodeVariant`) | `"soft"` | Surface treatment. |
| `size` | `"sm" \| "md" \| "lg"` (`CodeSize`) | `"md"` | Type size (12/13/15px) + inline padding. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` (`CodeAccent`) | — | Re-skins the surface from a ramp. |
| `block` | `boolean` | `false` | Render a scrollable `<pre>` block; otherwise an inline `<code>`. |
| `children` | `ReactNode` | — | The code text. |
| …rest | `HTMLAttributes<HTMLElement>` | — | `id`, `className`, `aria-*`, … pass through to the `<code>`/`<pre>`. |

## The enum language

- `variant` resolves to `.mx-code--<variant>`: `soft` = `--bg-tertiary` fill on `--fg-primary`; `solid` =
  `--bg-inverse` on `--fg-inverse`; `outline` = transparent with a `--border-primary` hairline; `ghost` =
  transparent on `--fg-secondary`.
- `accent` resolves to `.mx-code--accent-<id>` compounded with the variant: `soft` tints the fill from
  `--<ramp>-9 / 0.12` with `--<ramp>-11` ink; `solid` fills `--<ramp>-9` with readable ink; `outline`/`ghost`
  take `--<ramp>-11` ink (outline with a `--<ramp>-9 / 0.4` hairline).
- `size` resolves to `.mx-code--<size>` → the type ramp + the inline padding/radius. `block` adds
  `.mx-code--block` → a padded, `overflow-x: auto` `<pre>`.

## Composition

- **Composes:** nothing — a leaf type primitive.
- **Pairs with:** [Kbd](../Kbd/Kbd.prompt.md) — Kbd is a keyboard keycap (a key a user presses); Code is a
  literal of code/text. The two share the DM Mono (`--font-secondary`) face.

## Examples

```tsx
Run <Code>pnpm install @mercury/ui</Code> to add the library.

<Code variant="solid" accent="iris">JOB</Code>

<Code block>{`const id = BrandedId.mint("JOB");\nawait queue.enqueue(id);`}</Code>
```

## Notes

- `block` switches the element from `<code>` to `<pre>` and preserves whitespace (`white-space: pre`) with
  horizontal scrolling for long lines.
- The base `code`/`pre` element styles (token defaults) are overridden by the `.mx-code` classes; the
  surface and ink are class-driven, never inline.
- (source-grounded; no app call site — a net-new mx.7.2 import.)
