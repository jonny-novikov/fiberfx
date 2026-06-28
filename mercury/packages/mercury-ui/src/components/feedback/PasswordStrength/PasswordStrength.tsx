import { cx } from "@mercury/core";
import { Progress } from "#components/feedback/Progress/index.js";
import type { ProgressVariant } from "#components/feedback/Progress/index.js";

/**
 * PasswordStrength — a labelled strength meter for a password field.
 * Presentational: pass a `score` (0–100), `label` and `variant` — the
 * `passwordStrength()` helper in @mercury/effector computes all three.
 */
export type StrengthVariant = "negative" | "caution" | "positive";

export interface PasswordStrengthProps {
  score: number;
  label?: string;
  variant?: StrengthVariant;
  className?: string;
}

const TO_PROGRESS: Record<StrengthVariant, ProgressVariant> = {
  negative: "negative",
  caution: "caution",
  positive: "positive",
};

export function PasswordStrength({ score, label, variant = "negative", className }: PasswordStrengthProps) {
  return (
    <div className={cx("mx-pwstr", className)}>
      <Progress value={score} variant={TO_PROGRESS[variant]} size="sm" />
      {label && <span className={cx("mx-pwstr__lbl", `mx-pwstr__lbl--${variant}`)}>{label}</span>}
    </div>
  );
}
