import { CalendarDateTime, Time, ZonedDateTime } from "@internationalized/date";
import type { TimeValue } from "#shared/date/types.js";

/**
 * Normalize a {@link TimeValue} to a date-bearing value the `Intl` formatters
 * can consume. A bare `Time` has no date, so it is anchored to a fixed sentinel
 * day (2020-01-01) — only the time parts are ever read back out.
 *
 * This lives as a standalone leaf (rather than in `field/time-helpers`) so the
 * formatter can depend on it without pulling in the whole date-field surface.
 */
export function convertTimeValueToDateValue(time: TimeValue): CalendarDateTime | ZonedDateTime {
	if (time instanceof Time) {
		return new CalendarDateTime(2020, 1, 1, time.hour, time.minute, time.second, time.millisecond);
	}
	return time;
}
