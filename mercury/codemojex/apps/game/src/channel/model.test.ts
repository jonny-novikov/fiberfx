/**
 * The channel->props wiring proof (cmt.3-INV5's unit-proof).
 *
 * Drives `createGameModel()` through a fake `ChannelLike` (no socket, no Phoenix)
 * and asserts the four contract mappings the model promises: a GameProps-shaped
 * join reply and a "game:update" frame set/refresh `$props`; a one-off frame
 * ("guess_rejected") surfaces as a `serverEvent`; `submitGuess` pushes
 * "submit_guess" with the emojis payload back over the bound channel.
 */
import { describe, it, expect } from "vitest";
import type { ChannelLike, PushLike } from "@mercury/effector";
import { createGameModel, GAME_INBOUND } from "@/channel/model";
import type { GameProps } from "@/types";

/** A minimal GameProps payload — `isGameProps` only gates on `"view" in value`. */
function sampleProps(me: string): GameProps {
  return {
    view: {
      game: "GAM1",
      room: null,
      emojiset: null,
      ends_ms: null,
      prize_pool: 0,
      prize_usd: 0,
      guess_fee: 1,
      free: false,
      status: "open",
    },
    leaderboard: [],
    history: [],
    me,
  };
}

/**
 * A fake Phoenix channel: captures the per-event `on` listeners and the join `ok`
 * callback so a test can drive inbound frames, and records outbound pushes.
 */
function makeFakeChannel() {
  const listeners = new Map<string, (payload?: unknown) => void>();
  const pushes: Array<{ event: string; payload: object }> = [];
  let joinOk: ((payload?: unknown) => void) | undefined;
  const noopPush: PushLike = { receive: () => noopPush };

  const channel: ChannelLike = {
    join: () => {
      const p: PushLike = {
        receive(status, cb) {
          if (status === "ok") joinOk = cb;
          return p;
        },
      };
      return p;
    },
    on: (event, cb) => {
      listeners.set(event, cb);
      return listeners.size;
    },
    off: () => {},
    push: (event, payload) => {
      pushes.push({ event, payload });
      return noopPush;
    },
    onClose: () => {},
    onError: () => 0,
    leave: () => noopPush,
  };

  return {
    channel,
    fireJoin: (payload: unknown) => joinOk?.(payload),
    fire: (event: string, payload: unknown) => listeners.get(event)?.(payload),
    pushes,
  };
}

describe("createGameModel", () => {
  it("sets $props from a GameProps-shaped join reply", () => {
    const model = createGameModel();
    const fake = makeFakeChannel();
    model.chan.bind(fake.channel, GAME_INBOUND);

    expect(model.$props.getState()).toBeNull();
    fake.fireJoin(sampleProps("PLR_A"));
    expect(model.$props.getState()?.me).toBe("PLR_A");
  });

  it("refreshes $props on a game:update frame", () => {
    const model = createGameModel();
    const fake = makeFakeChannel();
    model.chan.bind(fake.channel, GAME_INBOUND);

    fake.fireJoin(sampleProps("PLR_A"));
    fake.fire("game:update", sampleProps("PLR_B"));
    expect(model.$props.getState()?.me).toBe("PLR_B");
  });

  it("routes a guess_rejected frame to a serverEvent (not to $props)", () => {
    const model = createGameModel();
    const fake = makeFakeChannel();
    const seen: Array<{ name: string; payload: unknown }> = [];
    model.serverEvent.watch((e) => seen.push(e));
    model.chan.bind(fake.channel, GAME_INBOUND);

    fake.fire("guess_rejected", { reason: "bad_guess" });
    expect(seen).toHaveLength(1);
    expect(seen[0]?.name).toBe("guess_rejected");
    expect(model.$props.getState()).toBeNull();
  });

  it("pushes submit_guess with the emojis payload over the bound channel", () => {
    const model = createGameModel();
    const fake = makeFakeChannel();
    model.chan.bind(fake.channel, GAME_INBOUND);

    model.submitGuess(["A1", "B2"]);
    expect(fake.pushes).toContainEqual({ event: "submit_guess", payload: { emojis: ["A1", "B2"] } });
  });
});
