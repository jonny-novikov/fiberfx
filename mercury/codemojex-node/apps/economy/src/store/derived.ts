/*
 * Derived state — plain effector map/combine over `form.$values`. Every store
 * recomputes synchronously on each input change; no effects, no Date/random.
 * The revenue flow is computed in <RevenueFlow> (its channel is component-local).
 */

import { combine, createEvent, createStore } from "effector";
import { form, type Inputs } from "./form";
import type { ModelParams, PackageRow, SplitResult, WacState } from "../model/calc";
import { split, splitWith, marginByStore, prizePool, conservation, packageLadder, wacBuy, wacSpend } from "../model/calc";
import { buildHousePctCurve, buildMarginCurve, buildPoolGrowth } from "../model/curves";

const toParams = ({ players, guessesEach, ...p }: Inputs): ModelParams => p;

export interface LadderRow extends PackageRow {
  split: SplitResult;
}

export const $params = form.$values.map(toParams);
export const $split = $params.map(split);
export const $marginRows = $params.map(marginByStore);
export const $ladderRows = $params.map<LadderRow[]>((p) =>
  packageLadder().map((rung) => ({ ...rung, split: splitWith({ ...p, akp: rung.akp }, p.storeFeeMobile) })),
);
export const $prizePool = combine(form.$values, (v) => prizePool(toParams(v), v.players, v.guessesEach));
export const $conservation = $prizePool.map(conservation);

export const $housePctCurve = $params.map(buildHousePctCurve);
export const $marginCurve = $params.map(buildMarginCurve);
export const $poolGrowthCurve = combine($params, form.$values, (p, v) => buildPoolGrowth(p, v.players * v.guessesEach));

/* ───────── WAC balance simulator — an independent island ───────── */
export const wacBought = createEvent<{ keys: number; costUsd: number }>();
export const wacSpent = createEvent<number>();
export const wacReset = createEvent();
export const $wac = createStore<WacState>({ keys: 0, basisUsd: 0 })
  .on(wacBought, (s, { keys, costUsd }) => wacBuy(s, keys, costUsd))
  .on(wacSpent, (s, keys) => wacSpend(s, keys).next)
  .reset(wacReset);
