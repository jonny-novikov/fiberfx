/*
 * Codemojex economy — package ladder + pay-in rails (pure constants).
 *
 * Grounded in docs/codemojex/specs/economy/economy.packages.md:
 *   - the star → USD cost basis is ~$0.013/star (the desktop/web payout),
 *   - the ladder discounts the PRICE PAID, never the booked gross,
 *   - Telegram fixes Stars at 200 per TON.
 * No Date/random — these are static reference data.
 */

/** Star → USD cost basis ($13 per 1,000 stars). */
export const STAR_USD = 0.013;

/** In-game convert rate: 10 diamonds = 1 key (echo `@diamonds_per_key 10`). */
export const IN_GAME_DIAMONDS_PER_KEY = 10;

export interface Package {
  keys: number;
  stars: number;
}

/** The 7-rung package ladder (keys ← stars), 5-pack … 1000-pack. */
export const PACKAGES: Package[] = [
  { keys: 5, stars: 99 },
  { keys: 15, stars: 249 },
  { keys: 50, stars: 799 },
  { keys: 100, stars: 1449 },
  { keys: 200, stars: 2599 },
  { keys: 500, stars: 5499 },
  { keys: 1000, stars: 9999 },
];

export type RailId = "stars" | "ton" | "usdt" | "rub";

export interface Rail {
  id: RailId;
  label: string;
  /** The frozen minor unit name (Codemojex.Rails). */
  minor: string;
  /** factor == 10**decimals (minor units per whole unit). */
  factor: number;
  /** Pinned-on-order rate → canonical USD per whole unit. */
  usdPerUnit: number;
}

/**
 * The four pay-in rails. Only `stars` and `ton` are canon-pinned
 * (200⭐ = 1 TON); `usdt`/`rub` rates are illustrative defaults the
 * Operator can re-pin. Everything normalizes to ONE canonical USD basis.
 */
export const RAILS: Rail[] = [
  { id: "stars", label: "Stars", minor: "star", factor: 1, usdPerUnit: STAR_USD },
  { id: "ton", label: "TON", minor: "nanoTON", factor: 1e9, usdPerUnit: 200 * STAR_USD },
  { id: "usdt", label: "USDT", minor: "microUSDT", factor: 1e6, usdPerUnit: 1 },
  { id: "rub", label: "RUB", minor: "kopeck", factor: 100, usdPerUnit: 0.011 },
];
