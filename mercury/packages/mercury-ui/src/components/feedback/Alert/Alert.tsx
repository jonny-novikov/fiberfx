import type { ReactNode } from "react";
import { cx } from "@mercury/core";

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
