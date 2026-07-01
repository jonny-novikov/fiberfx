/**
 * BridgeGame — hot-plug the game onto a LiveView host bridge.
 *
 * The LiveView-transport twin of `PhoenixGame`: the host's `Bridge`
 * ({pushEvent, onServerEvent}) is lifted into a `ChannelLike` by
 * `bridgeChannel`, so the SAME `createGameModel` drives the screen on both
 * transports. The initial props ride as the synthetic join reply (the moral
 * twin of RoomChannel's join `game_props`), seeding `$props`; fresh props
 * pushed by the host (`update()` -> `model.propsReceived`) flow through the
 * same store. `GameEdge` is untouched — it keeps the raw bridge for its own
 * toast subscription and outbound pushes, and renders from `$props` (falling
 * back to `initial` so the first paint is as immediate as the imperative
 * render it replaces).
 */
import { useEffect } from "react";
import { useUnit } from "effector-react";
import { bridgeChannel } from "@mercury/effector";
import { GameEdge } from "@/GameEdge";
import type { Bridge, GameProps } from "@/types";
import { GAME_INBOUND, type GameModel } from "@/channel/model";

export interface BridgeGameProps {
  /** The model driving the screen — owned by the caller (mount), so state can
   *  outlive this component across a hot swap. */
  model: GameModel;
  /** The host bridge, passed through to GameEdge unchanged. */
  bridge: Bridge;
  /** The host's initial props (data-props) — the synthetic join reply. */
  initial: GameProps;
}

export function BridgeGame({ model, bridge, initial }: BridgeGameProps) {
  const props = useUnit(model.$props);

  useEffect(() => {
    // Re-binding after a swap seeds from the model's latest props, not the
    // stale mount-time initial.
    const seed = model.$props.getState() ?? initial;
    return model.chan.bind(bridgeChannel(bridge, { joinReply: seed }), GAME_INBOUND);
  }, [model, bridge, initial]);

  const p = props ?? initial;
  return <GameEdge {...p} bridge={bridge} />;
}
