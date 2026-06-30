# Callout — an inline emphasis block

A contextual note set into the reading flow — an icon plus copy on a tinted, surface, or outlined
card. Reach for it to emphasise a passage inline; reach for `Alert` when reporting the result of an
action. Import: `import { Callout } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `intent` | `"info" \| "brand" \| "positive" \| "caution" \| "negative" \| "discovery"` (`CalloutIntent`) | `"info"` | Tone family — selects the semantic token family. |
| `variant` | `"soft" \| "surface" \| "outline"` (`CalloutVariant`) | `"soft"` | Fill/border treatment. |
| `size` | `"sm" \| "md" \| "lg"` (`CalloutSize`) | `"md"` | Padding, gap, type size, and icon px. |
| `title` | `ReactNode` | — | Optional bold lead line above the body. |
| `icon` | `IconName \| null` | intent default | Override the default intent glyph; `null` hides the icon. |
| `children` | `ReactNode` | — | The body copy. |
| …rest | `HTMLAttributes<HTMLDivElement>` | — | `id`, `className`, `aria-*`, … pass through to the root `<div role="note">`. |

## The enum language

- `intent` resolves to `.mx-callout--<intent>` → the semantic families (canon §6): `info`→`--bg-info-subtle`
  / `--fg-info`, `brand`→`--bg-brand-subtle` / `--fg-brand`, `positive`→`--bg-positive-subtle` /
  `--fg-positive`, `caution`→`--bg-caution-subtle` / `--fg-caution`, `negative`→`--bg-negative-subtle` /
  `--fg-negative`, `discovery`→`--bg-discovery-subtle` / `--fg-discovery`. The icon and title take the
  intent `--fg-*`; the body stays `--fg-primary`.
- `variant` resolves to `.mx-callout--<variant>`: `soft` is the tinted fill from the intent `-subtle`
  family; `surface` is a neutral `--bg-secondary` card with a `--border-secondary` hairline; `outline` is
  transparent with an intent-tinted hairline (`--border-<intent>` at reduced alpha; `info` uses
  `--border-active`, the family with no dedicated `--border-info` token).
- `size` resolves to `.mx-callout--<size>` → the padding/type ramp.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — the leading intent glyph (a real glyph
  name; `null` hides it).
- **Distinct from:** [Alert](../Alert/Alert.prompt.md) — Alert is a status message (`tone`:
  info/success/warning/danger, dismissible, with actions); Callout is editorial emphasis (`intent` ×
  `variant`, no dismiss). Pick Alert for an action result, Callout for an inline note.

## Examples

```tsx
<Callout intent="info" title="Heads up">
  The export runs on the server clock — local time is not used.
</Callout>

<Callout intent="positive" variant="surface">Saved. Your changes are live.</Callout>

<Callout intent="caution" variant="outline" icon="alert">
  This action cannot be undone.
</Callout>

<Callout intent="discovery" size="sm" icon={null}>A quiet aside without an icon.</Callout>
```

## Notes

- Renders `<div role="note">`; the icon is `aria-hidden` (decorative — the tone is carried by copy, never
  by colour alone, so pair a negative/caution callout with explicit wording).
- The default glyph per intent is drawn from the live Icon set (`info`, `check`, `alert`, `help-circle`);
  there is no `warning`/`circleHelp` glyph in `@mercury/ui` — pass an explicit `icon` from the live set to
  change it.
- (source-grounded; no app call site — a net-new mx.7.2 import.)
