import { createEffect, createStore, createEvent, sample } from "effector";
import type { GameSummary } from "@/types";

// admin.5-F2 same-origin: base "" in prod (admin Fastify serves the dist), blank
// in dev (the Vite proxy forwards). The token is config, NEVER a source literal.
const base = (import.meta.env.VITE_ADMIN_API_BASE as string) ?? "";
const token = import.meta.env.VITE_ADMIN_TOKEN as string;
const auth = () => ({ Authorization: `Bearer ${token}` });

export const fetchGamesFx = createEffect<void, GameSummary[]>(async () => {
  const res = await fetch(`${base}/games`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /games ${res.status}`);
  return (await res.json()) as GameSummary[];
});

// The two-clock seam (admin.5-D5 / INV4): views read this store via `useUnit`,
// never a component-local fetch. admin.7 seats a @mercury/effector `channel` model
// here (the game/src/channel/model.ts pattern) and `sample`s the live feed INTO
// $games — with no rewrite of any view.
export const $games = createStore<GameSummary[]>([]).on(fetchGamesFx.doneData, (_s, g) => g);

// The topbar connection/health indicator (admin.5-R3): a tri-state derived PURELY
// from the fetch effect — no new fetch, no new wire. "idle" before the first call.
export type Health = "idle" | "loading" | "ok" | "error";
export const $health = createStore<Health>("idle")
  .on(fetchGamesFx, () => "loading")
  .on(fetchGamesFx.done, () => "ok")
  .on(fetchGamesFx.fail, () => "error");

// A mount trigger the shell fires once; keeps raw fetch() confined to this file.
export const gamesRequested = createEvent();
sample({ clock: gamesRequested, target: fetchGamesFx });
