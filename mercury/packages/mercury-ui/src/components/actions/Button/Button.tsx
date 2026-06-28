import { forwardRef } from "react";
import type { ButtonHTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type ButtonVariant =
  | "primary"
  | "secondary"
  | "outline"
  | "ghost"
  | "destructive"
  | "inverse";
export type ButtonSize = "sm" | "md" | "lg";

export interface ButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "type"> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  /** Swap the label for a spinner and disable interaction. */
  loading?: boolean;
  /** Stretch to the container width. */
  fullWidth?: boolean;
  /** Element rendered before the label (usually an `<Icon />`). */
  leading?: ReactNode;
  /** Element rendered after the label. */
  trailing?: ReactNode;
  type?: "button" | "submit" | "reset";
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = "primary", size = "md", loading = false, fullWidth = false, leading, trailing, type = "button", className, children, disabled, ...rest },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      className={cx("mx-btn", `mx-btn--${variant}`, `mx-btn--${size}`, fullWidth && "is-full", className)}
      {...rest}
    >
      {loading ? (
        <span className="mx-btn__spin" aria-hidden="true" />
      ) : leading ? (
        <span className="mx-btn__icon">{leading}</span>
      ) : null}
      {children != null && <span className="mx-btn__lbl">{children}</span>}
      {trailing && !loading ? <span className="mx-btn__icon mx-btn__icon--trail">{trailing}</span> : null}
    </button>
  );
});
