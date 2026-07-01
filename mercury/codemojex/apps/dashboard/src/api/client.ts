import { createEffect, createStore, createEvent, sample } from "effector";
import type {
  GameDetail,
  GameSummary,
  PlayerDetail,
  PlayerSummary,
  RoomDetail,
  RoomSummary,
} from "@/types";

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

// The keyed detail seam (admin.5.2-D1): selecting a row sets the id AND fires the
// keyed fetch through one sample; deselect resets both stores so a stale pane
// never renders. The shipped GET /rooms/:id route (admin.1) is the only wire —
// the same auth() helper, the same base, no second credential path.
export const roomSelected = createEvent<string>();
export const roomDeselected = createEvent();

export const fetchRoomDetailFx = createEffect<string, RoomDetail>(async (id) => {
  const res = await fetch(`${base}/rooms/${id}`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /rooms/${id} ${res.status}`);
  return (await res.json()) as RoomDetail;
});

export const $selectedRoomId = createStore<string | null>(null)
  .on(roomSelected, (_s, id) => id)
  .reset(roomDeselected);

// The detail store fills ONLY when the reply matches the CURRENT selection —
// .done carries the effect's params (the requested id), so a late reply for a
// superseded or cleared selection is dropped instead of overwriting the pane.
export const $roomDetail = createStore<RoomDetail | null>(null).reset(roomDeselected);
sample({
  clock: fetchRoomDetailFx.done,
  source: $selectedRoomId,
  filter: (sel, { params }) => sel === params,
  fn: (_sel, { result }) => result,
  target: $roomDetail,
});

sample({ clock: roomSelected, target: fetchRoomDetailFx });

// The players detail trio mirrors the rooms trio exactly (admin.5.2-D1), over the
// shipped GET /players/:id route (admin.1).
export const playerSelected = createEvent<string>();
export const playerDeselected = createEvent();

export const fetchPlayerDetailFx = createEffect<string, PlayerDetail>(async (id) => {
  const res = await fetch(`${base}/players/${id}`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /players/${id} ${res.status}`);
  return (await res.json()) as PlayerDetail;
});

export const $selectedPlayerId = createStore<string | null>(null)
  .on(playerSelected, (_s, id) => id)
  .reset(playerDeselected);

// The same selection filter as the rooms seam: a late reply for a superseded or
// cleared selection is dropped.
export const $playerDetail = createStore<PlayerDetail | null>(null).reset(playerDeselected);
sample({
  clock: fetchPlayerDetailFx.done,
  source: $selectedPlayerId,
  filter: (sel, { params }) => sel === params,
  fn: (_sel, { result }) => result,
  target: $playerDetail,
});

sample({ clock: playerSelected, target: fetchPlayerDetailFx });

// The keyed game seam (admin.5.3-D1): the room -> game live path's node-only
// interim. Selecting a game on the room pane fires the keyed fetch over the
// shipped GET /games/:id route (admin.1) — the same auth() helper, the same
// base, no second credential path (admin.5.3-INV1, INV5). Both stores also
// reset on the shipped roomDeselected — a game selection never outlives its
// room, so a desk switch clears the watch surface through the 5.2 chain.
export const gameSelected = createEvent<string>();
export const gameDeselected = createEvent();

export const fetchGameDetailFx = createEffect<string, GameDetail>(async (id) => {
  const res = await fetch(`${base}/games/${id}`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /games/${id} ${res.status}`);
  return (await res.json()) as GameDetail;
});

export const $selectedGameId = createStore<string | null>(null)
  .on(gameSelected, (_s, id) => id)
  .reset(gameDeselected)
  .reset(roomDeselected);

// The detail store fills ONLY through the guarded done-sample (the admin.5.2
// hardening idiom, ledger L-2): .done carries the effect's params (the
// requested id), so a late reply for a superseded or cleared selection is
// dropped, while a poll reply for the CURRENT id passes on every tick. The
// later engine spectator channel model samples into this SAME store and
// retires the poll — no view rewrite (admin.5.3-INV4, the two-clock seam).
export const $gameDetail = createStore<GameDetail | null>(null)
  .reset(gameDeselected)
  .reset(roomDeselected);
sample({
  clock: fetchGameDetailFx.done,
  source: $selectedGameId,
  filter: (sel, { params }) => sel === params,
  fn: (_sel, { result }) => result,
  target: $gameDetail,
});

sample({ clock: gameSelected, target: fetchGameDetailFx });

// The near-live poll seam (admin.5.3-D3): the spectator view ticks this event
// every POLL_MS; the guarded sample re-fires the keyed fetch only while a game
// stays selected — a stale tick with no id fires no fetch (admin.5.3-INV6).
export const gamePollTicked = createEvent();
sample({
  clock: gamePollTicked,
  source: $selectedGameId,
  filter: (id): id is string => id !== null,
  target: fetchGameDetailFx,
});

// The topbar connection/health indicator (admin.5-R3): a tri-state derived PURELY
// from the fetch effects — no new fetch, no new wire. "idle" before the first
// call; admin.5.1 fans in the three list effects and admin.5.2 fans in the two
// keyed detail effects, so the indicator is truthful on every desk. admin.5.3
// fans in the game-detail effect's done/fail ONLY — deliberately not its loading
// flip, because the poll re-fires the effect every cadence and a loading flip
// would strobe the indicator; ok/error stay truthful.
export type Health = "idle" | "loading" | "ok" | "error";
export const $health = createStore<Health>("idle")
  .on([fetchGamesFx, fetchRoomsFx, fetchPlayersFx, fetchRoomDetailFx, fetchPlayerDetailFx], () => "loading")
  .on(
    [
      fetchGamesFx.done,
      fetchRoomsFx.done,
      fetchPlayersFx.done,
      fetchRoomDetailFx.done,
      fetchPlayerDetailFx.done,
      fetchGameDetailFx.done,
    ],
    () => "ok",
  )
  .on(
    [
      fetchGamesFx.fail,
      fetchRoomsFx.fail,
      fetchPlayersFx.fail,
      fetchRoomDetailFx.fail,
      fetchPlayerDetailFx.fail,
      fetchGameDetailFx.fail,
    ],
    () => "error",
  );

// Mount triggers the shell / desks fire; keeps raw fetch() confined to this file.
export const gamesRequested = createEvent();
sample({ clock: gamesRequested, target: fetchGamesFx });

export const roomsRequested = createEvent();
sample({ clock: roomsRequested, target: fetchRoomsFx });

export const playersRequested = createEvent();
sample({ clock: playersRequested, target: fetchPlayersFx });
