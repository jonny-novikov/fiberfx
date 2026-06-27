import type { CSSProperties, ReactNode } from "react";
import { cx } from "../cx";
import { Icon } from "./Icon";

/* ───────── Chip ───────── */
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

/* ───────── Tag (chip with a status dot) ───────── */
export interface TagProps {
  children: ReactNode;
  tone?: ChipVariant;
  dot?: boolean;
  size?: "sm" | "md" | "lg";
}
export function Tag({ children, tone = "neutral", dot = true, size = "sm" }: TagProps) {
  return (
    <Chip variant={tone} size={size} leading={dot ? <span style={{ width: 6, height: 6, borderRadius: "50%", background: "currentColor" }} /> : undefined}>
      {children}
    </Chip>
  );
}

/* ───────── Badge (count pill) ───────── */
export type BadgeVariant = "brand" | "negative" | "positive" | "caution" | "info";
export interface BadgeProps {
  children: ReactNode;
  variant?: BadgeVariant;
  size?: "sm" | "md" | "lg";
}
export function Badge({ children, variant = "negative", size = "md" }: BadgeProps) {
  return <span className={cx("mx-badge", `mx-badge--${variant}`, size !== "md" && `mx-badge--${size}`)}>{children}</span>;
}

/* ───────── Avatar ───────── */
export type AvatarStatus = "positive" | "caution" | "negative" | "info";
export interface AvatarProps {
  name?: string;
  src?: string;
  size?: number;
  status?: AvatarStatus;
}

const HUES = ["--iris-9", "--indigo-9", "--green-9", "--orange-9", "--plum-9", "--red-9"];

export function Avatar({ name = "", src, size = 40, status }: AvatarProps) {
  const initials = name
    .split(" ")
    .map((w) => w[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();
  const hash = [...name].reduce((a, c) => a + c.charCodeAt(0), 0);
  const bg = HUES[hash % HUES.length];
  const imgStyle: CSSProperties = {
    background: src ? "rgb(var(--bg-tertiary))" : `rgb(var(${bg}))`,
    fontSize: Math.round(size * 0.38),
  };
  const dot = Math.round(size * 0.28);
  return (
    <span className="mx-avatar" style={{ width: size, height: size }}>
      <span className="mx-avatar__img" style={imgStyle}>
        {src ? <img src={src} alt={name} /> : initials}
      </span>
      {status && <span className="mx-avatar__status" style={{ width: dot, height: dot, background: `rgb(var(--bg-${status}))` }} />}
    </span>
  );
}
