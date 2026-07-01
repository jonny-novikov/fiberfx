import { forwardRef, useId } from "react";
import type { TextareaHTMLAttributes } from "react";
import { cx } from "@mercury/core";

export interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  hint?: string;
  error?: string;
  resizable?: boolean;
  size?: "sm" | "md" | "lg";
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(function Textarea(
  { label, hint, error, resizable = false, size = "md", id, className, rows = 4, maxLength, value, required, disabled, ...rest },
  ref,
) {
  const uid = useId();
  const fieldId = id ?? uid;
  const count = typeof value === "string" ? value.length : 0;
  const msg = error || hint;
  return (
    <label htmlFor={fieldId} className={cx("mx-ta", `mx-ta--${size}`, error && "mx-ta--err", disabled && "mx-ta--dis", className)}>
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
