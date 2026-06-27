/**
 * passwordStrength — a pure scorer for password fields. Pairs with the
 * <PasswordStrength /> meter and <Checklist /> in @mercury/ui: feed `score` /
 * `label` / `variant` to the meter and `rules` to the checklist.
 */
export type StrengthVariant = "negative" | "caution" | "positive";

export interface PasswordRules {
  length: boolean;
  mixedCase: boolean;
  number: boolean;
  symbol: boolean;
}

export interface PasswordStrengthResult {
  /** 0–100. */
  score: number;
  /** "" while empty, else Weak / Fair / Strong. */
  label: "" | "Weak" | "Fair" | "Strong";
  variant: StrengthVariant;
  rules: PasswordRules;
}

export function passwordStrength(password: string): PasswordStrengthResult {
  const rules: PasswordRules = {
    length: password.length >= 8,
    mixedCase: /[a-z]/.test(password) && /[A-Z]/.test(password),
    number: /[0-9]/.test(password),
    symbol: /[^a-zA-Z0-9]/.test(password),
  };

  let score = 0;
  if (rules.length) score += 34;
  if (rules.mixedCase) score += 33;
  if (rules.number || rules.symbol) score += 33;
  score = Math.min(100, score);

  const label: PasswordStrengthResult["label"] =
    password.length === 0 ? "" : score < 40 ? "Weak" : score < 75 ? "Fair" : "Strong";
  const variant: StrengthVariant = score < 40 ? "negative" : score < 75 ? "caution" : "positive";

  return { score, label, variant, rules };
}
