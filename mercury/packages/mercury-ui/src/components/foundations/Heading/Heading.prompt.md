# Heading — section titles across the type scale

The display type primitive: a section title across a nine-step scale, where the large sizes ride
DM Mono — Mercury's technical display face — and the small sizes ride DM Sans. Reach for it for any
title or section heading. Import: `import { Heading } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `size` | `1 \| 2 \| 3 \| 4 \| 5 \| 6 \| 7 \| 8 \| 9` (`HeadingSize`) | `6` | Maps onto the canon 18..72 scale. Sizes 5–9 render in DM Mono (`--font-secondary`), 1–4 in DM Sans (`--font-primary`). |
| `weight` | `"regular" \| "medium" \| "semibold" \| "bold"` (`HeadingWeight`) | `"bold"` | Resolves to the `--fw-*` weight tokens. |
| `align` | `"left" \| "center" \| "right"` (`HeadingAlign`) | — | `text-align`. |
| `as` | `"h1" \| "h2" \| "h3" \| "h4" \| "h5" \| "h6" \| "div"` (`HeadingTag`) | derived from `size` | Render tag; defaults to a semantic h-level per size rank (9/8→h1, 7→h2, 6→h3, 5→h4, 4→h5, 3/2/1→h6). |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | — | Ink from a ramp (`--<ramp>-11`); overrides the default ink. |
| `truncate` | `boolean` | — | Single-line clip with an ellipsis. |
| `children` | `ReactNode` | — | The heading text. |
| …rest | `HTMLAttributes<HTMLElement>` | — | `id`, `className`, `aria-*`, … pass through to the rendered element. |

## The enum language

- `size` resolves to `.mx-heading--<1..9>` — the canon type ramp. The **display tier (5–9)** is set in
  DM Mono (`--font-secondary`); the **text tier (1–4)** in DM Sans (`--font-primary`). This split is the
  Mercury heading identity (canon §type).
- `weight` resolves to `.mx-heading--w-<weight>` → the `--fw-regular` / `--fw-medium` / `--fw-semi-bold`
  / `--fw-bold` tokens.
- `accent` resolves to `.mx-heading--accent-<id>` → the `--<ramp>-11` ink token for each of the six ramps.
  Tokens only — no raw values, no inline ink.

## Composition

- **Composes:** nothing — a leaf type primitive.
- **Pairs with:** [Text](../Text/Text.prompt.md) — Heading sets the titles, Text sets the prose; the two
  carry the same `accent` ramp vocabulary.
- **Composed by:** dialog titles, card headers, and section heads across the library and the apps (the
  overlay + data-display components reach for it as their title slot).

## Examples

```tsx
// A page section title (default size 6, DM Mono display face)
<Heading>Account settings</Heading>

// A small caption-weight subhead in DM Sans
<Heading size={3} weight="medium">Recent activity</Heading>

// A display hero title, centered, in an accent ink
<Heading size={9} align="center" accent="iris">Mercury</Heading>

// A custom tag with truncation in a narrow column
<Heading size={4} as="h2" truncate>A very long title that clips with an ellipsis</Heading>
```

## Notes

- **Recoloring** is the `accent` prop (the six ramps), not an arbitrary ink value — the ink stays inside
  the token system. The default ink is `--fg-primary`.
- `as` overrides only the element, not the visual size — pick `size` for the look and `as` for the
  document outline (e.g. a visually-small `size={3}` rendered as an `<h2>` for semantics).
- The display sizes use DM Mono at the bold weight, matching the canon `h1`/`h2`/`h3` elements.
- (source-grounded; no app call site — a net-new mx.7.1 import.)
