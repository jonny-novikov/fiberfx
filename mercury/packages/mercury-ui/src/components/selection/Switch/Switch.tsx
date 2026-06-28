import type { ReactNode } from "react";
import { cx } from "@mercury/core";

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
