import { useCallback, useMemo, useState } from "react";
import {
  type DateValue,
  getLocalTimeZone,
  isSameDay,
  today,
} from "@internationalized/date";
import { createFormatter } from "#internal/date-time/formatter.js";
import { getLastFirstDayOfWeek, toDate } from "#internal/date-time/utils.js";

/** Options for {@link useCalendar}. */
export type UseCalendarOptions = {
  /** Controlled selected day. */
  value?: DateValue;
  /** Uncontrolled initial selected day. */
  defaultValue?: DateValue;
  /** Fires when a day is chosen. */
  onChange?: (value: DateValue) => void;
  /** BCP-47 locale for the month/weekday labels + week ordering. Default "en". */
  locale?: string;
  /** First column of the week, 0=Sun .. 6=Sat. Default 0. */
  firstDayOfWeek?: number;
};

/** Props spread onto a single day cell. */
export interface CalendarCellProps {
  role: "gridcell";
  "aria-selected": boolean;
  "aria-label": string;
  tabIndex: number;
  onClick: () => void;
}

/** One rendered day in the month grid. */
export interface CalendarCell {
  date: DateValue;
  label: string;
  isSelected: boolean;
  isToday: boolean;
  isOutsideMonth: boolean;
  cellProps: CalendarCellProps;
}

/** Props for a prev/next month navigation control. */
export interface CalendarNavProps {
  onClick: () => void;
  "aria-label": string;
}

/** Return shape of {@link useCalendar}. */
export interface UseCalendarReturn {
  /** Localized "month year" header, e.g. "March 2024". */
  monthLabel: string;
  /** Seven localized weekday headers, in `firstDayOfWeek` order. */
  weekdays: string[];
  /** The 42 grid cells (6 weeks) for the visible month. */
  cells: CalendarCell[];
  /** Props for the grid container. */
  gridProps: { role: "grid"; "aria-label": string };
  /** The current selected value (controlled or uncontrolled). */
  selected: DateValue | undefined;
  /** Props for the previous-month control. */
  prevButtonProps: CalendarNavProps;
  /** Props for the next-month control. */
  nextButtonProps: CalendarNavProps;
}

const GRID_CELLS = 42; // six weeks

/**
 * Headless month-grid calendar composable. Composes the owned `internal/date-time`
 * machinery (locale formatter, week alignment, value conversion) over
 * `@internationalized/date` values; the only new logic is the grid assembly and
 * month paging. Presentational-ready: spread the cell/nav prop kits.
 */
export function useCalendar(options: UseCalendarOptions = {}): UseCalendarReturn {
  const { value, defaultValue, onChange, locale = "en", firstDayOfWeek = 0 } = options;
  const isControlled = value !== undefined;

  const [internalSelected, setInternalSelected] = useState<DateValue | undefined>(defaultValue);
  const selected = isControlled ? value : internalSelected;

  // The displayed month: first-of-month of the seed (selected / default / today).
  const [visibleMonth, setVisibleMonth] = useState<DateValue>(
    () => (value ?? defaultValue ?? today(getLocalTimeZone())).set({ day: 1 }),
  );

  const formatter = useMemo(() => createFormatter({ locale }), [locale]);
  const todayDate = useMemo(() => today(getLocalTimeZone()), []);

  const monthLabel = useMemo(
    () => formatter.fullMonthAndYear(toDate(visibleMonth)),
    [formatter, visibleMonth],
  );

  const gridStart = useMemo(
    () => getLastFirstDayOfWeek(visibleMonth.set({ day: 1 }), firstDayOfWeek, locale),
    [visibleMonth, firstDayOfWeek, locale],
  );

  const weekdays = useMemo<string[]>(
    () =>
      Array.from({ length: 7 }, (_, i) =>
        formatter.dayOfWeek(toDate(gridStart.add({ days: i })), "short"),
      ),
    [formatter, gridStart],
  );

  const select = useCallback(
    (date: DateValue) => {
      if (!isControlled) setInternalSelected(date);
      onChange?.(date);
    },
    [isControlled, onChange],
  );

  const cells = useMemo<CalendarCell[]>(
    () =>
      Array.from({ length: GRID_CELLS }, (_, i) => {
        const date = gridStart.add({ days: i });
        const isSelected = selected != null && isSameDay(date, selected);
        return {
          date,
          label: String(date.day),
          isSelected,
          isToday: isSameDay(date, todayDate),
          isOutsideMonth: date.month !== visibleMonth.month,
          cellProps: {
            role: "gridcell" as const,
            "aria-selected": isSelected,
            "aria-label": formatter.selectedDate(date, false),
            tabIndex: isSelected ? 0 : -1,
            onClick: () => select(date),
          },
        };
      }),
    [gridStart, selected, todayDate, visibleMonth, formatter, select],
  );

  return {
    monthLabel,
    weekdays,
    cells,
    gridProps: { role: "grid", "aria-label": monthLabel },
    selected,
    prevButtonProps: {
      onClick: () => setVisibleMonth((m) => m.subtract({ months: 1 })),
      "aria-label": "Previous month",
    },
    nextButtonProps: {
      onClick: () => setVisibleMonth((m) => m.add({ months: 1 })),
      "aria-label": "Next month",
    },
  };
}
