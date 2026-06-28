# Checklist — a met / unmet requirements list

A list of criteria, each rendered with a met (`✓`) or unmet (`○`) marker. Reach for it for password
rules, onboarding steps, or any "criteria satisfied" UI driven by booleans. Import:
`import { Checklist } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | `ChecklistItem[]` | — (required) | The requirements, in display order. |
| `className` | `string` | — | Extra class merged onto the root `<ul>`. |

**`ChecklistItem`** — `{ label: ReactNode; met: boolean }`: `label` is the requirement text; `met`
toggles the `is-met` row state and the `✓` / `○` marker.

The component takes **no other `…rest`** and is **not** `forwardRef` — it is a plain styled `<ul>`.

## The enum language

No enum props. The met/unmet state is a `boolean` per item (`is-met` class), not a token variant; the
marker color follows the row's met state from the component's own `.mx-checklist` styles.

## Composition

- **Composes:** nothing — a leaf. Each item is a marker glyph plus its `label` node; it embeds no other
  Mercury component.
- **Composed by:** [AuthLayout](../../layout/AuthLayout/AuthLayout.prompt.md) — the reset-password
  screen lists its rules through a Checklist; it pairs with
  [PasswordStrength](../../feedback/PasswordStrength/PasswordStrength.prompt.md) on the password flow.
  *(Sibling contracts authored across mx.2; links resolve at set completion.)*

## Examples

```tsx
// Live password rules on the reset screen
<Checklist
  items={[
    { label: "8+ characters", met: rules.length },
    { label: "Upper & lower case", met: rules.mixedCase },
    { label: "A number", met: rules.number },
  ]}
/>
// showcase/src/pages/patterns/AuthFlowPage.tsx
```

## Notes

- **Presentational** — Checklist computes nothing; the caller derives each `met` boolean (here from a
  `rules` object) and passes the finished list.
- The marker is `aria-hidden` (decorative `✓` / `○`) — the requirement text is the accessible content,
  so keep `label` self-describing.
- Items key by index, so the list is meant for a stable, ordered set of rules — not a reorderable one.
