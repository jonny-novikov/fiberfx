import type { ReactNode } from "react";
import { cx } from "../cx";

/**
 * Divider — a separator rule. With a `label` it becomes the "— or —" splitter
 * used between a primary and an alternate action (e.g. email vs. SSO sign-in).
 */
export interface DividerProps {
  label?: ReactNode;
  orientation?: "horizontal" | "vertical";
  className?: string;
}

export function Divider({ label, orientation = "horizontal", className }: DividerProps) {
  if (orientation === "vertical") {
    return <span className={cx("mx-divider mx-divider--v", className)} role="separator" aria-orientation="vertical" />;
  }
  if (label != null) {
    return (
      <div className={cx("mx-divider mx-divider--label", className)} role="separator">
        <span className="mx-divider__line" />
        <span className="mx-divider__lbl">{label}</span>
        <span className="mx-divider__line" />
      </div>
    );
  }
  return <hr className={cx("mx-divider", className)} />;
}
