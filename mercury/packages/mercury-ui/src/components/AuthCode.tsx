import { useRef } from "react";
import { cx } from "../cx";

export interface AuthCodeProps {
  value: string;
  onChange: (value: string) => void;
  onComplete?: (value: string) => void;
  length?: number;
  allow?: "numeric" | "alphanumeric";
  error?: string;
  disabled?: boolean;
}

export function AuthCode({ value, onChange, onComplete, length = 6, allow = "numeric", error, disabled }: AuthCodeProps) {
  const refs = useRef<Array<HTMLInputElement | null>>([]);
  const pattern = allow === "numeric" ? /[^0-9]/g : /[^a-zA-Z0-9]/g;
  const chars = Array.from({ length }, (_, i) => value[i] ?? "");

  const setAt = (i: number, ch: string) => {
    const arr = chars.slice();
    arr[i] = ch;
    const next = arr.join("").slice(0, length);
    onChange(next);
    if (next.length === length) onComplete?.(next);
  };

  return (
    <div className={cx("mx-auth", error && "mx-auth--err", disabled && "mx-auth--dis")}>
      <div className="mx-auth__row">
        {chars.map((c, i) => (
          <input
            key={i}
            ref={(el) => {
              refs.current[i] = el;
            }}
            className="mx-auth__cell"
            type="text"
            inputMode={allow === "numeric" ? "numeric" : "text"}
            maxLength={1}
            value={c}
            disabled={disabled}
            aria-label={`Digit ${i + 1}`}
            onChange={(e) => {
              const clean = e.target.value.replace(pattern, "").slice(-1);
              setAt(i, clean);
              if (clean && i < length - 1) refs.current[i + 1]?.focus();
            }}
            onKeyDown={(e) => {
              if (e.key === "Backspace" && !chars[i] && i > 0) {
                e.preventDefault();
                refs.current[i - 1]?.focus();
                setAt(i - 1, "");
              }
            }}
            onPaste={(e) => {
              const text = (e.clipboardData.getData("text") || "").replace(pattern, "");
              if (!text) return;
              e.preventDefault();
              const next = text.slice(0, length);
              onChange(next);
              refs.current[Math.min(text.length, length - 1)]?.focus();
              if (next.length === length) onComplete?.(next);
            }}
          />
        ))}
      </div>
      {error && <div className="mx-auth__msg">{error}</div>}
    </div>
  );
}
