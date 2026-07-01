/**
 * createChannel — an Effector plug for a Phoenix channel.
 *
 * The state lives outside React, matching the other Mercury plugs: a channel's
 * lifecycle (joining/joined/errored/closed), its inbound messages, and its
 * outbound pushes are Effector units. The plug is structurally typed against a
 * Phoenix channel (`ChannelLike`), so this package takes no `@echo/phoenix`
 * dependency — any object with the channel shape plugs in.
 *
 * "Hot plug": `bind(channel, inbound)` wires a live channel into the model at
 * runtime (join + the inbound listeners) and returns an unbind that removes the
 * listeners and detaches. Bind a fresh channel when the room changes; unbind on
 * teardown. A React status hook is provided for convenience; components stay
 * presentational.
 */
import { createEvent, createStore, createEffect, sample, type Store } from "effector";
import { useUnit } from "effector-react";

/** The receive-chain a Phoenix push returns. */
export interface PushLike {
  receive(status: string, callback: (response?: unknown) => void): PushLike;
}

/** The subset of a Phoenix channel this plug uses. A real `@echo/phoenix`
 *  `Channel` satisfies it structurally. */
export interface ChannelLike {
  join(timeout?: number): PushLike;
  on(event: string, callback: (payload?: unknown) => void): number;
  off(event: string, ref?: number): void;
  push(event: string, payload: object, timeout?: number): PushLike;
  onClose(callback: (payload?: unknown) => void): void;
  onError(callback: (reason?: unknown) => void): number;
  leave(timeout?: number): PushLike;
}

export type ChannelStatus = "idle" | "joining" | "joined" | "errored" | "closed";

/** A single inbound frame: the event name and its payload. */
export interface ChannelMessage {
  event: string;
  payload: unknown;
}

export interface ChannelModel {
  /** Reactive lifecycle status. */
  $status: Store<ChannelStatus>;
  /** The last join/close/error reason, or null. */
  $error: Store<unknown | null>;
  /** Fires with the join reply payload once the channel joins. */
  joined: import("effector").Event<unknown>;
  /** Every inbound frame for a bound event name. */
  message: import("effector").Event<ChannelMessage>;
  /** Fire-and-forget outbound push (routed to the bound channel). */
  push: (event: string, payload?: object) => void;
  /** Awaitable outbound push; resolves on "ok", rejects on "error"/"timeout". */
  pushAsync: (event: string, payload?: object) => Promise<unknown>;
  /** Plug a live channel in: join + listen. Returns an unbind. */
  bind: (channel: ChannelLike, inbound: readonly string[]) => () => void;
  /** React hook for the status store. */
  useStatus: () => ChannelStatus;
}

export function createChannel(): ChannelModel {
  const attached = createEvent<ChannelLike>();
  const detached = createEvent();
  const joining = createEvent();
  const joined = createEvent<unknown>();
  const errored = createEvent<unknown>();
  const closed = createEvent();
  const message = createEvent<ChannelMessage>();
  const pushRequested = createEvent<{ event: string; payload: object }>();

  const $channel = createStore<ChannelLike | null>(null)
    .on(attached, (_s, ch) => ch)
    .reset(detached);

  const $status = createStore<ChannelStatus>("idle")
    .on(joining, () => "joining")
    .on(joined, () => "joined")
    .on(errored, () => "errored")
    .on(closed, () => "closed")
    .reset(detached);

  const $error = createStore<unknown | null>(null)
    .on(errored, (_s, e) => e)
    .reset([joining, detached]);

  const pushFx = createEffect<{ channel: ChannelLike; event: string; payload: object }, unknown>(
    ({ channel, event, payload }) =>
      new Promise((resolve, reject) => {
        channel
          .push(event, payload)
          .receive("ok", resolve)
          .receive("error", reject)
          .receive("timeout", () => reject(new Error("push timeout")));
      }),
  );

  sample({
    clock: pushRequested,
    source: $channel,
    filter: (channel): channel is ChannelLike => channel !== null,
    fn: (channel, req) => ({ channel: channel as ChannelLike, event: req.event, payload: req.payload }),
    target: pushFx,
  });

  function bind(channel: ChannelLike, inbound: readonly string[]): () => void {
    attached(channel);
    joining();
    const refs = inbound.map((event) => {
      const ref = channel.on(event, (payload) => message({ event, payload }));
      return [event, ref] as const;
    });
    channel.onClose(() => closed());
    channel.onError((reason) => errored(reason));
    channel
      .join()
      .receive("ok", (payload) => joined(payload))
      .receive("error", (reason) => errored(reason))
      .receive("timeout", () => errored(new Error("join timeout")));

    return () => {
      for (const [event, ref] of refs) channel.off(event, ref);
      detached();
    };
  }

  function push(event: string, payload: object = {}): void {
    pushRequested({ event, payload });
  }

  function pushAsync(event: string, payload: object = {}): Promise<unknown> {
    const channel = $channel.getState();
    if (channel === null) return Promise.reject(new Error("no channel bound"));
    return pushFx({ channel, event, payload });
  }

  return {
    $status,
    $error,
    joined,
    message,
    push,
    pushAsync,
    bind,
    useStatus: () => useUnit($status),
  };
}
