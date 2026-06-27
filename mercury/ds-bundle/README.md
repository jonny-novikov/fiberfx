# Building with Mercury (`@mercury/ui`)

Mercury is a token-driven, presentational React component library. Build UI by **composing its components** and styling your own layout with its **design tokens** — never reach for ad-hoc colors, fonts, or a CSS framework.

## Setup
- **No provider or theme wrapper is required.** Components are presentational (plain `className`-based) and self-styling — import and render them directly; the stylesheet loads with the bundle.
- **Light theme is the default.** For dark mode, add the class `dark-theme` to a root ancestor (`<div className="dark-theme">…</div>`); every token re-resolves underneath. (Light is `:root` / `.light-theme`.)
- Fonts ship with the bundle: **DM Sans** = `var(--font-primary)`, **DM Mono** = `var(--font-secondary)`, **DM Serif Display** = `var(--font-display)`.

## Styling idiom — props + tokens, never utility classes
Mercury has **no utility-class system**, and its internal `.mx-*` classes are private — never author them. Two rules:

1. **Style components through their props.** The design language lives in enum props — read each component's `.d.ts` for the exact set:
   - `Button` `variant="primary|secondary|outline|ghost|destructive|inverse"`, `size="sm|md|lg"`, plus `loading` / `fullWidth` / `leading` / `trailing`.
   - `Tag` / `Chip` `tone`/`variant="neutral|brand|positive|negative|caution|info|discovery"`.
   - `Alert` `tone="info|success|warning|danger"`; `Badge` `variant="brand|negative|positive|caution|info"`; `Progress` `variant`; `Card` `variant="flat|raised|floating"`.

2. **Style your OWN layout with the design tokens**, written as `rgb(var(--token))` (token values are raw RGB triplets — add ` / .5` for alpha). Vocabulary:
   - **Surfaces**: `--bg-primary` (page), `--bg-secondary`, `--bg-tertiary`, `--bg-elevated`, `--bg-brand-subtle`. **Text**: `--fg-primary`, `--fg-secondary`, `--fg-tertiary`, `--fg-brand`. **Borders**: `--border-primary`, `--border-secondary`, `--border-strong`, `--border-focus`.
   - **Status families** (each ships `--bg-*`, `--fg-*`, `--border-*`, and a soft `--bg-*-subtle`): `positive`, `negative`, `caution`, `info`, `discovery`, `brand` — e.g. `rgb(var(--bg-positive-subtle))`, `rgb(var(--fg-negative))`.
   - **Brand accent is iris/indigo.** Raw ramps `--{slate,iris,indigo,green,red,orange,plum}-1..12` (e.g. `rgb(var(--iris-9))`) when you need a specific step.
   - **Type** `var(--font-primary|secondary|display)`; **radii** `var(--radius-2..32 | --radius-full)`; **shadows** `var(--shadow-100..600)`.

## Where the truth lives
- Every component dir ships `<Name>.d.ts` (prop contract) and `<Name>.prompt.md` (usage + examples) — read these before composing.
- Tokens are defined in `styles.css` (→ `_ds_bundle.css`); grep there for any token not listed above.

## Idiomatic example
```tsx
<Card variant="raised" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
  <h3 style={{ margin: 0, font: "600 16px var(--font-primary)", color: "rgb(var(--fg-primary))" }}>
    queue-worker-03
  </h3>
  <p style={{ margin: 0, color: "rgb(var(--fg-secondary))" }}>
    Drained 1,284 jobs in the last hour.
  </p>
  <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
    <Tag tone="positive">Healthy</Tag>
    <Button size="sm" variant="primary">View runs</Button>
  </div>
</Card>
```
The controls (`Card`, `Tag`, `Button`) are Mercury components; the layout glue is inline styles using Mercury tokens — that is the whole idiom.

# MercuryUI (@mercury/ui@2.4.0)

This design system is the published @mercury/ui React library, bundled as a single
browser global. All 23 components are the real upstream code.

## Where things are

- `_ds_bundle.js` — the whole-DS bundle at the project root; loads every component to `window.MercuryUI`. First line is a `/* @ds-bundle: … */` metadata header.
- `styles.css` — the single stylesheet entry: it `@import`s the tokens, fonts, and component styles (`_ds_bundle.css`). Link this one file.
- `components/<group>/<Name>/<Name>.prompt.md` (example JSX + variants), `<Name>.d.ts` (types), `<Name>.html` (variant grid).
- `tokens/*.css` — CSS custom properties, names verbatim from upstream.
- `fonts/` — `@font-face` files + `fonts.css` (when the package ships fonts).

For a specific component, `read_file("components/<group>/<Name>/<Name>.prompt.md")`.

## Loading

Add these two lines to your page once (React must be on the page first):

```html
<link rel="stylesheet" href="styles.css">
<script src="_ds_bundle.js"></script>
```

Components are then available at `window.MercuryUI.*`. Mount into a dedicated child node (e.g. `<div id="ds-root">`), not the host page's own React root, so the two trees don't collide:

```jsx
const { Alert } = window.MercuryUI;
ReactDOM.createRoot(document.getElementById('ds-root')).render(<Alert />);
```

## Tokens

179 CSS custom properties from @mercury/ui. Names are
preserved verbatim from upstream. They are declared inside `_ds_bundle.css` (this DS ships one compiled stylesheet rather than separate token files).

- **color** (85): `--bg-primary`, `--bg-secondary`, `--bg-tertiary`, …
- **spacing** (20): `--space-2`, `--space-4`, `--space-6`, …
- **typography** (3): `--font-primary`, `--font-secondary`, `--font-display`
- **radius** (10): `--radius-2`, `--radius-4`, `--radius-6`, …
- **shadow** (6): `--shadow-100`, `--shadow-200`, `--shadow-300`, …
- **other** (55): `--slate-1`, `--slate-2`, `--slate-3`, …

## Components

### feedback
- `Alert`
- `Progress`

### inputs
- `AuthCode`
- `Input`
- `Search`
- `Select`
- `Textarea`

### data-display
- `Avatar`
- `Badge`
- `Card`
- `Chip`
- `Table`
- `Tag`

### actions
- `Button`

### selection
- `Checkbox`
- `Radio`
- `Segmented`
- `Slider`
- `Switch`

### foundations
- `Icon`

### overlay
- `Modal`
- `Tooltip`

### navigation
- `Tabs`
