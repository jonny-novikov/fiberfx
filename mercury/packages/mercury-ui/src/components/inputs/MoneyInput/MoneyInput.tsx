import { forwardRef } from "react";
import type { InputHTMLAttributes } from "react";
import { cx } from "@mercury/core";
import { Input } from "../Input";

export interface MoneyInputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, "size"> {
  /** The currency prefix rendered as a leading affix (e.g. `$` or `USD`). */
  currency?: string;
  /** Field label (like Input). */
  label?: string;
  /** Helper text below the field (like Input). */
  hint?: string;
  /** Error text + `aria-invalid` (like Input). */
  error?: string;
}

export const MoneyInput = forwardRef<HTMLInputElement, MoneyInputProps>(function MoneyInput(
  { currency = "$", label, hint, error, inputMode = "decimal", className, ...rest },
  ref,
) {
  return (
    <Input
      ref={ref}
      className={cx("mx-money", className)}
      label={label}
      hint={hint}
      error={error}
      inputMode={inputMode}
      leading={<span className="mx-money__ccy">{currency}</span>}
      {...rest}
    />
  );
});
