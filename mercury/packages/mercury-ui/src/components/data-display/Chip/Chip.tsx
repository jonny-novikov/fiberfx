import type { ReactNode } from "react";
import { cx } from "@mercury/core";
import { Icon } from "../../foundations/Icon";

export type ChipVariant = "neutral" | "brand" | "positive" | "negative" | "caution" | "info" | "discovery";
export interface ChipProps {
  children: ReactNode;
  variant?: ChipVariant;
  size?: "sm" | "md" | "lg";
  selected?: boolean;
  leading?: ReactNode;
  onRemove?: () => void;
  onClick?: () => void;
  className?: string;
}

export function Chip({ children, variant = "neutral", size = "md", selected, leading, onRemove, onClick, className }: ChipProps) {
  return (
    <span
      className={cx("mx-chip", `mx-chip--${variant}`, size !== "md" && `mx-chip--${size}`, onClick && "mx-chip--selectable", selected && "is-selected", className)}
      onClick={onClick}
    >
      {leading}
      {children}
      {onRemove && (
        <button
          type="button"
          className="mx-chip__x"
          aria-label="Remove"
          onClick={(e) => {
            e.stopPropagation();
            onRemove();
          }}
        >
          <Icon name="close" size={12} strokeWidth={2.5} />
        </button>
      )}
    </span>
  );
}
