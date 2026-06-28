/*
 * The calibration input model — one @mercury/effector createForm over the
 * ModelParams (+ N/G). Everything computed derives from `form.$values`
 * (see derived.ts). The akp source (manual vs a package rung) is the only
 * non-field UI state.
 */

import { createEvent, createStore } from "effector";
import { createForm } from "@mercury/effector";
import type { ModelParams } from "../model/calc";
import { packageAkp } from "../model/calc";

export type Inputs = ModelParams & {
  /** N — players in the room. */
  players: number;
  /** G — guesses per player. */
  guessesEach: number;
};

export const INITIAL: Inputs = {
  diamondsPerUsd: 10,
  akp: 0.15,
  guessFee: 5,
  poolPortion: 0.7,
  storeFeeMobile: 0.32,
  storeFeeDesktop: 0.03,
  splitBasis: "gross",
  players: 10,
  guessesEach: 20,
};

export const form = createForm<Inputs>({
  initialValues: INITIAL,
  validate: (v) => {
    const e: Partial<Record<keyof Inputs, string>> = {};
    if (!(v.diamondsPerUsd > 0)) e.diamondsPerUsd = "must be > 0";
    if (!(v.akp > 0)) e.akp = "must be > 0";
    if (!(v.guessFee >= 1)) e.guessFee = "≥ 1 key";
    if (v.poolPortion < 0 || v.poolPortion > 1) e.poolPortion = "0 – 1";
    if (v.storeFeeMobile < 0 || v.storeFeeMobile >= 1) e.storeFeeMobile = "0 to <1";
    if (v.storeFeeDesktop < 0 || v.storeFeeDesktop >= 1) e.storeFeeDesktop = "0 to <1";
    if (!(v.players >= 1)) e.players = "≥ 1";
    if (!(v.guessesEach >= 1)) e.guessesEach = "≥ 1";
    return e;
  },
});

/** Where the current akp came from — manual edit or a picked package. */
export type AkpSource = { kind: "manual" } | { kind: "package"; keys: number };
export const setAkpSource = createEvent<AkpSource>();
export const $akpSource = createStore<AkpSource>({ kind: "manual" }).on(setAkpSource, (_, s) => s);

/** Edit akp directly (slider / number) → field + source becomes manual. */
export const editAkp = createEvent<number>();
editAkp.watch((value) => {
  form.changed({ name: "akp", value });
  setAkpSource({ kind: "manual" });
});

/** Pick a package rung → push its akp into the field + remember the source. */
export const pickPackage = createEvent<{ keys: number; stars: number }>();
pickPackage.watch(({ keys, stars }) => {
  form.changed({ name: "akp", value: packageAkp(stars, keys) });
  setAkpSource({ kind: "package", keys });
});
