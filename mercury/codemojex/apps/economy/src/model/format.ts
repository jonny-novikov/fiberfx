/* Display helpers — pure formatting, no model logic. Numbers render in DM Mono. */

export const usd = (n: number, dp = 2): string => `$${n.toFixed(dp)}`;
export const dia = (n: number): string => `${n}💎`;
export const pct = (n: number, dp = 1): string => `${(n * 100).toFixed(dp)}%`;
export const keys = (n: number): string => `${n} keys`;

/** Signed USD with 3dp — for the margin squeeze (e.g. "+$0.010", "−$0.05"). */
export const signedUsd = (n: number): string => `${n >= 0 ? "+" : "−"}$${Math.abs(n).toFixed(3)}`;

/** Signed percent — for the squeeze read (e.g. "+1.3%", "−4.0%"). */
export const signedPct = (n: number): string => `${n >= 0 ? "+" : "−"}${Math.abs(n * 100).toFixed(1)}%`;
