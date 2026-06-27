/*
 * EchoMQ dashboard state — modelled in Effector (the same pattern a real
 * Mercury consumer uses). The @mercury/effector plug owns the theme; this
 * file owns the dashboard's own cross-cutting state.
 */
import { createEvent, createStore } from "effector";
import { useUnit } from "effector-react";

export type View = "Overview" | "Jobs" | "Job Groups" | "Batches" | "Processors";
export const VIEWS: View[] = ["Overview", "Jobs", "Job Groups", "Batches", "Processors"];

export const setView = createEvent<View>();
export const $view = createStore<View>("Overview").on(setView, (_, v) => v);
export const useView = (): View => useUnit($view);

export const selectQueue = createEvent<string>();
export const $selected = createStore("order-processing").on(selectQueue, (_, q) => q);
export const useSelected = (): string => useUnit($selected);

export const setSearch = createEvent<string>();
export const $search = createStore("").on(setSearch, (_, s) => s);
export const useSearch = (): string => useUnit($search);

export type Run = "paused" | "running";
export const setRun = createEvent<Run>();
export const $run = createStore<Run>("running").on(setRun, (_, r) => r);
export const useRun = (): Run => useUnit($run);

export type Range = "1m" | "5m" | "15m" | "30m" | "1h";
export const setRange = createEvent<Range>();
export const $range = createStore<Range>("1m").on(setRange, (_, r) => r);
export const useRange = (): Range => useUnit($range);

/** Per-processor running flags, toggled by index. */
export const toggleProc = createEvent<number>();
export const $procRunning = createStore<boolean[]>([true, true, true, false]).on(toggleProc, (list, i) =>
  list.map((v, idx) => (idx === i ? !v : v)),
);
export const useProcRunning = (): boolean[] => useUnit($procRunning);
