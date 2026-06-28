/*
 * Revenue-flow geometry — three stacked bars, each scaled to the GROSS guess
 * value, showing where one guess's money goes:
 *   1. Gross                       (akp × guessFee)
 *   2. After store fee → Net | Store fee
 *   3. Net split      → Pool | Margin   (Margin red + flagged when negative)
 * Pure; the <RevenueFlow> component renders the rects/labels these produce.
 */

import type { SplitResult } from "./calc";

const VIEW_W = 1000;
const LEFT = 10;
const BAR_W = VIEW_W - LEFT * 2;
const PAD_TOP = 8;
const TITLE_H = 22;
const ROW_H = 46;
const ROW_GAP = 16;
const ROW_STRIDE = TITLE_H + ROW_H + ROW_GAP;

export interface FlowSeg {
  label: string;
  usd: number;
  x: number;
  w: number;
  fill: string;
  negative?: boolean;
}

export interface FlowRow {
  title: string;
  total: number;
  barY: number;
  segs: FlowSeg[];
}

export interface FlowGeom {
  viewBox: string;
  rowH: number;
  rows: FlowRow[];
  grossUsd: number;
  storeFeeUsd: number;
  netUsd: number;
  poolUsd: number;
  marginUsd: number;
  marginNegative: boolean;
}

const C = {
  gross: "rgb(var(--slate-9))",
  net: "rgb(var(--indigo-9))",
  fee: "rgb(var(--red-9))",
  pool: "rgb(var(--iris-9))",
  margin: "rgb(var(--green-9))",
  deficit: "rgb(var(--red-9))",
};

export function buildFlow(s: SplitResult, channelFee: number): FlowGeom {
  const gross = s.guessValue;
  const storeFeeUsd = gross * channelFee;
  const netUsd = gross - storeFeeUsd;
  const poolUsd = s.poolUsd;
  const marginUsd = netUsd - poolUsd;
  const marginNegative = marginUsd < 0;

  // usd → px (scaled to gross; guard gross=0).
  const X = (usd: number): number => LEFT + (gross > 0 ? (usd / gross) * BAR_W : 0);
  const W = (usd: number): number => (gross > 0 ? (usd / gross) * BAR_W : 0);
  const barY = (i: number): number => PAD_TOP + i * ROW_STRIDE + TITLE_H;

  const rows: FlowRow[] = [
    {
      title: "Gross — keys consumed",
      total: gross,
      barY: barY(0),
      segs: [{ label: "Gross", usd: gross, x: X(0), w: W(gross), fill: C.gross }],
    },
    {
      title: "After store fee",
      total: gross,
      barY: barY(1),
      segs: [
        { label: "Net received", usd: netUsd, x: X(0), w: W(netUsd), fill: C.net },
        { label: "Store fee", usd: storeFeeUsd, x: X(netUsd), w: W(storeFeeUsd), fill: C.fee, negative: true },
      ],
    },
    {
      title: "Net split → pool + margin",
      total: netUsd,
      barY: barY(2),
      segs: marginNegative
        ? [
            // Pool overflows net: net is all pool, plus a red deficit beyond net.
            { label: "Pool (liability)", usd: poolUsd, x: X(0), w: W(netUsd), fill: C.pool },
            { label: "Deficit", usd: -marginUsd, x: X(netUsd), w: W(poolUsd - netUsd), fill: C.deficit, negative: true },
          ]
        : [
            { label: "Pool (liability)", usd: poolUsd, x: X(0), w: W(poolUsd), fill: C.pool },
            { label: "Margin (house)", usd: marginUsd, x: X(poolUsd), w: W(marginUsd), fill: C.margin },
          ],
    },
  ];

  return {
    viewBox: `0 0 ${VIEW_W} ${PAD_TOP + 3 * ROW_STRIDE}`,
    rowH: ROW_H,
    rows,
    grossUsd: gross,
    storeFeeUsd,
    netUsd,
    poolUsd,
    marginUsd,
    marginNegative,
  };
}
