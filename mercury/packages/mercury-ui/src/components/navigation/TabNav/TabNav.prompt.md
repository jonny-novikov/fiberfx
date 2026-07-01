# TabNav — link-styled navigation tabs

A `<nav>` of `<a aria-current="page">` anchors sharing an underline rail — the tab bar for page-level
navigation (Overview · Activity · Settings). Distinct from [Tabs](../Tabs/Tabs.prompt.md): TabNav
**navigates** (each tab is a real link with an `href`; the active tab is the current *page*), where Tabs
switches in-page panels. Controlled + presentational. Import: `import { TabNav } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `TabNavItem[]` | — (required) | The tabs in order. |
| `value` | `string` | — (required) | The active tab's `value` (controlled). |
| `onChange` | `(value: string) => void` | — | Notified with the clicked tab's `value` (a disabled tab is inert). |
| `size` | `TabNavSize` (`"sm" \| "md"`) | `"md"` | Density: `sm` = 36px row, `md` = 44px row. |

### `TabNavItem`

| Field | Type | Notes |
|---|---|---|
| `value` | `string` | Stable id; matched against `value` to mark the active tab. |
| `label` | `ReactNode` | The visible label. |
| `href` | `string?` | Navigation target. Omitted → a non-navigating tab (driven by `onChange`); a disabled tab renders no `href`. |
| `disabled` | `boolean?` | Dimmed + non-interactive (`aria-disabled`, `preventDefault`, no `onChange`). |

## The enum language

`size` is the sole visual enum — `sm`/`md` scale the row height, padding, and font size; there is no
`accent`. The active tab reads `--bg-brand` for its underline and `--fg-primary` at `--fw-semi-bold`;
resting tabs read `--fg-secondary` at `--fw-medium`, hovering to `--bg-hover`. The `:focus-visible` ring
reads `--border-focus` + `--ring-focus`.

## Composition

- **Composes:** its own `<a>` anchors — no child components (labels are `ReactNode`).
- **Related:** [Tabs](../Tabs/Tabs.prompt.md) — in-page panel switching (link-navigation vs
  panel-selection); [Pagination](../Pagination/Pagination.prompt.md) — sequential page navigation;
  [Menubar](../Menubar/Menubar.prompt.md) — command menus.
- **Composed by:** net-new this rung — no app call site yet.

## Examples

```tsx
// A page tab bar (controlled by the router's active segment)
<TabNav
  items={[
    { value: "overview", label: "Overview", href: "/team/overview" },
    { value: "activity", label: "Activity", href: "/team/activity" },
    { value: "settings", label: "Settings", href: "/team/settings" },
  ]}
  value={segment}
  onChange={(v) => navigate(`/team/${v}`)}
/>
// (source-grounded; no app call site)

// Compact, with a disabled tab
<TabNav size="sm" value="general" items={[
  { value: "general", label: "General", href: "#general" },
  { value: "billing", label: "Billing", disabled: true },
]} />
// (source-grounded; no app call site)
```

## Notes

- **Link-navigation, not panel-switching** — each tab is a real `<a href>`; the active tab is the current
  page (`aria-current="page"`), not a selected panel. Reach for `Tabs` to switch in-page content.
- **Controlled** — `value` is required; the component holds no internal state. `onChange` fires on a
  non-disabled click; a disabled tab calls `preventDefault` and does not notify.
- **Focus ring restored** — the source prototype set `outline: none`, an a11y regression; TabNav restores
  a `:focus-visible` ring so keyboard focus paints a visible outline + ring (precondition: keyboard focus
  → postcondition: a visible ring).
- **a11y** — the active anchor carries `aria-current="page"`; a disabled tab carries `aria-disabled` and
  renders no `href` (removed from the tab sequence).
