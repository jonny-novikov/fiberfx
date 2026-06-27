// FORK of lib/css-fallback.mjs (declared in cfg.libOverrides). Only
// `fallbackCssFromStorybook` differs: it data-URL-inlines local image assets
// so brand images resolve in previews AND post-upload. Upstream leaves them as
// 404s ([CSS_ASSETS]). This repo references images two ways, both fixed here:
//   1. CSS  — `--gold-texture: url(../assets/gold.png)` (Button `golden`, Badge `gold`).
//   2. JS   — bundled component code: a complete literal
//      `'/assets/emoji/01-emoji-set.png'` (SpriteEmoji → 6 board components) and
//      template literals `` `${ASSET}/iphone-topbar.png` `` (NavPhonePanel chrome).
// The bundle JS is written by bundleToIife BEFORE this hook runs and re-read
// from disk by stampHeader AFTER, so rewriting it here is safe and the
// _ds_sync.json anchor (hashed later) stays consistent. Imports are
// node-builtin-only → no import re-pointing / node_modules symlink needed.

import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';

const IMG_MIME = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.webp': 'image/webp', '.avif': 'image/avif', '.svg': 'image/svg+xml' };
const SIZE_CAP = 300 * 1024;
const INLINE_DIR = join(process.cwd(), '.design-sync', 'inline-assets');
const extOf = (p) => { const i = p.lastIndexOf('.'); return i < 0 ? '' : p.slice(i).toLowerCase(); };

// Resolve an asset to a data: URL. Prefers a hand-optimized override at
// .design-sync/inline-assets/<basename> (the source gold.png is 1.3M → a 320px
// override is ~80K); else the first existing candidate path. Over the size cap
// with no override → skipped (left for the [CSS_ASSETS] warning). Returns the
// data: URL string or null (pushing a reason to `skipped`).
function dataUrlFor(basename, candidates, skipped, ref) {
  const ext = extOf(basename);
  if (!IMG_MIME[ext]) return null; // non-image (fonts handled by extractFonts)
  let file = null, isOverride = false;
  for (const p of [join(INLINE_DIR, basename), ...candidates]) {
    try { if (statSync(p).isFile()) { file = p; isOverride = p.startsWith(INLINE_DIR); break; } } catch { /* keep probing */ }
  }
  if (!file) { skipped.push(`${ref} (not found)`); return null; }
  const sz = statSync(file).size;
  if (!isOverride && sz > SIZE_CAP) { skipped.push(`${ref} (${(sz / 1024).toFixed(0)}K > ${(SIZE_CAP / 1024).toFixed(0)}K cap — add .design-sync/inline-assets/${basename})`); return null; }
  return `data:${IMG_MIME[ext]};base64,${readFileSync(file).toString('base64')}`;
}

// basename -> absolute path under a dir, for `${VAR}/file.ext` templates whose
// base prefix isn't a literal we can read. Duplicates are dropped (ambiguous).
function basenameMap(dir, acc = new Map(), dupes = new Set()) {
  let entries;
  try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return acc; }
  for (const e of entries) {
    const p = join(dir, e.name);
    if (e.isDirectory()) basenameMap(p, acc, dupes);
    else if (IMG_MIME[extOf(e.name)]) { if (acc.has(e.name)) { dupes.add(e.name); acc.delete(e.name); } else if (!dupes.has(e.name)) acc.set(e.name, p); }
  }
  return acc;
}

// Rewrite absolute /assets image refs in the bundled component JS as data URLs:
// complete string/backtick literals, and `${IDENT}/file.ext` templates resolved
// by unique basename under <sbStatic>/assets.
function inlineBundleAssets(bundleJs, sbStatic, inlined, skipped) {
  if (!existsSync(bundleJs)) return;
  let js = readFileSync(bundleJs, 'utf8');
  const IMGEXT = 'png|jpe?g|gif|webp|avif|svg';
  // 1. complete literals: "…/assets/…​.ext" / '…' / `…` (no interpolation inside)
  js = js.replace(new RegExp('(["\'\`])(/assets/[^"\'\`${}]+?\\.(?:' + IMGEXT + '))\\1', 'gi'), (whole, q, path) => {
    const url = dataUrlFor(path.split('/').pop(), [join(sbStatic, path.replace(/^\/+/, ''))], skipped, path);
    if (!url) return whole;
    inlined.push(`${path.split('/').pop()} (js)`);
    return `${q}${url}${q}`;
  });
  // 2. `${IDENT}/file.ext` templates → data URL string literal (base prefix is a var)
  const bmap = basenameMap(join(sbStatic, 'assets'));
  js = js.replace(new RegExp('`\\$\\{[A-Za-z_$][\\w$]*\\}(/[^`${}]+?\\.(?:' + IMGEXT + '))`', 'gi'), (whole, suffix) => {
    const base = suffix.split('/').pop();
    const hit = bmap.get(base);
    if (!hit) { skipped.push(`\${…}${suffix} (js template — basename not unique under /assets)`); return whole; }
    const url = dataUrlFor(base, [hit], skipped, `\${…}${suffix}`);
    if (!url) return whole;
    inlined.push(`${base} (js template)`);
    return `"${url}"`;
  });
  writeFileSync(bundleJs, js);
}

// Brand fonts shipped via .storybook/preview-head.html land inline in the
// built iframe.html, often as base64 data-URI @font-face that no filename
// search finds. Harvest faces that are FULLY self-contained for families
// nothing else shipped.
export function inlineFontFacesFromStorybook(sbStatic, existingRules) {
  if (!sbStatic) return [];
  let html;
  try { html = readFileSync(join(sbStatic, 'iframe.html'), 'utf8'); } catch { return []; }
  const familyOf = (block) => /font-family:\s*['"]?([^'";}]+)/i.exec(block)?.[1].trim().toLowerCase();
  const have = new Set(existingRules.map(familyOf).filter(Boolean));
  const out = [];
  for (const m of html.matchAll(/@font-face\s*\{[^}]*\}/gi)) {
    const block = m[0];
    const urls = [...block.matchAll(/url\(\s*['"]?([^'")]+)/gi)].map((u) => u[1]);
    if (!urls.length || !urls.every((u) => u.startsWith('data:'))) continue;
    const fam = familyOf(block);
    if (!fam || have.has(fam)) continue;
    out.push(block);
  }
  if (out.length) console.error(`  [FONTS_FROM_PREVIEW_HEAD] harvested ${out.length} data-URI @font-face rule(s) from the storybook reference`);
  return out;
}

export function isPlaceholderCss(p) {
  if (!existsSync(p)) return false;
  const sz = statSync(p).size;
  if (sz > 500) return false;
  const txt = readFileSync(p, 'utf8');
  const stripped = txt.replace(/\/\*[\s\S]*?\*\//g, '').replace(/@(import|charset)\b[^;]*;/g, '').trim();
  return stripped.length === 0;
}

// If bundleCss is a placeholder/missing stub, replace it with storybook-static's
// compiled CSS. FORK: image url()s in that CSS AND absolute /assets refs in the
// bundled JS are inlined as data URLs (above) so they survive upload.
export function fallbackCssFromStorybook({ bundleCss, sbStatic, out }) {
  if ((existsSync(bundleCss) && !isPlaceholderCss(bundleCss)) || !sbStatic || !existsSync(join(sbStatic, 'iframe.html'))) return null;
  const iframeHtml = readFileSync(join(sbStatic, 'iframe.html'), 'utf8');
  const links = [...iframeHtml.matchAll(/<link\b[^>]*>/gi)]
    .map((m) => m[0])
    .filter((t) => /\brel\s*=\s*["']stylesheet["']/i.test(t))
    .map((t) => t.match(/\bhref\s*=\s*["']([^"']+)["']/i)?.[1])
    .filter((h) => h && !/^(https?:|\/\/)/.test(h))
    .map((h) => join(sbStatic, h.replace(/^\.\//, '')))
    .filter((p) => p.startsWith(sbStatic + sep) && existsSync(p))
    .sort((a, b) => statSync(b).size - statSync(a).size);
  const inlined = [], skipped = [];
  if (links[0]) {
    const was = existsSync(bundleCss) ? `a ${statSync(bundleCss).size}B placeholder` : 'missing';
    const kb = (statSync(links[0]).size / 1024).toFixed(0);
    const srcDir = dirname(links[0]);
    const css = readFileSync(links[0], 'utf8');
    // CSS url() pass — relative refs resolve against the stylesheet's own dir,
    // absolute against the storybook static root (where public/ was copied).
    const cssOut = css.replace(/url\(\s*(['"]?)((?!data:|https?:|\/\/)[^'")]+)\1\s*\)/gi, (whole, _q, ref) => {
      const clean = ref.split(/[?#]/)[0];
      const url = dataUrlFor(clean.split('/').pop(), [clean.startsWith('/') ? join(sbStatic, clean.slice(1)) : join(srcDir, clean), join(sbStatic, clean.replace(/^\/+/, ''))], skipped, ref);
      if (!url) return whole;
      inlined.push(`${clean.split('/').pop()} (css)`);
      return `url("${url}")`;
    });
    writeFileSync(bundleCss, cssOut);
    console.error(`[CSS_FROM_STORYBOOK] _ds_bundle.css was ${was} — replaced with ${relative(out, links[0])} (${kb} KB).`);
    // JS pass — the bundled component code (written by bundleToIife, re-read by
    // stampHeader after this hook).
    inlineBundleAssets(join(out, '_ds_bundle.js'), sbStatic, inlined, skipped);
    if (inlined.length) console.error(`  [CSS_ASSETS_INLINED] ${inlined.length} image ref(s) inlined as data URLs: ${inlined.join(', ')}`);
    if (skipped.length) console.error(`[CSS_ASSETS] ${skipped.length} ref(s) left unresolved (will 404 post-upload): ${skipped.slice(0, 6).join(', ')}${skipped.length > 6 ? ', …' : ''}`);
    return srcDir;
  }
  console.error(`[CSS_PLACEHOLDER] _ds_bundle.css is missing or a stub (@import-only, <500B) and no storybook CSS found to fall back to — set cfg.cssEntry to the compiled stylesheet.`);
  return null;
}

export function scrapeRemoteImports(sbStatic) {
  if (!sbStatic || !existsSync(join(sbStatic, 'iframe.html'))) return [];
  const iframeHtml = readFileSync(join(sbStatic, 'iframe.html'), 'utf8');
  const out = [...new Set(
    [...iframeHtml.matchAll(/<link\b[^>]*>/gi)]
      .map((m) => m[0])
      .filter((t) => /\brel\s*=\s*["']stylesheet["']/i.test(t))
      .map((t) => t.match(/\bhref\s*=\s*["']([^"']+)["']/i)?.[1])
      .filter((h) => h && /^(https?:|\/\/)/.test(h))
      .map((h) => (h.startsWith('//') ? 'https:' + h : h)),
  )];
  if (out.length) console.error(`  remote stylesheet(s) from storybook: ${out.length} → styles.css @import url(...)`);
  return out;
}
