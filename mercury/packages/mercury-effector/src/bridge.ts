/**
 * bridgeChannel — lift a host bridge into the `ChannelLike` contract.
 *
 * A LiveView-style host hands an embedded island a bridge — outbound
 * `pushEvent(event, payload)` plus an `onServerEvent(cb)` fan-out of named
 * server frames — rather than a raw Phoenix channel. Both transports terminate
 * the same server-side PubSub, so this adapter maps the bridge onto
 * `ChannelLike` and `createChannel().bind(...)` (and every model built over
 * it) runs unchanged on either transport.
 *
 * Semantics, stated honestly:
 * - `join()` resolves "ok" synchronously with `joinReply` — the host delivered
 *   the initial state before the island mounted (the moral twin of a Phoenix
 *   join reply), so there is nothing to wait for and no way to fail.
 * - `push()` forwards to `bridge.pushEvent` and acks "ok" immediately —
 *   fire-and-forget; a host reply path, where one exists, is a bridge-surface
 *   extension, not this adapter's invention.
 * - `onClose`/`onError` are no-ops: the host socket owns lifecycle and
 *   reconnection; the bridge never surfaces them.
 */
import type { ChannelLike, PushLike } from "./channel";

/** The host-bridge shape an embedding page hands its island. */
export interface HostBridge {
  pushEvent(event: string, payload: unknown): void;
  onServerEvent(cb: (name: string, payload: unknown) => void): () => void;
}

export interface BridgeChannelOptions {
  /** Delivered as the join "ok" reply (the host's initial state). */
  joinReply?: unknown;
}

/** A PushLike that acks "ok" synchronously and never errors. */
function okPush(reply?: unknown): PushLike {
  const push: PushLike = {
    receive(status, callback) {
      if (status === "ok") callback(reply);
      return push;
    },
  };
  return push;
}

export function bridgeChannel(bridge: HostBridge, opts: BridgeChannelOptions = {}): ChannelLike {
  const subs = new Map<number, () => void>();
  let nextRef = 1;

  return {
    join: () => okPush(opts.joinReply),
    on(event, callback) {
      const ref = nextRef++;
      const off = bridge.onServerEvent((name, payload) => {
        if (name === event) callback(payload);
      });
      subs.set(ref, off);
      return ref;
    },
    off(_event, ref) {
      if (ref === undefined) return;
      subs.get(ref)?.();
      subs.delete(ref);
    },
    push(event, payload) {
      bridge.pushEvent(event, payload);
      return okPush();
    },
    onClose() {
      /* host-owned lifecycle */
    },
    onError() {
      /* host-owned lifecycle */
      return 0;
    },
    leave() {
      for (const off of subs.values()) off();
      subs.clear();
      return okPush();
    },
  };
}
