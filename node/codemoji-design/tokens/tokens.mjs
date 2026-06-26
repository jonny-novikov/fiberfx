// @codemoji/design — token source of truth (structured, ESM).
//
// This package OWNS the Codemoji design tokens. The base palette is copied
// VERBATIM from the live app's :root in codemoji-app/src/styles.css so the
// generated theme.css matches the app's values today; the type scale and
// font mirror the app's `@theme inline`. The accent is collapsed to a SINGLE
// themeable channel (`--accent`) so a `[data-theme]` block can recolor it —
// the known double-definition of --color-accent in the app's @theme inline
// (a var() alias AND a later literal HSL that wins) is the debt this fixes.
//
// `src/theme.mjs` consumes this to emit Tailwind v4 CSS-first text.

// ---------------------------------------------------------------------------
// base — the :root palette, oklch, copied verbatim from
// codemoji-app/src/styles.css :root (with the app's hex comment preserved).
// `--accent` is the ONE themeable channel (an accentThemes value overrides it
// per [data-theme]); every other value is the app's base, unchanged.
// ---------------------------------------------------------------------------
export const base = {
  background: 'oklch(0.9119 0.0161 233.04)', // #D8E4EB - white
  foreground: 'oklch(0.3211 0 0)', // #333333 - dark gray
  'foreground-secondary': 'oklch(0.5103 0 0)', // #666666 - secondary gray

  card: 'oklch(1 0 0)', // #FFFFFF - white
  'card-foreground': 'oklch(0.3211 0 0)', // #333333 - dark gray
  'card-foreground-secondary': 'oklch(0.5103 0 0)', // #666666 - secondary gray

  drawer: 'oklch(0.9474 0.008 216.63)', // #E8EFF1 - light gray
  'drawer-foreground': 'oklch(0.3211 0 0)', // #333333 - dark gray
  'drawer-foreground-secondary': 'oklch(0.5103 0 0)', // #666666 - secondary gray

  primary: 'oklch(0 0 0)', // #000000 - black
  'primary-foreground': 'oklch(1 0 0)', // #FFFFFF - white

  // --accent is the SINGLE themeable channel; the orange base equals the app's.
  accent: 'oklch(0.738 0.1834 54.69)', // #FF8400 - orange (default; [data-theme] overrides)

  border: 'oklch(0.3211 0 0)', // #333333 - dark gray

  'active-slot': 'oklch(0.2393 0 0)', // #1F1F1F

  muted: 'oklch(0.5103 0 0)', // #666666 - secondary gray

  popover: 'oklch(1 0 0)',
  'popover-foreground': 'oklch(0.145 0 0)',
  'popover-foreground-secondary': 'oklch(0.5103 0 0)',

  secondary: 'oklch(0.97 0 0)',
  'secondary-foreground': 'oklch(0.205 0 0)',

  'muted-foreground': 'oklch(0.556 0 0)',

  'accent-foreground': 'oklch(0.205 0 0)',

  destructive: 'oklch(0.577 0.245 27.325)',

  link: 'oklch(0.5249 0.264881 263.0129)', // #0050FF - blue

  slot: 'oklch(0.9474 0.008 216.63)', // #E8EFF1 - light gray
  'slot-active': 'oklch(0.8698 0.0655 225.19)', // #A6DEF5 - light gray

  input: 'oklch(0.922 0 0)',
  ring: 'oklch(0.708 0 0)',
  'chart-1': 'oklch(0.646 0.222 41.116)',
  'chart-2': 'oklch(0.6 0.118 184.704)',
  'chart-3': 'oklch(0.398 0.07 227.392)',
  'chart-4': 'oklch(0.828 0.189 84.429)',
  'chart-5': 'oklch(0.769 0.188 70.08)',
  sidebar: 'oklch(0.985 0 0)',
  'sidebar-foreground': 'oklch(0.145 0 0)',
  'sidebar-primary': 'oklch(0.205 0 0)',
  'sidebar-primary-foreground': 'oklch(0.985 0 0)',
  'sidebar-accent': 'oklch(0.97 0 0)',
  'sidebar-accent-foreground': 'oklch(0.205 0 0)',
  'sidebar-border': 'oklch(0.922 0 0)',
  'sidebar-ring': 'oklch(0.708 0 0)',
};

// ---------------------------------------------------------------------------
// literalColors — the literal-HSL semantic tokens the app declares directly in
// @theme inline (NOT routed through :root). Copied verbatim, EXCEPT `accent`,
// which the app double-defines (the bug): here `--color-accent` is driven by
// the themeable var(--accent) instead, so [data-theme] can recolor it.
// ---------------------------------------------------------------------------
export const literalColors = {
  'bg-app-from': 'hsl(196, 48%, 94%)', // #E8F3F7 - light blue
  'bg-app-to': 'hsl(203, 32%, 76%)', // #AFC7D6 - light blue
  'bg-from': 'hsl(196, 48%, 94%)', // #E8F3F7 - light blue
  'bg-to': 'hsl(203, 32%, 76%)', // #AFC7D6 - light blue
  'bg-main': 'hsl(193, 24%, 93%)', // #E8F3F7 - light blue
  'bg-secondary': 'hsl(203, 32%, 76%)', // #AFC7D6 - light blue
  'accent-secondary': 'hsl(11, 100%, 50%)', // #FF2F00 - orange
  success: 'hsl(141, 71%, 48%)', // #00D95F - green
  muted: 'hsl(0, 0%, 40%)', // #666666 - gray
  'dark-muted': 'hsl(0, 0%, 20%)', // #333333 - dark gray
};

// ---------------------------------------------------------------------------
// type scale + font — verbatim from the app's @theme inline.
// ---------------------------------------------------------------------------
export const textScale = {
  '2xs': '0.625rem', // 10px
  h1: '1.25rem', // 20px
  h2: '1.125rem', // 18px
  h3: '1rem', // 16px
  h4: '0.875rem', // 14px
  h5: '0.75rem', // 12px
  h6: '0.625rem', // 10px
  large: '1.625rem', // 26px
};

export const fontSans = "'Noto Sans Mono', monospace";

// ---------------------------------------------------------------------------
// accentThemes — the three accent treatments. Each overrides the single
// themeable `--accent` channel under its [data-theme] block. `orange` is the
// app's current accent (#FF8400); `blue` is the app's --link; `green` the
// app's --color-success. (codemoji-app/src/styles.css.)
// ---------------------------------------------------------------------------
export const accentThemes = {
  orange: '#FF8400', // the current accent
  blue: '#0050FF', // the app's --link
  green: '#00D95F', // the app's --color-success
};

// ---------------------------------------------------------------------------
// gold — the golden treatment. The app gilds the golden button/room with a metallic
// gold TEXTURE (bg-[url("/images/rooms/gold.png")]); this package carries that raster
// (public/assets/gold.png) and exposes it as `--gold-texture` + the `bg-gold-texture`
// utility, plus a small set of flat gold surface/foreground/border tokens. (Earlier it
// was a tokenized CSS gradient — replaced here by the faithful Figma texture.)
//
// NOTE (overload): "golden" is two unrelated things in the canon —
//   - a BOOST class (gold_multiplier on a classic game; the Golden Room screens)
//   - the `golden` blind/sealed commit-reveal GAME TYPE
// This treatment formalizes the golden VISUALS (the boost-class gild) only.
// ---------------------------------------------------------------------------
export const gold = {
  // The golden treatment is the app's gold TEXTURE (public/images/rooms/gold.png,
  // copied verbatim into this package's public/assets/gold.png) — the metallic fill
  // Figma uses for the golden button/room, NOT a CSS gradient. Served at
  // /assets/gold.png (the public/ staticDir). Earlier rungs tokenized this as a
  // 7-stop linear-gradient because rasters weren't available; the texture is the
  // faithful original and is restored here.
  texture: "url('/assets/gold.png')",
  // gold surface/foreground/border tokens — a flat warm gold (#CC7500) for a fill
  // where the texture is not wanted, white text over, amber border.
  goldSurface: '#CC7500',
  goldForeground: '#FFFFFF',
  goldBorder: '#E6A900',
};

// ---------------------------------------------------------------------------
// actions — SEMANTIC, role-based button colors (FIXED, not theme-following).
// The app colors action buttons by INTENT rather than by the global accent:
//   - purchase ("Приобрести ключи" / Buy keys) -> the orange buy gradient,
//     verbatim from shared/ui/button.tsx variant="gradient" (#FF8800->#FF4800).
//   - enter (Open safe / Enter room — free or paid, NON-gold) -> blue (#0050FF,
//     the app's --link / the blue accent-theme value).
// Golden rooms keep the `gold` treatment above. These three carry meaning
// (spend / play / boosted) and stay constant under any [data-theme].
// ---------------------------------------------------------------------------
export const actions = {
  gradientPurchase: 'linear-gradient(90deg, #FF8800 0%, #FF4800 100%)',
  enter: '#0050FF',
  // the iOS control-pill grey — the fill of the nav chrome buttons (the exported
  // tg-back / tg-menu rasters), reused for the circle behind the nav logo so it
  // matches the buttons exactly. Sampled #A8ACB0 (opaque) from tg-back.png.
  control: '#A8ACB0',
};

export default {
  base,
  literalColors,
  textScale,
  fontSans,
  accentThemes,
  gold,
  actions,
};
