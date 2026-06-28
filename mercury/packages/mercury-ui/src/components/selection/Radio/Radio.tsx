import type { ReactNode } from "react";
import { cx } from "@mercury/core";

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
