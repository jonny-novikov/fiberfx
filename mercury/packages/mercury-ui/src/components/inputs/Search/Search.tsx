import type { InputHTMLAttributes } from "react";
import { cx } from "@mercury/core";
import { Icon } from "#components/foundations/Icon/index.js";

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
