# Text — one typography primitive across the families

The body-copy primitive: one component spanning eleven typographic roles, from `display` and the
heading echoes through `body`, `lead`, `muted`, `code`, and `quote`. Each role selects its own element,
face, size, and default ink. Reach for it for any run of text that is not a section title. Import:
`import { Text } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `variant` | `"display" \| "h1" \| "h2" \| "h3" \| "h4" \| "lead" \| "body" \| "small" \| "muted" \| "code" \| "quote"` (`TextVariant`) | `"body"` | The typographic role — selects the element + the `.mx-text--<variant>` recipe. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | — | Ink from a ramp (`--<ramp>-11`); overrides the variant ink. |
| `italic` | `boolean` | — | Italic style. |
| `align` | `"left" \| "center" \| "right"` | — | `text-align`. |
| `children` | `ReactNode` | — | The text content. |
| …rest | `HTMLAttributes<HTMLElement>` | — | `id`, `className`, `aria-*`, … pass through to the rendered element. |

## The enum language

`variant` resolves to `.mx-text--<variant>`, each carrying a face + size + default ink (canon §type):

- `display` — DM Serif Display (`--font-display`), the editorial hero face.
- `h1` / `h2` / `h3` — DM Mono (`--font-secondary`), the display echoes.
- `h4` — DM Sans (`--font-primary`) bold.
- `lead` — large body, `--fg-secondary`.
- `body` — the default prose run.
- `small` / `muted` — fine print; `muted` reads `--fg-tertiary`.
- `code` — DM Mono on a `--bg-tertiary` chip.
- `quote` — italic, `--fg-secondary`, with a `--border-strong` rule on the inline-start edge.

`accent` resolves to `.mx-text--accent-<id>` → the `--<ramp>-11` ink token. Tokens only — no inline ink.

## Composition

- **Composes:** nothing — a leaf type primitive.
- **Pairs with:** [Heading](../Heading/Heading.prompt.md) — Heading sets the titles, Text sets the
  prose; the two share the `accent` ramp vocabulary.
- **Composed by:** form field descriptions, card bodies, and list captions across the library and apps.

## Examples

```tsx
// Default body copy
<Text>The job ran for 4.2 seconds and emitted 12 events.</Text>

// A lead paragraph and a muted footnote
<Text variant="lead">Distribute work across the bus, fan out to workers, and replay the log.</Text>
<Text variant="muted">Last synced 2 minutes ago.</Text>

// Inline code and a pull quote in an accent ink
<Text variant="code">XADD emq:q:default</Text>
<Text variant="quote" accent="plum">The brand is the type.</Text>
```

## Notes

- **Recoloring** is the `accent` prop (the six ramps); the default ink comes from the variant. Tokens
  only — there is no arbitrary ink value.
- `variant` chooses the **element** too (`display`/`h1`→`<h1>`, `body`→`<p>`, `code`→`<code>`,
  `quote`→`<blockquote>`). For a heading-shaped element with the full title scale, prefer
  [Heading](../Heading/Heading.prompt.md).
- The `quote` variant is italic by default; its inline-start rule stays `--border-strong` regardless of
  `accent` (accent recolors the text ink only).
- (source-grounded; no app call site — a net-new mx.7.1 import.)
