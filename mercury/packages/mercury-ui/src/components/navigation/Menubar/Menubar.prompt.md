# Menubar — the horizontal bar of menus

A desktop-app menu strip: a horizontal bar of top-level menus, each opening a submenu of items,
checks, and radio groups. Import: `import { Menubar } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `menus` | `MenubarMenu[]` | — (required) | The top-level menus, left to right. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | `"iris"` | The check-mark ink + radio-dot fill family. |

`MenubarMenu`: `{ label: string; icon?: IconName; items: MenubarItem[] }`. `MenubarItem`: `{ type?:
"item" | "check" | "radio" | "label" | "separator"; label?: ReactNode; id?: string; group?: string;
value?: string; checked?: boolean; shortcut?: string; icon?: IconName; onSelect?: () => void }`. A
`check` needs an `id` (its toggle state is keyed by it); a `radio` needs a `group` + `value` (the
group holds one selected value); a plain `item` runs `onSelect` and closes the submenu. The surface is
exactly these two props — no `…rest`, no `forwardRef` (the component owns the bar + per-menu refs for
the anchoring floor).

## The enum language

`accent` is a token recipe: `.mx-menubar--accent-<id>` sets two custom properties — `--mx-accent-mark:
var(--<ramp>-11)` (the check-mark ink) and `--mx-accent-solid: var(--<ramp>-9)` (the radio-dot fill) —
read by `.mx-menubar__check` / `.mx-menubar__radio-dot`. Because each submenu is **portaled** (not a
DOM descendant of the bar), the accent class rides on both the bar and each submenu panel so the
custom properties are in scope for the marks. The bar reads `--bg-secondary` / `--border-secondary` /
`--shadow-100`; a submenu panel reads `--bg-elevated` / `--shadow-300` at radius `--radius-12`.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) (a trigger's / row's glyph, the check
  mark).
- **Related:** [Dropdown](../../overlay/Dropdown/Dropdown.prompt.md) (a single trigger-anchored menu —
  the Menubar is its horizontal, multi-menu sibling), [Separator](../../foundations/Separator/Separator.prompt.md)
  (the visual model for a `separator` row), [Tabs](../Tabs/Tabs.prompt.md) / [TabNav](../TabNav/TabNav.prompt.md)
  (horizontal navigation without submenus).
- **Composed by:** net-new this rung — no app call site yet.

## Examples

```tsx
// A File / View menu bar with checks + a radio group
<Menubar
  accent="indigo"
  menus={[
    { label: "File", items: [
      { type: "item", label: "New File", icon: "plus", shortcut: "⌘N", onSelect: newFile },
      { type: "separator" },
      { type: "item", label: "Save", shortcut: "⌘S", onSelect: save },
    ]},
    { label: "View", items: [
      { type: "check", id: "sidebar", label: "Show Sidebar", checked: true, onSelect: toggleSidebar },
      { type: "separator" },
      { type: "radio", group: "density", value: "comfortable", label: "Comfortable", checked: true },
      { type: "radio", group: "density", value: "compact", label: "Compact" },
    ]},
  ]}
/>
// (source-grounded; no app call site)
```

## Notes

- **Switching + hover** — clicking a top trigger toggles its submenu; while any submenu is open,
  hovering a sibling trigger switches to it. The whole bar is `ignore`d by the dismiss floor, so a
  sibling press switches without a close-then-reopen race.
- **Keyboard** — `ArrowLeft`/`ArrowRight` move between the top triggers (wrapping); within an open
  submenu, `ArrowUp`/`ArrowDown` move between rows and `Escape` closes it.
- **Selection** — a `check` toggles in place; a `radio` selects within its `group` — both keep the
  submenu open so the state change is visible; a plain `item` closes on activation.
- **a11y** — the bar is `role="menubar"`; each trigger is `role="menuitem"` with `aria-haspopup="menu"`
  + `aria-expanded`; a submenu is `role="menu"`, its rows `role="menuitem"` /
  `role="menuitemcheckbox"` / `role="menuitemradio"` with `aria-checked`.
- **React-19 nullable ref** — the anchoring/dismiss floor guards the bar + per-menu refs (`null` while
  closed).
