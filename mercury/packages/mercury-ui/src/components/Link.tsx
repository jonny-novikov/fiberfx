import type { MouseEvent, ReactNode } from "react";
import { cx } from "../cx";

export type LinkSize = "sm" | "md";

/**
 * Link — the inline text affordance used across forms and flows:
 * "Forgot password?", "Create an account", "Back to sign in", "Resend code".
 * Renders an <a> when `href` is set, otherwise a <button> — so the same brand
 * affordance covers both navigation and in-app actions. Presentational; the
 * caller owns the navigation or click.
 */
export interface LinkProps {
  href?: string;
  onClick?: (e: MouseEvent) => void;
  disabled?: boolean;
  size?: LinkSize;
  /** Muted (tertiary) colour instead of the brand colour. */
  muted?: boolean;
  leading?: ReactNode;
  trailing?: ReactNode;
  type?: "button" | "submit" | "reset";
  target?: string;
  rel?: string;
  className?: string;
  children?: ReactNode;
  "aria-label"?: string;
}

export function Link({
  href,
  onClick,
  disabled = false,
  size = "md",
  muted = false,
  leading,
  trailing,
  type = "button",
  target,
  rel,
  className,
  children,
  "aria-label": ariaLabel,
}: LinkProps) {
  const cls = cx("mx-link", `mx-link--${size}`, muted && "mx-link--muted", disabled && "is-disabled", className);
  const inner = (
    <>
      {leading && <span className="mx-link__icon">{leading}</span>}
      {children != null && <span className="mx-link__lbl">{children}</span>}
      {trailing && <span className="mx-link__icon">{trailing}</span>}
    </>
  );

  if (href !== undefined && !disabled) {
    return (
      <a className={cls} href={href} target={target} rel={rel} onClick={onClick} aria-label={ariaLabel}>
        {inner}
      </a>
    );
  }

  return (
    <button className={cls} type={type} disabled={disabled} onClick={onClick} aria-label={ariaLabel}>
      {inner}
    </button>
  );
}
