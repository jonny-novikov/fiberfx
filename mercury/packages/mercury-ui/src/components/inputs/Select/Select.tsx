import { forwardRef, useId } from "react";
import type { SelectHTMLAttributes } from "react";
import { cx } from "@mercury/core";

export interface SelectOption {
  label: string;
  value: string;
  disabled?: boolean;
}

export interface SelectProps extends Omit<SelectHTMLAttributes<HTMLSelectElement>, "size"> {
  label?: string;
  hint?: string;
  error?: string;
  options: SelectOption[];
  placeholder?: string;
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select(
  { label, hint, error, options, placeholder, id, className, required, disabled, ...rest },
  ref,
) {
  const uid = useId();
  const fieldId = id ?? uid;
  const msg = error || hint;
  return (
    <label htmlFor={fieldId} className={cx("mx-sl", error && "mx-sl--err", disabled && "mx-sl--dis", className)}>
      {label && (
        <span className="mx-sl__lbl">
          {label}
          {required && <span className="mx-sl__req"> *</span>}
        </span>
      )}
      <div className="mx-sl__field">
        <select
          ref={ref}
          id={fieldId}
          className="mx-sl__sel"
          aria-invalid={error ? "true" : undefined}
          required={required}
          disabled={disabled}
          {...rest}
        >
          {placeholder && (
            <option value="" disabled hidden>
              {placeholder}
            </option>
          )}
          {options.map((o) => (
            <option key={o.value} value={o.value} disabled={o.disabled}>
              {o.label}
            </option>
          ))}
        </select>
        <span className="mx-sl__chev" aria-hidden="true" />
      </div>
      {msg && <span className={cx("mx-sl__msg", error && "mx-sl__msg--err")}>{msg}</span>}
    </label>
  );
});
