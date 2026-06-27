# MercuryUI (@mercury/ui@2.4.0)

This design system is the published @mercury/ui React library, bundled as a single
browser global. All 0 components are the real upstream code.

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
const { Component } = window.MercuryUI;
ReactDOM.createRoot(document.getElementById('ds-root')).render(<Component />);
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


