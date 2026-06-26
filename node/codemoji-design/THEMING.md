# Theming — `@codemoji/design`

The design system OWNS the Codemoji tokens. `tokens/tokens.mjs` is the structured
source of truth; `codemoji-design theme` (a.k.a. `pnpm theme`) emits the
Tailwind v4 CSS-first artifact `dist/theme.css` (committed as generated output).
Storybook dogfoods that artifact (`stories/preview.css` imports it), so the
swatches, the type scale, the themeable accent, and the gold treatment shown in
Storybook are the same tokens an app would consume.

> Status: this is the FUTURE integration contract — it documents how
> `codemoji-app` WOULD consume the package. It is **not applied this rung**; the
> app is untouched.

## What the artifact contains

`dist/theme.css` is a drop-in for the token surface of
`codemoji-app/src/styles.css`:

- a `@theme inline { … }` block whose `--color-*` / `--text-*` / `--font-sans`
  names **match the app's** (so the same `bg-accent`, `text-h1`, `from-bg-from`
  utilities compile);
- a `:root { … }` with the base palette (oklch, copied verbatim from the app's
  `:root`) plus the gold tokens;
- exactly three accent themes: `[data-theme="orange"]`, `[data-theme="blue"]`,
  `[data-theme="green"]`, each overriding a **single themeable channel**,
  `--accent`.

### The accent fix

The app double-defines `--color-accent` inside `@theme inline` (a `var(--accent)`
alias **and** a later literal HSL that wins) — which makes the accent
non-themeable. The generated artifact collapses `--color-accent` to one value
driven by `var(--accent)`, so a `[data-theme]` attribute recolors every
`bg-accent` / `text-accent` surface at once.

## How `codemoji-app` would adopt it

1. **Import the artifact** in `src/styles.css`, replacing the inline token
   blocks (the `@theme inline` + `:root` + `.dark`) with:

   ```css
   @import 'tailwindcss';
   @import '@codemoji/design/theme.css';
   ```

   (Add `@codemoji/design: workspace:*` to the app's `dependencies`; the package
   exports `./theme.css` → `dist/theme.css` and `./tokens` → `tokens/tokens.mjs`.)

2. **Toggle the accent** by setting `data-theme` on a root element (e.g. the
   `BaseLayout` wrapper or `<html>`):

   ```tsx
   <div data-theme={accent /* 'orange' | 'blue' | 'green' */}>…</div>
   ```

   With no `data-theme`, the base `--accent` (orange, `#FF8400`) applies — the
   app's current look is preserved.

3. **Consume the tokens programmatically** where needed:

   ```js
   import { accentThemes, gold } from '@codemoji/design/tokens';
   ```

## The gold treatment supersedes the ad-hoc gild

Today the app gilds two ways, neither tokenized:

- the `golden` Button variant rides a raster, `bg-[url("/images/rooms/gold.png")]`
  (`codemoji-app/src/shared/ui/button/button.tsx`);
- the golden-room banner uses one inline gold gradient
  (`codemoji-app/src/widgets/lobby-info/ui/lobby-info.tsx`).

The artifact tokenizes the gradient **verbatim** as `--gradient-gold` (plus
`--color-gold` / `--color-gold-foreground` / `--color-gold-border` for a flat
fill). On adoption:

- the golden Button variant becomes `bg-gradient-gold text-gold-foreground` —
  no PNG, no opaque raster;
- the banner uses `bg-gradient-gold` instead of the inline `style` gradient.

> **"Golden" is overloaded.** A *boost class* (the `gold_multiplier` on an
> otherwise `classic` game — the Golden Room screens) is a different thing from
> the *blind commit-reveal game type* (the app's `golden` code). This treatment
> formalizes the golden **visuals** (the boost-class gild) only — it changes no
> game logic.

## Regenerating

```bash
pnpm -C node/codemoji-design theme           # regenerate dist/theme.css from tokens
pnpm -C node/codemoji-design storybook       # dev server (port 6006) — live theming
pnpm -C node/codemoji-design build-storybook # static build -> storybook-static/
```
