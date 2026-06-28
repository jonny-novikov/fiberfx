import type { ReactNode } from "react";
import { cx } from "@mercury/core";

export type BadgeVariant = "brand" | "negative" | "positive" | "caution" | "info";
export interface BadgeProps {
  children: ReactNode;
  variant?: BadgeVariant;
  size?: "sm" | "md" | "lg";
}
export function Badge({ children, variant = "negative", size = "md" }: BadgeProps) {
  return <span className={cx("mx-badge", `mx-badge--${variant}`, size !== "md" && `mx-badge--${size}`)}>{children}</span>;
}
