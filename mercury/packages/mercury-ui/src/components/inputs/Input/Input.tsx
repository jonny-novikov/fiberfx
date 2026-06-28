import { forwardRef, useId } from "react";
import type { InputHTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export interface InputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, "size"> {
  label?: string;
  hint?: string;
  error?: string;
  leading?: ReactNode;
  trailing?: ReactNode;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { label, hint, error, leading, trailing, id, className, required, disabled, ...rest },
  ref,
) {
  const uid = useId();
  const fieldId = id ?? uid;
  const msg = error || hint;
  return (
    <label htmlFor={fieldId} className={cx("mx-in", error && "mx-in--err", disabled && "mx-in--dis", className)}>
      {label && (
        <span className="mx-in__lbl">
          {label}
          {required && <span className="mx-in__req" aria-hidden="true"> *</span>}
        </span>
      )}
      <span className="mx-in__field">
        {leading && <span className="mx-in__aff mx-in__aff--lead">{leading}</span>}
        <input
          ref={ref}
          id={fieldId}
          className="mx-in__inp"
          aria-invalid={error ? "true" : undefined}
          required={required}
          disabled={disabled}
          {...rest}
        />
        {trailing && <span className="mx-in__aff mx-in__aff--trail">{trailing}</span>}
      </span>
      {msg && <span className={cx("mx-in__msg", error && "mx-in__msg--err")}>{msg}</span>}
    </label>
  );
});
