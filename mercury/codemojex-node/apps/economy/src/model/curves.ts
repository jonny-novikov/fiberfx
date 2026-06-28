/*
 * Curve geometry — pure SVG path/scale builders, no React (echomq `data.ts`
 * discipline). The <Chart> primitive is geometry-dumb; it renders what these
 * functions precompute. viewBox units throughout; no Date/random.
 */

import type { ModelParams } from "./calc";
import { split } from "./calc";

const VIEW_W = 1000;
const VIEW_H = 300;
export const VIEW_BOX = `0 0 ${VIEW_W} ${VIEW_H}`;

/** domain [d0,d1] → x in [0, VIEW_W]. */
const sx = (t: number, d0: number, d1: number): number => (d1 === d0 ? 0 : ((t - d0) / (d1 - d0)) * VIEW_W);
/** value [vmin,vmax] → y in [VIEW_H, 0] (inverted: bigger value = higher). */
const sy = (v: number, vmin: number, vmax: number): number =>
  vmax === vmin ? VIEW_H : VIEW_H - ((v - vmin) / (vmax - vmin)) * VIEW_H;

const linePath = (pts: [number, number][]): string =>
  pts.map(([x, y], i) => `${i ? "L" : "M"}${x.toFixed(1)} ${y.toFixed(1)}`).join(" ");
const areaPath = (pts: [number, number][]): string => `${linePath(pts)} L${VIEW_W} ${VIEW_H} L0 ${VIEW_H} Z`;
/** n+1 horizontal grid-line y positions, evenly spaced. */
const gridY = (n = 5): number[] => Array.from({ length: n + 1 }, (_, i) => (i / n) * VIEW_H);

export interface CurveSeries {
  d: string;
  area?: string;
  stroke: string;
  fillId?: string;
  width?: number;
  dashed?: boolean;
}

export interface CurveGeom {
  viewBox: string;
  series: CurveSeries[];
  gridY: number[];
  yTicks: string[];
  xTicks: string[];
  gradients?: { id: string; stroke: string }[];
  /** Margin curve only: the y of the zero (loss) boundary, drawn as a marker. */
  zeroY?: number;
  ariaLabel: string;
}

/** Curve 1 — house% of each guess vs average key price (sweep akp $0.01→$0.40). */
export function buildHousePctCurve(p: ModelParams): CurveGeom {
  const A0 = 0.01;
  const A1 = 0.4;
  const STEPS = 80;
  const pts: [number, number][] = [];
  for (let i = 0; i <= STEPS; i++) {
    const akp = A0 + (A1 - A0) * (i / STEPS);
    const hp = split({ ...p, akp }).housePct; // 0..1
    pts.push([sx(akp, A0, A1), sy(hp, 0, 1)]);
  }
  return {
    viewBox: VIEW_BOX,
    gridY: gridY(5),
    series: [{ d: linePath(pts), area: areaPath(pts), stroke: "rgb(var(--iris-9))", fillId: "houseGrad" }],
    gradients: [{ id: "houseGrad", stroke: "rgb(var(--iris-9))" }],
    yTicks: ["100%", "80%", "60%", "40%", "20%", "0%"],
    xTicks: ["$0.01", "$0.10", "$0.20", "$0.30", "$0.40"],
    ariaLabel: "House percentage of each guess as the average key price rises",
  };
}

/** Curve 2 — Operator margin vs pool portion (mobile + desktop), with a zero-loss line. */
export function buildMarginCurve(p: ModelParams): CurveGeom {
  const STEPS = 100;
  const gv = p.akp * p.guessFee;
  const range = gv > 0 ? gv : 1; // symmetric ±guessValue (guard akp=0)
  const mob: [number, number][] = [];
  const desk: [number, number][] = [];
  for (let i = 0; i <= STEPS; i++) {
    const portion = i / STEPS;
    const s = split({ ...p, poolPortion: portion });
    const mMob = s.guessValue * (1 - p.storeFeeMobile) - s.poolUsd;
    const mDesk = s.guessValue * (1 - p.storeFeeDesktop) - s.poolUsd;
    mob.push([sx(portion, 0, 1), sy(mMob, -range, range)]);
    desk.push([sx(portion, 0, 1), sy(mDesk, -range, range)]);
  }
  return {
    viewBox: VIEW_BOX,
    gridY: gridY(4),
    series: [
      { d: linePath(desk), stroke: "rgb(var(--green-9))", width: 2.5 }, // desktop (low fee) — healthier
      { d: linePath(mob), stroke: "rgb(var(--orange-9))", width: 2.5 }, // mobile (high fee) — squeezed
    ],
    zeroY: sy(0, -range, range), // === VIEW_H / 2 — the loss boundary
    yTicks: [`+$${range.toFixed(2)}`, `+$${(range / 2).toFixed(2)}`, "$0.00", `−$${(range / 2).toFixed(2)}`, `−$${range.toFixed(2)}`],
    xTicks: ["0%", "25%", "50%", "75%", "100%"],
    ariaLabel: "Operator margin versus pool-funding portion, mobile and desktop",
  };
}

/** Curve 3 — prize-pool diamonds accumulated vs total guesses (linear ramp 0→N×G). */
export function buildPoolGrowth(p: ModelParams, totalGuesses: number): CurveGeom {
  const s = split(p);
  const T1 = Math.max(1, totalGuesses);
  const STEPS = 60;
  const poolMax = T1 * s.poolDiamonds || 1;
  const pts: [number, number][] = [];
  for (let i = 0; i <= STEPS; i++) {
    const tg = (T1 * i) / STEPS;
    pts.push([sx(tg, 0, T1), sy(tg * s.poolDiamonds, 0, poolMax)]);
  }
  return {
    viewBox: VIEW_BOX,
    gridY: gridY(5),
    series: [{ d: linePath(pts), area: areaPath(pts), stroke: "rgb(var(--indigo-9))", fillId: "poolGrad" }],
    gradients: [{ id: "poolGrad", stroke: "rgb(var(--indigo-9))" }],
    yTicks: [`${poolMax}💎`, "", "", "", "", "0💎"],
    xTicks: ["0", "", `${Math.round(T1 / 2)}`, "", `${T1}`],
    ariaLabel: "Prize-pool diamonds accumulated versus total guesses",
  };
}
