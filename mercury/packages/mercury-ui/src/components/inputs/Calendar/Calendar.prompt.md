# Calendar

A month-grid day picker — paged by month, one day selectable. The presentational
`@mercury/ui` home over `@mercury/core`'s `useCalendar` (grid, month paging, and value
model); the month-nav chevrons are the live `Icon`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `DateValue` | — | Controlled selected day (a `DateValue` from `@mercury/core`). |
| `defaultValue` | `DateValue` | — | Initial selected day when uncontrolled. |
| `onChange` | `(value: DateValue) => void` | — | Fires when a day is chosen. |
| `locale` | `string` | `"en"` | BCP-47 locale for labels + week order. |
| `firstDayOfWeek` | `number` | `0` | First column of the week, `0`=Sun..`6`=Sat. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` | — | Selected-day fill + today ring from an accent ramp. |
| `className` | `string` | — | Appended to the root class. |

## The enum language

`accent` selects the ramp colour bound to the `--mx-cal-accent` custom property
(`--<id>-9`): `iris` (the default when `accent` is unset), `indigo`, `green`, `orange`,
`plum`, `red`. That one token drives both the **selected-day fill** (a solid background on
the chosen day) and the **today ring** (an inset 1px ring on the current day when it is not
also the selected day). The class is `.mx-calendar--accent-<id>`.

## Composition

- `../DateField/DateField.prompt.md` — the typed half of the date pair: keyboard entry to
  the same `DateValue` model this grid selects.
- `../../overlay/Popover` — *(forward-tense, mx.7.4)* pairs the field + this grid into a
  single date-picker.
- `../../foundations/Icon/Icon.prompt.md` — the month-nav chevron (`chevron-right`; the
  prev control is the same glyph flipped in CSS).

## Examples

```tsx
// Uncontrolled, opening on a given month
<Calendar defaultValue={parseDate("2024-03-15")} />

// Accent ramp
<Calendar accent="indigo" defaultValue={parseDate("2024-03-15")} />

// Controlled
const [date, setDate] = useState<DateValue | undefined>(new CalendarDate(2024, 3, 15));
<Calendar value={date} onChange={setDate} accent="green" />;
```

## Notes

- **INV-6** — date types cross through `@mercury/core` (`DateValue`, `CalendarDate`,
  `parseDate`); `@internationalized/date` is never imported in `@mercury/ui`.
- The prev-month control reuses the `chevron-right` glyph rotated 180° in CSS — no
  `chevron-left` glyph exists in the icon set.
- Controlled through `value`; uncontrolled through `defaultValue` — the `useCalendar` value
  model owns the switch between the two.
- The accent is class-driven (`.mx-calendar--accent-<id>`), themed through CSS with no
  inline style.
- Day-grid arrow-key roving is out of this batch: the day cells are clickable and the
  month-nav buttons are tabbable.
