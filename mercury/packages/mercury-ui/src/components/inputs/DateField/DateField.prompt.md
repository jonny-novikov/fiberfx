# DateField — the segmented date entry

A labeled, segmented `mm/dd/yyyy` date field: each part (month, day, year) is its own spinbutton
segment, edited with digits and arrow keys, separated by locale-aware literals. Reach for it whenever a
date is typed inline (a due date, a date of birth, a filter bound). The value model, segment list, and
keyboard arithmetic are owned by `@mercury/core`'s `useDateField`; this component is the presentational
`@mercury/ui` home that renders it. Import: `import { DateField } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `DateValue` | — | Controlled value (a `DateValue` from `@mercury/core`). Omit / pass `undefined` for uncontrolled. |
| `defaultValue` | `DateValue` | — | Initial value when uncontrolled. |
| `onChange` | `(value: DateValue \| undefined) => void` | — | Fires on each committed segment edit; receives `undefined` when the field is cleared. |
| `label` | `ReactNode` | — | Label rendered above the segmented field. |
| `locale` | `string` | `"en"` | BCP-47 locale; orders the segments and picks the literal separators (resolved by the hook). |
| `disabled` | `boolean` | — | Fades the field and blocks entry. |
| `className` | `string` | — | Merged onto the `<label>` wrapper via `cx`. |

## The enum language

DateField carries **no enum props** — it has a single visual form, so there is no `variant`/`size`/`tone`
vocabulary. Tokens it styles through: box `--bg-primary` on `--border-primary`, shifting to
`--border-focus` with a 3px `--ring-focus` ring on `:focus-within`; glyphs in `--font-secondary` (DM
Mono), the label in `--font-primary` (DM Sans 500); separators in `--fg-tertiary`; radius `--radius-8`.

## Composition

- **Composes:** `@mercury/core`'s `useDateField` — the headless hook supplies `segments`, `fieldProps`,
  and `segmentProps`; this component renders them and owns no date logic.
- **Pairs with:** [Calendar](../Calendar/Calendar.prompt.md) — the month-grid pointer picker (shipped
  **mx.7.3.2**); DateField is the typed text entry, Calendar the pointer-driven one.
- **Sibling:** [Input](../Input/Input.prompt.md) — the single-line free-text field; DateField is its
  date-typed analog (a segmented value instead of a raw string).

## Examples

```tsx
// Uncontrolled — seeded from an ISO string
import { DateField } from "@mercury/ui";
import { parseDate } from "@mercury/core";

<DateField label="Due date" defaultValue={parseDate("2024-03-15")} />
```

```tsx
// Controlled — a CalendarDate held in component state
import { useState } from "react";
import { DateField } from "@mercury/ui";
import { CalendarDate } from "@mercury/core";
import type { DateValue } from "@mercury/core";

function BirthdayField() {
  const [date, setDate] = useState<DateValue | undefined>(new CalendarDate(2024, 3, 15));
  return <DateField label="Date of birth" value={date} onChange={setDate} />;
}
```

## Notes

- **Per-segment ARIA bounds are derived by the hook, not passed in.** `useDateField` emits
  `aria-valuemin`/`aria-valuemax` per segment (month `1–12`, day `1–getDaysInMonth(month, year)`, year
  `1–9999`) alongside `aria-valuenow`; the originating bundle carried only `aria-valuenow`, so the
  bounds are an `@mercury/core` enrichment, not a literal port.
- **The value model lives in `@mercury/core`.** All date arithmetic (segment increment/decrement,
  month-length clamping, parse/format) is the hook's responsibility, built over the owned
  `internal/date-time` machinery (the mx.7.3.1 A2 ruling, arm (a)) — `@mercury/ui` adds presentation
  only.
- **INV-6 — date types cross through `@mercury/core`.** `DateValue`, `CalendarDate`, and `parseDate` are
  imported from `@mercury/core`; `@mercury/ui` never imports `@internationalized/date` directly.
- **Controlled vs uncontrolled.** A controlled `value` must be a `DateValue`; passing `value={undefined}`
  reverts the field to uncontrolled (the React convention, matching the bundle's optional-not-nullable
  API — `value` is omittable, never explicitly `null`).
- **Accessibility.** The segments live inside a `role="group"` field container (carried by
  `fieldProps`), wrapped in the `<label>`, so the label associates with the group without extra wiring.
  Each editable segment is a read-only `<input>` whose value the hook drives via its key handler.
