import { useEffect, useRef } from "react";
import type { CSSProperties, ReactNode } from "react";
import { cx } from "../cx";

/* ───────── Checkbox ───────── */
export interface CheckboxProps {
  checked?: boolean;
  onChange?: (checked: boolean) => void;
  label?: ReactNode;
  indeterminate?: boolean;
  disabled?: boolean;
  name?: string;
  value?: string;
  id?: string;
}

export function Checkbox({ checked = false, onChange, label, indeterminate = false, disabled, name, value, id }: CheckboxProps) {
  const ref = useRef<HTMLInputElement>(null);
  useEffect(() => {
    if (ref.current) ref.current.indeterminate = indeterminate;
  }, [indeterminate]);
  return (
    <label className={cx("mx-cb", disabled && "mx-cb--dis")} htmlFor={id}>
      <input
        ref={ref}
        id={id}
        type="checkbox"
        name={name}
        value={value}
        checked={checked}
        disabled={disabled}
        onChange={(e) => onChange?.(e.target.checked)}
      />
      <span className="mx-cb__box" aria-hidden="true">
        {indeterminate ? (
          <svg viewBox="0 0 12 12" width="12" height="12">
            <path d="M3 6h6" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          </svg>
        ) : checked ? (
          <svg viewBox="0 0 12 12" width="12" height="12">
            <path d="M2.5 6.2l2.3 2.3L9.5 3.8" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        ) : null}
      </span>
      {label != null && <span className="mx-cb__lbl">{label}</span>}
    </label>
  );
}

/* ───────── Radio ───────── */
export interface RadioProps {
  checked?: boolean;
  onChange?: (value: string) => void;
  label?: ReactNode;
  value: string;
  name?: string;
  disabled?: boolean;
  id?: string;
}

export function Radio({ checked = false, onChange, label, value, name, disabled, id }: RadioProps) {
  return (
    <label className={cx("mx-rd", disabled && "mx-rd--dis")} htmlFor={id}>
      <input
        id={id}
        type="radio"
        name={name}
        value={value}
        checked={checked}
        disabled={disabled}
        onChange={() => onChange?.(value)}
      />
      <span className="mx-rd__ring" aria-hidden="true">
        <span className="mx-rd__dot" />
      </span>
      {label != null && <span className="mx-rd__lbl">{label}</span>}
    </label>
  );
}

/* ───────── Switch ───────── */
export interface SwitchProps {
  checked?: boolean;
  onChange?: (checked: boolean) => void;
  label?: ReactNode;
  disabled?: boolean;
  name?: string;
  id?: string;
}

export function Switch({ checked = false, onChange, label, disabled, name, id }: SwitchProps) {
  return (
    <label className={cx("mx-sw", !checked && "mx-sw--off", disabled && "mx-sw--dis")} htmlFor={id}>
      <input
        id={id}
        type="checkbox"
        role="switch"
        name={name}
        checked={checked}
        disabled={disabled}
        onChange={(e) => onChange?.(e.target.checked)}
      />
      <span className="mx-sw__track" aria-hidden="true">
        <span className="mx-sw__thumb" />
      </span>
      {label != null && <span className="mx-sw__lbl">{label}</span>}
    </label>
  );
}

/* ───────── Segmented ───────── */
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

/* ───────── Slider ───────── */
export interface SliderProps {
  value: number;
  onChange?: (value: number) => void;
  min?: number;
  max?: number;
  step?: number;
  label?: string;
  unit?: string;
  showValue?: boolean;
  size?: "sm" | "md";
  disabled?: boolean;
}

export function Slider({ value, onChange, min = 0, max = 100, step = 1, label, unit = "", showValue = true, size = "md", disabled }: SliderProps) {
  const pct = ((value - min) / (max - min)) * 100;
  return (
    <div className={cx("mx-sd", `mx-sd--${size}`, disabled && "mx-sd--dis")}>
      {(label || showValue) && (
        <div className="mx-sd__head">
          {label && <span className="mx-sd__lbl">{label}</span>}
          {showValue && (
            <span className="mx-sd__val">
              {value}
              {unit}
            </span>
          )}
        </div>
      )}
      <div className="mx-sd__track" style={{ "--mx-pct": `${pct}%` } as CSSProperties}>
        <input
          className="mx-sd__inp"
          type="range"
          min={min}
          max={max}
          step={step}
          value={value}
          disabled={disabled}
          onChange={(e) => onChange?.(Number(e.target.value))}
        />
      </div>
    </div>
  );
}
