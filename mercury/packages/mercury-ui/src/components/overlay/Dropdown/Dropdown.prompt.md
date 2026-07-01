# Dropdown — the anchored action menu

A menu of actions anchored to a trigger — item rows, group labels, toggling checks, and separators.
Non-modal: it does not lock the page or trap focus. Import: `import { Dropdown } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `trigger` | `ReactNode` | — (required) | The trigger's **content** — a label or icon, **not** an interactive element (Dropdown renders its own `<button>`; see Notes). |
| `items` | `DropdownItem[]` | — (required) | The menu rows, in order (see the item shape below). |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | `"iris"` | The check-mark ink family. |
| `align` | `"start" \| "end"` | `"start"` | Which trigger edge the panel aligns to (`bottom-start` / `bottom-end`). |
| `width` | `number` | `220` | Panel width (px). |

`DropdownItem`: `{ type?: "item" | "label" | "separator" | "check"; label?: ReactNode; icon?: IconName;
shortcut?: string; checked?: boolean; id?: string; onSelect?: () => void; disabled?: boolean }`. A
`check` row requires an `id` (its toggle state is keyed by it) and toggles in place; a plain `item`
runs `onSelect` and closes; `label`/`separator` are presentational. The surface is exactly these five
props — no `…rest`, no `forwardRef` (the component owns its trigger + panel refs for the anchoring floor).

## The enum language

`accent` is a token recipe, not a positional enum: the class `.mx-dropdown--accent-<id>` sets a
custom property `--mx-accent-mark: var(--<ramp>-11)` that the check-mark span reads as
`rgb(var(--mx-accent-mark))` — one accent block per ramp, no per-consumer color. `align` is a
positional enum feeding the floor's `useAnchoredPosition` (`bottom-start` vs `bottom-end`). The panel
is portaled + positioned `position: fixed`, so it escapes any `overflow`/stacking context; the
`.mx-dropdown` surface reads `--bg-elevated` / `--border-secondary` / `--shadow-300` at radius
`--radius-12`.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) (a row's leading glyph + the check
  mark); the trigger is commonly an [IconButton](../../actions/IconButton/IconButton.prompt.md) or a
  [Button](../../actions/Button/Button.prompt.md)'s label.
- **Related:** [Separator](../../foundations/Separator/Separator.prompt.md) (the visual model for a
  `separator` row), [Menubar](../../navigation/Menubar/Menubar.prompt.md) (the horizontal sibling — a
  bar of dropdown-like menus), [Popover](../Popover/Popover.prompt.md) (arbitrary panel content
  rather than a row list), [ContextMenu](../ContextMenu/ContextMenu.prompt.md) (the pointer-anchored
  sibling).
- **Composed by:** net-new this rung — no app call site yet.

## Examples

```tsx
// A user menu — a label, item rows, a toggling check, a separator
<Dropdown
  trigger={<IconButton icon="user" label="Account" />}
  items={[
    { type: "label", label: "Account" },
    { type: "item", label: "Profile", icon: "user", shortcut: "⌘P", onSelect: openProfile },
    { type: "check", id: "notify", label: "Notifications", checked: true, onSelect: toggleNotify },
    { type: "separator" },
    { type: "item", label: "Sign out", icon: "arrow-up-right", onSelect: signOut },
  ]}
/>
// (source-grounded; no app call site)

// End-aligned, a different accent ink
<Dropdown trigger="Filters" accent="green" align="end" width={260} items={filterItems} />
// (source-grounded; no app call site)
```

## Notes

- **Pass content, not a control, as `trigger`** — Dropdown wraps `trigger` in its own `<button
  aria-haspopup="menu" aria-expanded>`, so nesting an interactive element inside is invalid HTML.
  Pass a label or an `Icon`.
- **Dismissal** — an outside press or `Escape` closes it; a press on the trigger is ignored by the
  dismiss floor (so the trigger's `onClick` toggles rather than close-then-reopen).
- **Keyboard** — the panel takes focus on open; `ArrowUp`/`ArrowDown` move between rows (`Home`/`End`
  jump to the ends), skipping `disabled` rows. Focus returns to the trigger on close. Not modal —
  `Tab` may leave the panel.
- **a11y** — the trigger is a real `<button>` with `aria-haspopup="menu"` + `aria-expanded`; the panel
  is `role="menu"`, item rows are `role="menuitem"`, and a `check` row is `role="menuitemcheckbox"`
  with `aria-checked`. A `disabled` row carries `aria-disabled` and is excluded from arrow-nav.
- **React-19 nullable ref** — the anchoring/dismiss floor guards the trigger + panel refs (`null`
  while closed).
