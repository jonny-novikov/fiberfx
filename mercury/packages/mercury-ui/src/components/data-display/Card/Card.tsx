import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: "flat" | "raised" | "floating";
  padding?: number | string;
  children?: ReactNode;
}

export function Card({ variant = "flat", padding = 20, className, style, children, ...rest }: CardProps) {
  return (
    <div className={cx("mx-card", variant !== "flat" && `mx-card--${variant}`, className)} style={{ padding, ...style }} {...rest}>
      {children}
    </div>
  );
}
