import { cx, useCalendar } from "@mercury/core";
import type { DateValue } from "@mercury/core";
import { Icon } from "../../foundations/Icon";

export interface CalendarProps {
  /** Controlled selected day (a DateValue from @mercury/core). */
  value?: DateValue;
  /** Initial selected day when uncontrolled. */
  defaultValue?: DateValue;
  /** Fires when a day is chosen. */
  onChange?: (value: DateValue) => void;
  /** BCP-47 locale for labels + week order (default "en"). */
  locale?: string;
  /** First column of the week, 0=Sun..6=Sat (default 0). */
  firstDayOfWeek?: number;
  /** Selected-day fill + today ring from an accent ramp. */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  className?: string;
}

/**
 * Calendar — a month-grid day picker. The grid, month paging, and value model
 * come from @mercury/core's useCalendar (over the owned internal/date-time
 * machinery); this is the presentational @mercury/ui home. INV-6: date types
 * cross through @mercury/core, never @internationalized/date directly. The nav
 * chevrons are the live Icon (chevron-right; the prev control is flipped in CSS).
 */
export function Calendar({
  value,
  defaultValue,
  onChange,
  locale,
  firstDayOfWeek,
  accent,
  className,
}: CalendarProps) {
  const { monthLabel, weekdays, cells, gridProps, prevButtonProps, nextButtonProps } =
    useCalendar({ value, defaultValue, onChange, locale, firstDayOfWeek });
  return (
    <div className={cx("mx-calendar", accent && `mx-calendar--accent-${accent}`, className)}>
      <div className="mx-calendar__header">
        <button type="button" className="mx-calendar__nav mx-calendar__nav--prev" {...prevButtonProps}>
          <Icon name="chevron-right" />
        </button>
        <span className="mx-calendar__title">{monthLabel}</span>
        <button type="button" className="mx-calendar__nav mx-calendar__nav--next" {...nextButtonProps}>
          <Icon name="chevron-right" />
        </button>
      </div>
      <div className="mx-calendar__weekdays" aria-hidden="true">
        {weekdays.map((w, i) => (
          <span key={i} className="mx-calendar__weekday">
            {w}
          </span>
        ))}
      </div>
      <div {...gridProps} className="mx-calendar__days">
        {cells.map((cell) => (
          <button
            key={cell.date.toString()}
            type="button"
            {...cell.cellProps}
            className={cx(
              "mx-calendar__day",
              cell.isSelected && "mx-calendar__day--selected",
              cell.isToday && "mx-calendar__day--today",
              cell.isOutsideMonth && "mx-calendar__day--outside",
            )}
          >
            {cell.label}
          </button>
        ))}
      </div>
    </div>
  );
}
