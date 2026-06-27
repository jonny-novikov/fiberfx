import type { ReactNode } from "react";
import { cx } from "../cx";

/* ───────── Alert ───────── */
export type AlertTone = "info" | "success" | "warning" | "danger";
const GLYPH: Record<AlertTone, string> = { info: "i", success: "✓", warning: "!", danger: "×" };

export interface AlertProps {
  tone?: AlertTone;
  title?: ReactNode;
  children?: ReactNode;
  dismissible?: boolean;
  onDismiss?: () => void;
  actions?: ReactNode;
}

export function Alert({ tone = "info", title, children, dismissible, onDismiss, actions }: AlertProps) {
  return (
    <div className={cx("mx-alt", `mx-alt--${tone}`)} role={tone === "danger" ? "alert" : "status"}>
      <span className="mx-alt__icon" aria-hidden="true">
        {GLYPH[tone]}
      </span>
      <div className="mx-alt__body">
        {title && <h4 className="mx-alt__h">{title}</h4>}
        {children && <div className="mx-alt__msg">{children}</div>}
        {actions && <div className="mx-alt__actions">{actions}</div>}
      </div>
      {dismissible && (
        <button className="mx-alt__x" type="button" aria-label="Dismiss" onClick={onDismiss}>
          ×
        </button>
      )}
    </div>
  );
}

/* ───────── Progress ───────── */
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
