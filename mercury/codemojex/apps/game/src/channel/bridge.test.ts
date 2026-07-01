/**
 * The bridge-transport proof: `bridgeChannel` (a host bridge lifted into
 * ChannelLike) drives the SAME `createGameModel` the Phoenix-channel twin uses.
 *
 * Behavioral home for @mercury/effector's `bridgeChannel` (the package carries
 * no vitest harness; the game suite is its one real consumer): the synthetic
 * join reply seeds `$props` (+ the derived slices), one-off frames surface as
 * `serverEvent` AND as the typed per-name events, outbound pushes route to
 * `bridge.pushEvent` with an "ok" ack, and unbind releases every bridge
 * subscription.
 */
import { describe, it, expect, vi } from "vitest";
import { bridgeChannel, type HostBridge } from "@mercury/effector";
import { createGameModel, GAME_INBOUND } from "@/channel/model";
import type { GameProps } from "@/types";

function sampleProps(me: string, prize = 0): GameProps {
  return {
    view: {
      game: "GAM1",
      room: null,
      emojiset: null,
      ends_ms: null,
      prize_pool: prize,
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

/** A fake host bridge: multi-listener fan-out (the boot's Set semantics),
 *  observable pushes, observable per-listener teardown. */
function makeBridge() {
  const listeners = new Set<(name: string, payload: unknown) => void>();
  const pushEvent = vi.fn();
  const bridge: HostBridge = {
    pushEvent,
    onServerEvent: (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
  };
  const emit = (name: string, payload?: unknown): void => {
    for (const cb of listeners) cb(name, payload);
  };
  return { bridge, emit, pushEvent, listeners };
}

describe("bridgeChannel through createGameModel", () => {
  it("seeds $props (and the derived slices) from the synthetic join reply", () => {
    const model = createGameModel();
    const { bridge } = makeBridge();
    const initial = sampleProps("PLR1", 7);

    model.chan.bind(bridgeChannel(bridge, { joinReply: initial }), GAME_INBOUND);

    expect(model.chan.$status.getState()).toBe("joined");
    expect(model.$props.getState()).toEqual(initial);
    expect(model.$view.getState()?.prize_pool).toBe(7);
    expect(model.$me.getState()).toBe("PLR1");
    expect(model.$leaderboard.getState()).toEqual([]);
    expect(model.$history.getState()).toEqual([]);
  });

  it("routes a game:update frame from the bridge into $props", () => {
    const model = createGameModel();
    const { bridge, emit } = makeBridge();
    model.chan.bind(bridgeChannel(bridge, { joinReply: sampleProps("PLR1") }), GAME_INBOUND);

    emit("game:update", sampleProps("PLR2", 42));

    expect(model.$props.getState()?.me).toBe("PLR2");
    expect(model.$view.getState()?.prize_pool).toBe(42);
  });

  it("surfaces one-off frames as serverEvent AND as the typed per-name event", () => {
    const model = createGameModel();
    const { bridge, emit } = makeBridge();
    model.chan.bind(bridgeChannel(bridge, { joinReply: sampleProps("PLR1") }), GAME_INBOUND);

    const anyEvent = vi.fn();
    const revealed = vi.fn();
    const rejected = vi.fn();
    const unAny = model.serverEvent.watch(anyEvent);
    const unRev = model.events.revealed.watch(revealed);
    const unRej = model.events.guessRejected.watch(rejected);

    emit("revealed", { code: ["0000"] });
    emit("guess_rejected", { reason: "closed" });

    expect(anyEvent).toHaveBeenCalledTimes(2);
    expect(revealed).toHaveBeenCalledExactlyOnceWith({ code: ["0000"] });
    expect(rejected).toHaveBeenCalledExactlyOnceWith({ reason: "closed" });
    unAny();
    unRev();
    unRej();
  });

  it("routes outbound pushes to bridge.pushEvent, and pushAsync resolves on the ack", async () => {
    const model = createGameModel();
    const { bridge, pushEvent } = makeBridge();
    model.chan.bind(bridgeChannel(bridge, { joinReply: sampleProps("PLR1") }), GAME_INBOUND);

    model.submitGuess(["0000", "0011"]);
    expect(pushEvent).toHaveBeenCalledWith("submit_guess", { emojis: ["0000", "0011"] });

    await expect(model.chan.pushAsync("lock", { pos: 1, code: "0022" })).resolves.toBeUndefined();
    expect(pushEvent).toHaveBeenCalledWith("lock", { pos: 1, code: "0022" });
  });

  it("unbind releases every bridge subscription; later frames no longer reach the model", () => {
    const model = createGameModel();
    const { bridge, emit, listeners } = makeBridge();
    const unbind = model.chan.bind(
      bridgeChannel(bridge, { joinReply: sampleProps("PLR1") }),
      GAME_INBOUND,
    );
    expect(listeners.size).toBe(GAME_INBOUND.length);

    const spy = vi.fn();
    const un = model.serverEvent.watch(spy);
    unbind();

    expect(listeners.size).toBe(0);
    emit("revealed", {});
    expect(spy).not.toHaveBeenCalled();
    un();
  });
});
