# Design tokens — jonnify dark-editorial

The complete `:root` token palette every course page opens its `<style>` with. The builder injects these via the shared head, so an author never re-declares them — but matching them exactly is required when editing, when adding SVG (which needs the literal hex, since SVG attributes cannot read CSS variables), and when choosing an accent. Values below are authoritative, copied from the built pages.

## The full :root block

```css
:root{
  --ink:#0a0e1a; --ink-2:#10162b; --ink-3:#161d38;
  --cream:#ece4d0; --cream-soft:#d7cfb9; --cream-dim:#a39c89;
  --gold:#d4a85a; --gold-bright:#f0cd7f;
  --blue:#5a87c4; --blue-bright:#9fc0ea;
  --sage:#7ba387; --sage-bright:#a7c9b1;
  --burgundy:#c4504c;
  --elixir:#b39ddb; --elixir-bright:#cdb8f0;
  --line:#2a3252;
  --serif-display:"Cormorant Garamond", Georgia, "Times New Roman", serif;
  --serif:"PT Serif", Georgia, serif;
  --sans:"Manrope", ui-sans-serif, system-ui, sans-serif;
  --mono:"JetBrains Mono", ui-monospace, "SF Mono", Menlo, monospace;
  --measure:68ch;
}
```

## Colour tokens, with role and exact value

| Token | Value | Role |
|---|---|---|
| `--ink` | `#0a0e1a` | page background, button text on accents, code-block background |
| `--ink-2` | `#10162b` | raised surfaces, inline-code background, select-button background |
| `--ink-3` | `#161d38` | deeper surface, active arc node, SVG node fill |
| `--cream` | `#ece4d0` | body text, strong text, headings |
| `--cream-soft` | `#d7cfb9` | secondary prose, lede, takeaway, bridge cell text |
| `--cream-dim` | `#a39c89` | captions, eyebrow sublabels, dim separators, axis labels |
| `--gold` | `#d4a85a` | **primary accent**, eyebrow, results, links, pager border |
| `--gold-bright` | `#f0cd7f` | bright results, readout text, hovered link target, active gold button |
| `--blue` | `#5a87c4` | alternate accent (a second function/state), note border |
| `--blue-bright` | `#9fc0ea` | bright blue, active blue button |
| `--sage` | `#7ba387` | alternate accent (a third function/state), live pill |
| `--sage-bright` | `#a7c9b1` | bright sage, active sage button |
| `--burgundy` | `#c4504c` | **warnings and counterexamples** ("not a function") |
| `--elixir` | `#b39ddb` | **the FP / code accent**, dive tags, lab marker, soon pill |
| `--elixir-bright` | `#cdb8f0` | bright elixir-purple, the `<h1> .ex` highlight, op tokens in code |
| `--line` | `#2a3252` | hairline borders, dividers, idle SVG strokes, grid lines |

Bright variants are the high-emphasis form of each accent: the muted token (`--gold`, `--blue`, `--sage`, `--elixir`) carries borders, idle states, and labels; the `-bright` token carries the active state, results, and hovered targets. `--burgundy` has no bright variant — it is used at full strength for the single counterexample/warning role.

## Font stacks (the four families)

| Token | Stack | Use |
|---|---|---|
| `--serif-display` | `"Cormorant Garamond", Georgia, "Times New Roman", serif` | headings `h1`–`h4`, the lede, takeaways, card titles |
| `--serif` | `"PT Serif", Georgia, serif` | body prose, the default `body` font, math spans |
| `--sans` | `"Manrope", ui-sans-serif, system-ui, sans-serif` | labels, eyebrow, buttons, nav, pills, captions |
| `--mono` | `"JetBrains Mono", ui-monospace, "SF Mono", Menlo, monospace` | code, readouts, route tags, the build stamp, SVG numerals |

JetBrains Mono renders ligatures, so `|>` and `==` show natively in code. The fonts load from Google Fonts via the head's stylesheet link; no fonts are vendored.

## Layout token

| Token | Value | Use |
|---|---|---|
| `--measure` | `68ch` | the prose measure — `.prose`, `.kicker`, and the page reading width cap |

Related fixed measures used in the built pages (not `:root` tokens, but house values): the `.lede` caps at `46ch`, the `.colophon` at `42ch`, the content `.wrap` at `max-width:1080px`. The mobile breakpoint is `@media (max-width:760px)`.

## SVG colour rule

SVG presentation attributes (`fill`, `stroke`) cannot reference CSS custom properties, so inside `<svg>` use the literal hex. Map by role, not by guess:

- result / primary accent → `#f0cd7f` (gold-bright) or `#d4a85a` (gold)
- node fill → `#161d38` (ink-3); idle stroke → `#2a3252` (line) or `#a39c89` (cream-dim)
- alternate states → `#9fc0ea` (blue-bright), `#a7c9b1` (sage-bright)
- counterexample → `#c4504c` (burgundy) or a lighter `#e08f8b` for text on dark
- code / FP accent → `#cdb8f0` (elixir-bright)
- axis and label text → `#a39c89` (cream-dim)

CSS rules that target SVG via class (e.g. `.arc-flow`, `.lin-arrow`) still use `var(--token)`.
