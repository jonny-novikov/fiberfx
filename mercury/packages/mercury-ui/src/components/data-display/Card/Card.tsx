import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export interface CardProps extends Omit<HTMLAttributes<HTMLDivElement>, "title"> {
  variant?: "flat" | "raised" | "floating";
  padding?: number | string;
  title?: ReactNode;
  actions?: ReactNode;
  children?: ReactNode;
}

export function Card({
  variant = "flat",
  padding = 20,
  title,
  actions,
  className,
  style,
  children,
  ...rest
}: CardProps) {
  const hasHeader = title != null || actions != null;
  return (
    <div className={cx("mx-card", variant !== "flat" && `mx-card--${variant}`, className)} style={{ padding, ...style }} {...rest}>
      {hasHeader && (
        <div className="mx-card__header">
          {title != null && <div className="mx-card__title">{title}</div>}
          {actions != null && <div className="mx-card__actions">{actions}</div>}
        </div>
      )}
      {children}
    </div>
  );
}
