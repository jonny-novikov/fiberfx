import { forwardRef } from "react";
import type { ButtonHTMLAttributes } from "react";
import { cx } from "@mercury/core";
import { Icon } from "../../foundations/Icon";
import type { IconName } from "../../foundations/Icon";

export type IconButtonVariant = "primary" | "secondary" | "outline" | "ghost" | "destructive";
export type IconButtonSize = "sm" | "md" | "lg";
export type IconButtonShape = "circle" | "square";

export interface IconButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "type"> {
  /** The icon glyph name (from the `Icon` set). */
  icon: IconName;
  /** Required accessible name — there is no visible text. Becomes `aria-label` + `title`. */
  label: string;
  variant?: IconButtonVariant;
  size?: IconButtonSize;
  /** Mercury icon buttons are fully round by default. */
  shape?: IconButtonShape;
  type?: "button" | "submit" | "reset";
}

// Icon glyph px per control size.
const ICON_PX: Record<IconButtonSize, number> = { sm: 16, md: 18, lg: 20 };

/**
 * IconButton — a square/round button carrying only an icon. It reuses the Button token
 * surface (`.mx-btn--<variant>`) for fill/ink and adds the `.mx-icon-btn` square-box
 * geometry; `shape="circle"` is `--radius-full`. The required `label` becomes the
 * `aria-label` (icon-only controls need an accessible name).
 */
export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(function IconButton(
  { icon, label, variant = "secondary", size = "md", shape = "circle", type = "button", className, ...rest },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      className={cx(
        "mx-icon-btn",
        `mx-btn--${variant}`,
        `mx-icon-btn--${size}`,
        `mx-icon-btn--${shape}`,
        className,
      )}
      {...rest}
      aria-label={label}
      title={label}
    >
      <Icon name={icon} size={ICON_PX[size]} />
    </button>
  );
});

export default IconButton;
