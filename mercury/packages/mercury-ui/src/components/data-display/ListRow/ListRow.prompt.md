# ListRow — a horizontal item row

A single horizontal row — a leading glyph/avatar, a label with an optional description, an optional
right-aligned value, and an optional trailing affordance — for a settings list, an activity feed, or
any list of named items. Reach for it instead of hand-rolling a `<button>`/`<div>` with icon + text +
value. Becomes an interactive `<button>` when `onClick` is set, otherwise a non-interactive `<div>`.
Import: `import { ListRow } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | `ReactNode` | — *(required)* | The primary text. |
| `leading` | `ReactNode` | — | A leading glyph/avatar slot — drive with a real `<Icon />` / `<Avatar />`. |
| `description` | `ReactNode` | — | Secondary text below `label` (the "meta"/subtitle). |
| `value` | `ReactNode` | — | Trailing value text, right-aligned — e.g. a settings value or an amount. |
| `trailing` | `ReactNode` | — | A trailing affordance after `value` (a chevron / action) — usually an `<Icon name="chevron-right" />`. |
| `onClick` | `MouseEventHandler<HTMLElement>` | — | When present, the row is interactive (rendered as a `<button type="button">`); else a non-interactive `<div>`. |
| `className` | `string` | — | Merged onto the root element via `cx`. |
| …rest | `Omit<HTMLAttributes<HTMLElement>, "onClick">` | — | `id`, `style`, `aria-*`, `role`, `tabIndex`, etc. pass through to the root `<button>`/`<div>`. |

## The enum language

No enum props — `ListRow` has no `variant`/`size`/`tone`. Its single state axis is **interactive vs.
static**, derived from the presence of `onClick`: when set, the root is a `<button>` carrying
`.mx-listrow--interactive` (hover background + a focus ring); when absent, the root is a plain `<div>`.
All color/spacing resolves to the canon §6 token families (`--fg-*`, `--bg-hover`, `--ring-focus`),
never raw hex.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) (the `leading` glyph and the `trailing`
  chevron) and [Avatar](../Avatar/Avatar.prompt.md) (a `leading` avatar) — passed into the slots.
- **Composed by:** [Card](../Card/Card.prompt.md) — a list of `ListRow`s stacked inside a `padding={0}`
  card is the settings/activity panel shape (the mobile `ActivityList` Card wrapper).

## Examples

```tsx
// A tappable settings row — leading icon, label, value, chevron
<ListRow
  leading={<Icon name="user" size={18} />}
  label="Profile"
  value="Ana Ruiz"
  trailing={<Icon name="chevron-right" size={18} />}
  onClick={openProfile}
/>
// generalizes apps/mobile/src/chrome/Row.tsx (icon + label + value + chevron <button>)

// An activity-feed row inside a Card — leading icon, label + meta, amount
<Card padding={0} style={{ overflow: "hidden" }}>
  <ListRow
    leading={<Icon name="arrow-down-left" size={18} />}
    label="Received from Ana"
    description="Today · 2:14 PM"
    value="+$240.00"
  />
</Card>
// generalizes apps/mobile/src/chrome/ActivityList.tsx (icon + title/meta + amount)
```

## Notes

- **Polymorphic root, no `forwardRef`** — the root is a `<button>` (when `onClick`) or a `<div>` (when
  not), so a single ref type cannot address both; following the data-display siblings (`Card`,
  `Avatar`) `ListRow` is a plain function component and exposes no `ref` (it spreads native attrs onto
  whichever root it renders). The interactive root is a real `<button type="button">`, so keyboard
  focus + Enter/Space activation come for free.
- **Slots, not strings** — `leading`/`trailing` take a `ReactNode` (a real `<Icon />`/`<Avatar />`),
  not an icon name; `value`/`description` are plain text/nodes.
- **Accessibility** — when interactive, the row is a native `<button>` (focusable, in the tab order,
  Enter/Space-activated); when static, it is a non-interactive `<div>`.
