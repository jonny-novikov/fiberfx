/**
 * The codemojex game model — Effector state fed by a Phoenix channel.
 *
 * Built on `@mercury/effector`'s `createChannel`. It mirrors the `GameLive`
 * contract exactly (the channel is the channel-transport twin of the LiveView):
 * full `GameProps` arrive on the join reply and on every `"game:update"`; the
 * one-off `"revealed"` / `"golden_win"` / `"guess_rejected"` frames surface as
 * server events; and `submit_guess` / `lock` / `unlock` go out as pushes.
 *
 * The model is transport-agnostic. `PhoenixGame` plugs a live channel into it.
 */
import { createChannel } from "@mercury/effector";
import { createEvent, createStore, sample } from "effector";
import type { GameProps } from "@/types";

/** The inbound frame names the channel binds. `"game:update"` carries fresh
 *  props; the rest are one-off events GameEdge shows as toasts. */
export const GAME_INBOUND = ["game:update", "revealed", "golden_win", "guess_rejected"] as const;

export interface ServerEvent {
  name: string;
  payload: unknown;
}

function isGameProps(value: unknown): value is GameProps {
  return typeof value === "object" && value !== null && "view" in value;
}

export function createGameModel() {
  const chan = createChannel();

  // Full props: the join reply and every "game:update".
  const propsReceived = createEvent<GameProps>();
  const $props = createStore<GameProps | null>(null).on(propsReceived, (_s, p) => p);

  // One-off server events (reject / reveal / win).
  const serverEvent = createEvent<ServerEvent>();

  // Join reply -> props.
  sample({
    clock: chan.joined,
    filter: isGameProps,
    target: propsReceived,
  });

  // "game:update" frames -> props.
  sample({
    clock: chan.message,
    filter: (m) => m.event === "game:update" && isGameProps(m.payload),
    fn: (m) => m.payload as GameProps,
    target: propsReceived,
  });

  // Every other frame -> a server event.
  sample({
    clock: chan.message,
    filter: (m) => m.event !== "game:update",
    fn: (m): ServerEvent => ({ name: m.event, payload: m.payload }),
    target: serverEvent,
  });

  // Derived slices of $props — fine-grained effector-react consumption
  // (useUnit/useStoreMap subscribers re-render per slice, not per full props).
  const $view = $props.map((p) => p?.view ?? null);
  const $leaderboard = $props.map((p) => p?.leaderboard ?? []);
  const $history = $props.map((p) => p?.history ?? []);
  const $me = $props.map((p) => p?.me ?? null);

  // Typed one-off events — the client-side terminus of the server's
  // Phoenix.PubSub fan-out ("game:"<>gam), one Effector event per frame name.
  const guessRejected = createEvent<unknown>();
  const revealed = createEvent<unknown>();
  const goldenWin = createEvent<unknown>();
  (
    [
      ["guess_rejected", guessRejected],
      ["revealed", revealed],
      ["golden_win", goldenWin],
    ] as const
  ).forEach(([name, target]) => {
    sample({
      clock: serverEvent,
      filter: (e) => e.name === name,
      fn: (e) => e.payload,
      target,
    });
  });

  // Outbound, matching the GameEdge bridge contract.
  const submitGuess = (emojis: string[]): void => chan.push("submit_guess", { emojis });
  const lock = (pos: number, code: string): void => chan.push("lock", { pos, code });
  const unlock = (pos: number): void => chan.push("unlock", { pos });

  return {
    chan,
    $props,
    $view,
    $leaderboard,
    $history,
    $me,
    serverEvent,
    events: { guessRejected, revealed, goldenWin },
    propsReceived,
    submitGuess,
    lock,
    unlock,
  };
}

export type GameModel = ReturnType<typeof createGameModel>;
