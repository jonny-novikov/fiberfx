import { cx } from "@mercury/core";

export type ProgressVariant = "brand" | "positive" | "negative" | "caution" | "info";
export interface ProgressProps {
  value?: number;
  max?: number;
  variant?: ProgressVariant;
  size?: "sm" | "md" | "lg";
  indeterminate?: boolean;
}

export function Progress({ value = 0, max = 100, variant = "brand", size = "md", indeterminate = false }: ProgressProps) {
  const pct = indeterminate ? 0 : Math.min(100, Math.max(0, (value / max) * 100));
  return (
    <div
      className={cx("mx-pr", `mx-pr--${size}`, `mx-pr--${variant}`, indeterminate && "is-indet")}
      role="progressbar"
      aria-valuenow={indeterminate ? undefined : Math.round(pct)}
      aria-valuemin={0}
      aria-valuemax={100}
    >
      <div className="mx-pr__track">
        <div className="mx-pr__bar" style={indeterminate ? undefined : { width: `${pct}%` }} />
      </div>
    </div>
  );
}
