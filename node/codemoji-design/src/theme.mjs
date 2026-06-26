// @codemoji/design — theme generator.
//
// Emits Tailwind v4 CSS-first theme text from tokens/tokens.mjs and writes it
// to dist/theme.css (reproducibly, offline). The generated CSS is a DROP-IN for
// codemoji-app/src/styles.css's token surface: the `@theme inline` names match
// the app's (so the same `bg-accent` / `text-h1` / `from-bg-from` utilities
// compile), but the accent is a SINGLE themeable channel (`--accent`) that the
// three `[data-theme]` blocks override — fixing the app's double-defined,
// non-themeable `--color-accent`.
//
// Used by `bin/codemoji-design.mjs theme` (sibling to `sortout`).

import { mkdirSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import {
  base,
  literalColors,
  textScale,
  fontSans,
  accentThemes,
  gold,
  actions,
} from '../tokens/tokens.mjs';

const PKG_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

// --- helpers ---------------------------------------------------------------

const decl = (name, value) => `  --${name}: ${value};`;

// The `@theme inline` color aliases that the app routes through :root. Each
// `--color-<x>` maps to `var(--<x>)`. The list (and order) mirrors the app's
// @theme inline so the generated surface is a drop-in. `accent` is INCLUDED
// here as `var(--accent)` (single themeable channel) — NOT later overwritten
// by a literal HSL, which is the app's bug we collapse.
const COLOR_ALIASES = [
  'background',
  'foreground',
  'card',
  'card-foreground',
  'card-foreground-secondary',
  'popover',
  'popover-foreground',
  'popover-foreground-secondary',
  'active-slot',
  'primary',
  'primary-foreground',
  'accent', // single themeable channel -> var(--accent)
  'border',
  'muted',
  'secondary',
  'secondary-foreground',
  'muted-foreground',
  'accent-foreground',
  'destructive',
  'link',
  'slot',
  'slot-active',
  'input',
  'ring',
  'chart-1',
  'chart-2',
  'chart-3',
  'chart-4',
  'chart-5',
  'sidebar',
  'sidebar-foreground',
  'sidebar-primary',
  'sidebar-primary-foreground',
  'sidebar-accent',
  'sidebar-accent-foreground',
  'sidebar-border',
  'sidebar-ring',
];

// --- block builders --------------------------------------------------------

function themeBlock() {
  const lines = [];

  // type scale
  lines.push(decl('text-2xs', textScale['2xs']) + ' /* 10px */');
  lines.push(decl('text-h1', textScale.h1) + ' /* 20px */');
  lines.push(decl('text-h2', textScale.h2) + ' /* 18px */');
  lines.push(decl('text-h3', textScale.h3) + ' /* 16px */');
  lines.push(decl('text-h4', textScale.h4) + ' /* 14px */');
  lines.push(decl('text-h5', textScale.h5) + ' /* 12px */');
  lines.push(decl('text-h6', textScale.h6) + ' /* 10px */');
  lines.push(decl('text-large', textScale.large) + ' /* 26px */');
  lines.push('');

  // color aliases routed through :root (semantic var() chain)
  for (const name of COLOR_ALIASES) lines.push(decl(`color-${name}`, `var(--${name})`));
  lines.push('');

  // literal-color semantic tokens (declared directly in @theme inline by the
  // app). `accent` is intentionally OMITTED here — it lives only in the alias
  // list above as var(--accent) so it stays themeable.
  lines.push(decl('color-bg-app-from', literalColors['bg-app-from']) + ' /* #E8F3F7 */');
  lines.push(decl('color-bg-app-to', literalColors['bg-app-to']) + ' /* #AFC7D6 */');
  lines.push(decl('color-bg-from', literalColors['bg-from']) + ' /* #E8F3F7 */');
  lines.push(decl('color-bg-to', literalColors['bg-to']) + ' /* #AFC7D6 */');
  lines.push(decl('color-bg-main', literalColors['bg-main']) + ' /* #E8F3F7 */');
  lines.push(decl('color-bg-secondary', literalColors['bg-secondary']) + ' /* #AFC7D6 */');
  lines.push(decl('color-accent-secondary', literalColors['accent-secondary']) + ' /* #FF2F00 */');
  lines.push(decl('color-success', literalColors.success) + ' /* #00D95F */');
  lines.push(decl('color-muted', literalColors.muted) + ' /* #666666 */');
  lines.push(decl('color-dark-muted', literalColors['dark-muted']) + ' /* #333333 */');
  lines.push('');

  // gold treatment as Tailwind utilities (e.g. bg-gradient-gold, bg-gold,
  // text-gold-foreground, border-gold-border).
  lines.push(decl('gradient-gold', gold.gradientGold));
  lines.push(decl('color-gold', gold.goldSurface) + ' /* #CC7500 */');
  lines.push(decl('color-gold-foreground', gold.goldForeground) + ' /* #FFFFFF */');
  lines.push(decl('color-gold-border', gold.goldBorder) + ' /* #E6A900 */');
  lines.push('');

  // action colors (role-based button colors): bg-gradient-purchase, bg-enter.
  lines.push(decl('gradient-purchase', actions.gradientPurchase));
  lines.push(decl('color-enter', actions.enter) + ' /* #0050FF */');
  lines.push('');

  // font
  lines.push(decl('font-sans', fontSans));

  return `@theme inline {\n${lines.join('\n')}\n}`;
}

function rootBlock() {
  const lines = [];
  for (const [name, value] of Object.entries(base)) lines.push(decl(name, value));
  lines.push('');
  lines.push('  /* gold treatment (formalized from the app\'s ad-hoc gild) */');
  lines.push(decl('gradient-gold', gold.gradientGold));
  lines.push(decl('gold-surface', gold.goldSurface));
  lines.push(decl('gold-foreground', gold.goldForeground));
  lines.push(decl('gold-border', gold.goldBorder));
  lines.push('');
  lines.push('  /* action colors (role-based button colors) */');
  lines.push(decl('gradient-purchase', actions.gradientPurchase));
  lines.push(decl('enter', actions.enter));
  return `:root {\n${lines.join('\n')}\n}`;
}

function themeOverrideBlocks() {
  // exactly one block per accent theme, each overriding the single --accent.
  return Object.entries(accentThemes)
    .map(([name, hex]) => `[data-theme="${name}"] {\n${decl('accent', hex)}\n}`)
    .join('\n\n');
}

// Tailwind v4 has NO bg-gradient-<name> utility for a --gradient-* theme var, so
// `bg-gradient-gold` / `bg-gradient-purchase` are no-ops without an explicit
// @utility (background-image is the right property for a gradient fill). Emitting
// these here ships the working classes with the drop-in artifact.
function utilityBlock() {
  return [
    '@utility bg-gradient-gold {',
    '  background-image: var(--gradient-gold);',
    '}',
    '',
    '@utility bg-gradient-purchase {',
    '  background-image: var(--gradient-purchase);',
    '}',
  ].join('\n');
}

// --- public API ------------------------------------------------------------

/**
 * Generate the full Tailwind v4 CSS-first theme text.
 * @returns {string} CSS text: @theme inline + :root + three [data-theme] blocks.
 */
export function generateTheme() {
  const header = [
    '/* GENERATED by @codemoji/design — do not edit by hand.',
    ' * Source of truth: tokens/tokens.mjs. Regenerate: `codemoji-design theme`.',
    ' *',
    ' * Drop-in for codemoji-app/src/styles.css token surface: the theme-block',
    ' * names match the app so the same utilities compile, but --accent is a SINGLE',
    ' * themeable channel — the three [data-theme] blocks recolor the Buy/CTA accent',
    ' * (orange | blue | green). The gold treatment tokenizes the app\'s ad-hoc gild',
    ' * (--gradient-gold is the lobby-info banner gradient, verbatim).',
    ' */',
  ].join('\n');

  return `${header}\n\n${themeBlock()}\n\n${rootBlock()}\n\n${themeOverrideBlocks()}\n\n${utilityBlock()}\n`;
}

/**
 * Write the generated theme to dist/theme.css (creates dist/ if absent).
 * @param {{ outDir?: string }} [opts]
 * @returns {string} the path written.
 */
export function writeTheme(opts = {}) {
  const outDir = opts.outDir || join(PKG_ROOT, 'dist');
  mkdirSync(outDir, { recursive: true });
  const out = join(outDir, 'theme.css');
  writeFileSync(out, generateTheme());
  return out;
}
