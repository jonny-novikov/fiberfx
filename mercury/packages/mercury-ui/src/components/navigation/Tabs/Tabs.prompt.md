# Tabs — the controlled tab strip

A horizontal, controlled set of tabs in two visual variants — `underline` for page-level navigation,
`pills` for a compact view toggle. Generic over the value union (`Tabs<T>`), so the active value is
type-checked. Import: `import { Tabs } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `tabs` | `Tab<T>[]` | — (required) | The tab list. Each `Tab<T>` is `{ label: string; value: T; disabled?: boolean }`. |
| `value` | `T` | — (required) | The active tab's `value` — controlled (the component holds no internal state). |
| `onChange` | `(value: T) => void` | — | Fired with the clicked tab's `value`; a `disabled` tab does not fire. |
| `variant` | `"underline" \| "pills"` | `"underline"` | Visual style (see the enum language). |

`T extends string`. Pass it explicitly (`<Tabs<View> … />`) so `tabs`, `value`, and `onChange` agree on
the union. No `…rest`, no `forwardRef` — the surface is exactly these four props.

## The enum language

`variant` resolves to the `.mx-tabs` token recipe (canon §6):

- `underline` — a flush strip on a `--border-secondary` bottom rule; the active tab takes `--fg-primary`
  text with a `--bg-brand` underline. The default; use it for page-level sections.
- `pills` — a `--bg-secondary` track with the active pill lifted onto `--bg-primary` + `--shadow-100`;
  compact, for an inline view toggle.

## Composition

- **Composes:** nothing — a leaf. It renders its own `role="tab"` buttons; tab labels are plain strings.
- **Composed by:** app shells / pages — the showcase `TabsPage` and the economy `App` main column.
  *(Both are app call sites, not `@mercury/ui` component contracts, so there is no sibling link.)*

## Examples

```tsx
// Underline — page-level sections (controlled)
<Tabs<UnderlineTab>
  tabs={[
    { label: "Overview", value: "overview" },
    { label: "Activity", value: "activity" },
    { label: "Settings", value: "settings" },
    { label: "Billing", value: "billing" },
  ]}
  value={active}
  onChange={setActive}
/>
// showcase/src/pages/components/TabsPage.tsx

// Pills — a compact view toggle
<Tabs<PillTab>
  variant="pills"
  tabs={[
    { label: "Daily", value: "daily" },
    { label: "Weekly", value: "weekly" },
    { label: "Monthly", value: "monthly" },
  ]}
  value={range}
  onChange={setRange}
/>
// showcase/src/pages/components/TabsPage.tsx

// Pills driving a view switch in the economy console
<Tabs<View> tabs={TABS} value={view} onChange={setView} variant="pills" />
// codemojex-node/apps/economy/src/App.tsx
```

## Notes

- **Controlled only** — there is no `defaultValue`; you own `value` and update it in `onChange`. The
  active tab is whichever `tab.value === value`.
- **a11y** — the strip is `role="tablist"`, each button `role="tab"` with `aria-selected`. Tabs does not
  render the panels or wire `aria-controls`; pair it with your own content region (the examples render
  the body beside it).
- A `disabled` tab renders disabled and is inert — its click neither toggles nor calls `onChange`.
- Type the union and pass it explicitly (`Tabs<View>`); otherwise `T` widens to `string` and you lose
  the value-checking that is the point of the generic.
