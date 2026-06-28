import type { ReactNode } from "react";
import { cx } from "@mercury/core";

/*
 * Stat — a KPI / metric tile. A standalone token-styled box (label, big mono
 * value, optional tone-colored delta + hint + leading icon). Both Mercury
 * dashboards hand-rolled this from Card; promoted here as a reusable primitive.
 */

export type StatTone = "neutral" | "positive" | "negative" | "caution" | "brand" | "info";

export interface StatProps {
  label: string;
  /** Formatted by the caller (renders in DM Mono via .mx-stat__value). */
  value: ReactNode;
  /** Optional delta chip, e.g. "+30.3%". */
  delta?: ReactNode;
  deltaTone?: StatTone;
  /** Sub-caption under the value. */
  hint?: ReactNode;
  /** Optional leading icon. */
  leading?: ReactNode;
  align?: "left" | "center";
}

export function Stat({ label, value, delta, deltaTone = "neutral", hint, leading, align = "left" }: StatProps) {
  return (
    <div className={cx("mx-stat", align === "center" && "mx-stat--center")}>
      <div className="mx-stat__head">
        {leading && <span className="mx-stat__icon">{leading}</span>}
        <span className="mx-stat__label">{label}</span>
      </div>
      <div className="mx-stat__value">{value}</div>
      {(delta || hint) && (
        <div className="mx-stat__foot">
          {delta && <span className={cx("mx-stat__delta", `mx-stat__delta--${deltaTone}`)}>{delta}</span>}
          {hint && <span className="mx-stat__hint">{hint}</span>}
        </div>
      )}
    </div>
  );
}
