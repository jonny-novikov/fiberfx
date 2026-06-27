import { forwardRef, useId } from "react";
import type { InputHTMLAttributes, ReactNode, TextareaHTMLAttributes } from "react";
import { cx } from "../cx";
import { Icon } from "./Icon";

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

export interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  hint?: string;
  error?: string;
  resizable?: boolean;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(function Textarea(
  { label, hint, error, resizable = false, id, className, rows = 4, maxLength, value, required, disabled, ...rest },
  ref,
) {
  const uid = useId();
  const fieldId = id ?? uid;
  const count = typeof value === "string" ? value.length : 0;
  const msg = error || hint;
  return (
    <label htmlFor={fieldId} className={cx("mx-ta", error && "mx-ta--err", disabled && "mx-ta--dis", className)}>
      {label && (
        <span className="mx-ta__lbl">
          {label}
          {required && <span className="mx-ta__req" aria-hidden="true"> *</span>}
        </span>
      )}
      <div className={cx("mx-ta__field", resizable && "is-resize")}>
        <textarea
          ref={ref}
          id={fieldId}
          className="mx-ta__inp"
          rows={rows}
          maxLength={maxLength}
          value={value}
          aria-invalid={error ? "true" : undefined}
          required={required}
          disabled={disabled}
          {...rest}
        />
      </div>
      <div className="mx-ta__foot">
        {msg ? <span className={cx("mx-ta__msg", error && "mx-ta__msg--err")}>{msg}</span> : <span />}
        {maxLength != null && (
          <span className={cx("mx-ta__count", count >= maxLength && "is-over")}>
            {count}/{maxLength}
          </span>
        )}
      </div>
    </label>
  );
});

export interface SearchProps extends Omit<InputHTMLAttributes<HTMLInputElement>, "onChange"> {
  value: string;
  onChange?: (value: string) => void;
  onSearch?: (value: string) => void;
}

export function Search({ value, onChange, onSearch, placeholder = "Search", className, disabled, ...rest }: SearchProps) {
  return (
    <label className={cx("mx-sr", disabled && "mx-sr--dis", className)}>
      <span className="mx-sr__icon">
        <Icon name="search" size={14} />
      </span>
      <input
        className="mx-sr__inp"
        type="search"
        value={value}
        placeholder={placeholder}
        disabled={disabled}
        onChange={(e) => onChange?.(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter") onSearch?.(value);
          else if (e.key === "Escape") onChange?.("");
        }}
        {...rest}
      />
      {value && !disabled && (
        <button type="button" className="mx-sr__x" aria-label="Clear" onClick={() => onChange?.("")}>
          ×
        </button>
      )}
    </label>
  );
}
