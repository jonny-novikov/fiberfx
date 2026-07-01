import { forwardRef, useState } from "react";
import type { ButtonHTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type ToggleSize = "sm" | "md" | "lg";

export interface ToggleProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "onChange"> {
  /** Controlled pressed state. Omit for uncontrolled. */
  pressed?: boolean;
  defaultPressed?: boolean;
  onPressedChange?: (pressed: boolean) => void;
  size?: ToggleSize;
}

/** A single two-state pressable control (e.g. a bold/italic formatting toggle). */
export const Toggle = forwardRef<HTMLButtonElement, ToggleProps>(function Toggle(
  { pressed, defaultPressed = false, onPressedChange, size = "md", className, children, disabled, onClick, ...rest },
  ref,
) {
  const [internal, setInternal] = useState(defaultPressed);
  const isOn = pressed ?? internal;
  return (
    <button
      ref={ref}
      type="button"
      disabled={disabled}
      aria-pressed={isOn}
      className={cx("mx-tgl", `mx-tgl--${size}`, isOn && "is-on", className)}
      onClick={(e) => {
        if (pressed == null) setInternal((v) => !v);
        onPressedChange?.(!isOn);
        onClick?.(e);
      }}
      {...rest}
    >
      {children}
    </button>
  );
});

export type ToggleGroupType = "single" | "multiple";

export interface ToggleGroupItem {
  value: string;
  label?: ReactNode;
  icon?: ReactNode;
  disabled?: boolean;
  /** Accessible name when the item is icon-only. */
  ariaLabel?: string;
}

export interface ToggleGroupProps {
  items: ToggleGroupItem[];
  /** "single" (default) = one active value; "multiple" = a set. */
  type?: ToggleGroupType;
  value?: string | string[];
  defaultValue?: string | string[];
  onValueChange?: (value: string | string[]) => void;
  size?: ToggleSize;
  /** Recolors the on-state of every item; omit for the neutral fill. */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  /** Disables every item (composes with per-item `disabled`). */
  disabled?: boolean;
  className?: string;
}

function toArr(v: string | string[] | undefined): string[] {
  if (v == null) return [];
  return Array.isArray(v) ? v : v ? [v] : [];
}

/** A bordered row of toggles behaving as a single- or multiple-select group. */
export function ToggleGroup({
  items,
  type = "single",
  value,
  defaultValue,
  onValueChange,
  size = "md",
  accent,
  disabled,
  className,
}: ToggleGroupProps) {
  const [internal, setInternal] = useState<string[]>(() => toArr(defaultValue));
  const controlled = value != null;
  const sel = controlled ? toArr(value) : internal;

  const commit = (next: string[]) => {
    if (!controlled) setInternal(next);
    onValueChange?.(type === "multiple" ? next : next[0] ?? "");
  };
  const onItem = (v: string) => {
    const on = sel.includes(v);
    if (type === "multiple") commit(on ? sel.filter((x) => x !== v) : [...sel, v]);
    else commit(on ? [] : [v]);
  };

  return (
    <div className={cx("mx-tgl-grp", `mx-tgl-grp--${size}`, accent && `mx-tgl-grp--accent-${accent}`, className)} role="group">
      {items.map((it) => {
        const on = sel.includes(it.value);
        return (
          <button
            key={it.value}
            type="button"
            disabled={disabled || it.disabled}
            aria-label={it.ariaLabel}
            aria-pressed={on}
            className={cx("mx-tgl", "mx-tgl--grouped", `mx-tgl--${size}`, on && "is-on")}
            onClick={() => onItem(it.value)}
          >
            {it.icon && <span className="mx-tgl__icon">{it.icon}</span>}
            {it.label}
          </button>
        );
      })}
    </div>
  );
}
