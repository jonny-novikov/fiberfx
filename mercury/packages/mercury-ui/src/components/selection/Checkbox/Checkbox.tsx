import { useEffect, useRef } from "react";
import type { ReactNode } from "react";
import { cx } from "@mercury/core";

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
