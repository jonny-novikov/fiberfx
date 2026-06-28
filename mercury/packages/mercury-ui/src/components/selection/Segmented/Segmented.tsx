import { cx } from "@mercury/core";

export interface Segment<T extends string> {
  label: string;
  value: T;
  disabled?: boolean;
}
export interface SegmentedProps<T extends string> {
  segments: Segment<T>[];
  value: T;
  onChange?: (value: T) => void;
  size?: "sm" | "md" | "lg";
  fullWidth?: boolean;
}

export function Segmented<T extends string>({ segments, value, onChange, size = "md", fullWidth = false }: SegmentedProps<T>) {
  return (
    <div className={cx("mx-seg", `mx-seg--${size}`, fullWidth && "is-full")} role="radiogroup">
      {segments.map((s) => (
        <button
          key={s.value}
          type="button"
          role="radio"
          aria-checked={s.value === value}
          disabled={s.disabled}
          className={cx("mx-seg__seg", s.value === value && "is-active")}
          onClick={() => !s.disabled && onChange?.(s.value)}
        >
          {s.label}
        </button>
      ))}
    </div>
  );
}
