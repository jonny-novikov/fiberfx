import type { CSSProperties } from "react";
import { cx } from "@mercury/core";

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
