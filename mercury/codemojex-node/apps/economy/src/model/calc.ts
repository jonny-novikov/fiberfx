/*
 * Codemojex revenue model — the pure, deterministic calc engine.
 *
 * All money is USD-canonical (number, dollars). `diamondsPerUsd` is a PARAMETER
 * everywhere it matters — never a hidden constant (the new direction is 10💎=$1,
 * i.e. $0.10/💎; the as-built echo `economy.ex` @cents_per_diamond 1.2 is stale).
 *
 * Discipline (mirrors echo `economy.ex` + the cm.6 one-floor-complement law):
 *   - `floor` applies ONLY to integer diamonds (poolDiamonds) and the WAC cost-out;
 *   - `houseUsd` is the COMPLEMENT (guessValue − poolUsd) so the floor residue always
 *     accrues to the house — never double-floored;
 *   - guards return 0 / no-op on a collapsed denominator (keys=0, guessValue=0).
 *
 * No Date/Math.random — every output is a pure function of its inputs.
 */

import { PACKAGES, STAR_USD, IN_GAME_DIAMONDS_PER_KEY } from "./packages";

export type ModelParams = {
  /** 10💎 = $1 → 10. The locked diamond price. */
  diamondsPerUsd: number;
  /** Average key price (USD) — the weighted-average gross cost basis per key. */
  akp: number;
  /** Keys consumed per guess (default 5). */
  guessFee: number;
  /** Fraction of the guess value routed to the prize pool, 0..1 (default 0.70). */
  poolPortion: number;
  /** Store fee on a mobile pay-in (~0.32). */
  storeFeeMobile: number;
  /** Store fee on a desktop/web pay-in (~0.03). */
  storeFeeDesktop: number;
  /** Size the pool off the gross akp (default) or the net akp (after store fee). */
  splitBasis: "gross" | "net";
};

export interface SplitResult {
  /** akp × guessFee — the GROSS cost basis consumed by one guess. */
  guessValue: number;
  /** The akp the pool is sized from (gross akp, or net akp when splitBasis==="net"). */
  basisAkp: number;
  /** floor(basisAkp × guessFee × poolPortion × diamondsPerUsd) — whole diamonds. */
  poolDiamonds: number;
  /** poolDiamonds / diamondsPerUsd. */
  poolUsd: number;
  /** guessValue − poolUsd — the one-floor complement (residue accrues here). */
  houseUsd: number;
  /** houseUsd / guessValue (0 when guessValue===0). */
  housePct: number;
}

/**
 * The per-guess split, with an explicit net-basis reference fee.
 * When splitBasis==="gross" the fee is ignored (basisAkp = akp).
 * When splitBasis==="net" the pool is sized off akp × (1 − netRefFee).
 */
export function splitWith(p: ModelParams, netRefFee: number): SplitResult {
  const basisAkp = p.splitBasis === "net" ? p.akp * (1 - netRefFee) : p.akp;
  const guessValue = p.akp * p.guessFee; // gross cost basis consumed — always off gross akp
  const poolDiamonds = Math.floor(basisAkp * p.guessFee * p.poolPortion * p.diamondsPerUsd);
  const poolUsd = poolDiamonds / p.diamondsPerUsd;
  const houseUsd = guessValue - poolUsd;
  const housePct = guessValue > 0 ? houseUsd / guessValue : 0;
  return { guessValue, basisAkp, poolDiamonds, poolUsd, houseUsd, housePct };
}

/**
 * The canonical split used by the headline KPIs, the prize pool and conservation.
 * Gross ignores the fee; net sizes the pool off the WORST-CASE (mobile) net basis,
 * so the single canonical pool is conservative across channels.
 */
export function split(p: ModelParams): SplitResult {
  return splitWith(p, p.storeFeeMobile);
}

// ───────── Package ladder ─────────

export interface PackageRow {
  keys: number;
  stars: number;
  akp: number;
}

/** akp from a package: stars × $0.013 / keys (0 when keys===0). */
export function packageAkp(stars: number, keys: number): number {
  return keys > 0 ? (stars * STAR_USD) / keys : 0;
}

/** The 7-rung ladder with akp precomputed. */
export function packageLadder(): PackageRow[] {
  return PACKAGES.map(({ keys, stars }) => ({ keys, stars, akp: packageAkp(stars, keys) }));
}

// ───────── The store-fee margin squeeze ─────────

export interface MarginRow {
  channel: "mobile" | "desktop";
  storeFee: number;
  /** guessValue × (1 − storeFee). */
  netReceived: number;
  /** poolUsd — the pool liability fixed by the canonical split. */
  poolOwed: number;
  /** netReceived − poolOwed — the squeeze; can go NEGATIVE (loss). */
  margin: number;
  /** margin / guessValue — the PINNED denominator (yields +1.3% / +30.3%). */
  squeezePct: number;
  /** margin < 0 — the §8 divergence / loss flag. */
  negative: boolean;
}

/** [mobile, desktop] margins against the single canonical pool (a fixed 2-tuple). */
export function marginByStore(p: ModelParams): [MarginRow, MarginRow] {
  const s = split(p);
  const row = (channel: MarginRow["channel"], storeFee: number): MarginRow => {
    const netReceived = s.guessValue * (1 - storeFee);
    const poolOwed = s.poolUsd;
    const margin = netReceived - poolOwed;
    const squeezePct = s.guessValue > 0 ? margin / s.guessValue : 0;
    return { channel, storeFee, netReceived, poolOwed, margin, squeezePct, negative: margin < 0 };
  };
  return [row("mobile", p.storeFeeMobile), row("desktop", p.storeFeeDesktop)];
}

// ───────── Prize pool (N players × G guesses) ─────────

export interface PrizePoolResult {
  players: number;
  guessesEach: number;
  totalGuesses: number;
  poolDiamonds: number;
  poolUsd: number;
  houseUsd: number;
  grossConsumed: number;
  spendPerPlayerKeys: number;
  spendPerPlayerUsd: number;
  /** The winner takes the whole pool. */
  winnerTakesUsd: number;
  /** poolDiamonds / 10 — the winner's keys at the in-game 10💎=1key rate. */
  winnerTakesKeysInGame: number;
}

export function prizePool(p: ModelParams, players: number, guessesEach: number): PrizePoolResult {
  const s = split(p);
  const totalGuesses = players * guessesEach;
  const poolDiamonds = totalGuesses * s.poolDiamonds;
  const poolUsd = poolDiamonds / p.diamondsPerUsd;
  const houseUsd = totalGuesses * s.houseUsd;
  const grossConsumed = totalGuesses * s.guessValue;
  const spendPerPlayerKeys = guessesEach * p.guessFee;
  const spendPerPlayerUsd = spendPerPlayerKeys * p.akp;
  return {
    players,
    guessesEach,
    totalGuesses,
    poolDiamonds,
    poolUsd,
    houseUsd,
    grossConsumed,
    spendPerPlayerKeys,
    spendPerPlayerUsd,
    winnerTakesUsd: poolUsd,
    winnerTakesKeysInGame: Math.floor(poolDiamonds / IN_GAME_DIAMONDS_PER_KEY),
  };
}

// ───────── Conservation identity ─────────

export interface Conservation {
  grossConsumed: number;
  poolLiability: number;
  houseRealized: number;
  /** gross − (pool + house) — ≈ 0; shown for trust. */
  residual: number;
  balanced: boolean;
}

const EPS = 1e-9;

export function conservation(pp: PrizePoolResult): Conservation {
  const grossConsumed = pp.grossConsumed;
  const poolLiability = pp.poolUsd;
  const houseRealized = pp.houseUsd;
  const residual = grossConsumed - (poolLiability + houseRealized);
  return { grossConsumed, poolLiability, houseRealized, residual, balanced: Math.abs(residual) < EPS };
}

// ───────── WAC balance simulator ─────────

export interface WacState {
  keys: number;
  /** TOTAL cost basis of the current balance, canonical USD. */
  basisUsd: number;
}

/** Buy B keys at total cost C: pure addition, no division → no acquisition dust. */
export function wacBuy(s: WacState, addKeys: number, costUsd: number): WacState {
  if (addKeys <= 0) return s;
  return { keys: s.keys + addKeys, basisUsd: s.basisUsd + Math.max(0, costUsd) };
}

/**
 * Spend S of K keys: cost_out = floor(basis × S / K), basis −= cost_out, keys −= S.
 * Floored in µUSD to mirror the integer cost-basis discipline; the remainder stays
 * on `basisUsd` and washes to 0 on spend-all. Guards keys=0 (no-op).
 */
export function wacSpend(s: WacState, spendKeys: number): { next: WacState; costOut: number } {
  if (s.keys <= 0 || spendKeys <= 0) return { next: s, costOut: 0 };
  const spend = Math.min(spendKeys, s.keys);
  const costOut = Math.floor(((s.basisUsd * spend) / s.keys) * 1e6) / 1e6;
  return { next: { keys: s.keys - spend, basisUsd: Math.max(0, s.basisUsd - costOut) }, costOut };
}

/** Weighted-average cost per key, derived at read (0 when keys===0). */
export function wac(s: WacState): number {
  return s.keys > 0 ? s.basisUsd / s.keys : 0;
}
