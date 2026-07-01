import { createEffect, createStore, createEvent, sample } from "effector";
import type { GameSummary, PlayerSummary, RoomSummary } from "@/types";

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

// The rooms / players seams (admin.5.1-D1) mirror the games trio exactly — the
// same auth() helper, the same base; no second credential path (admin.5.1-INV1).
export const fetchRoomsFx = createEffect<void, RoomSummary[]>(async () => {
  const res = await fetch(`${base}/rooms`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /rooms ${res.status}`);
  return (await res.json()) as RoomSummary[];
});

export const $rooms = createStore<RoomSummary[]>([]).on(fetchRoomsFx.doneData, (_s, r) => r);

export const fetchPlayersFx = createEffect<void, PlayerSummary[]>(async () => {
  const res = await fetch(`${base}/players`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /players ${res.status}`);
  return (await res.json()) as PlayerSummary[];
});

export const $players = createStore<PlayerSummary[]>([]).on(fetchPlayersFx.doneData, (_s, p) => p);

// The topbar connection/health indicator (admin.5-R3): a tri-state derived PURELY
// from the fetch effects — no new fetch, no new wire. "idle" before the first
// call; admin.5.1 fans in all three effects so the indicator is truthful on
// every desk.
export type Health = "idle" | "loading" | "ok" | "error";
export const $health = createStore<Health>("idle")
  .on([fetchGamesFx, fetchRoomsFx, fetchPlayersFx], () => "loading")
  .on([fetchGamesFx.done, fetchRoomsFx.done, fetchPlayersFx.done], () => "ok")
  .on([fetchGamesFx.fail, fetchRoomsFx.fail, fetchPlayersFx.fail], () => "error");

// Mount triggers the shell / desks fire; keeps raw fetch() confined to this file.
export const gamesRequested = createEvent();
sample({ clock: gamesRequested, target: fetchGamesFx });

export const roomsRequested = createEvent();
sample({ clock: roomsRequested, target: fetchRoomsFx });

export const playersRequested = createEvent();
sample({ clock: playersRequested, target: fetchPlayersFx });
