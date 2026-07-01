/**
 * PhoenixGame — hot-plug the game onto a Phoenix channel.
 *
 * One `Socket`, one `game:<id>` channel, bound to an Effector model that mirrors
 * the GameLive contract. `GameEdge` is untouched: it sees a `Bridge` whose
 * `pushEvent` goes to the channel and whose `onServerEvent` taps the model's
 * one-off events, and its props come from the model's `$props` store. Mounting
 * this component under a live socket is the whole integration — no LiveView host.
 */
import { useEffect, useMemo, useRef } from "react";
import { Socket } from "@echo/phoenix";
import { useUnit } from "effector-react";
import type { ChannelLike } from "@mercury/effector";
import { GameEdge } from "@/GameEdge";
import type { Bridge } from "@/types";
import { createGameModel, GAME_INBOUND, type ServerEvent } from "@/channel/model";

export interface PhoenixGameProps {
  /** GAM id — the `game:<id>` topic. */
  game: string;
  /** SES id — the socket connect param (a body field, kept out of the query string). */
  session: string;
  /** Socket mount point. Defaults to `/socket`. */
  endpoint?: string;
  /** Rendered until the first props arrive. */
  fallback?: React.ReactNode;
}

export function PhoenixGame({ game, session, endpoint = "/socket", fallback }: PhoenixGameProps) {
  // One model + one socket per mount.
  const model = useMemo(() => createGameModel(), []);
  const props = useUnit(model.$props);

  // Fan the model's one-off server events out to any GameEdge onServerEvent subs.
  const subs = useRef(new Set<(name: string, payload: unknown) => void>());
  useEffect(
    () =>
      model.serverEvent.watch((e: ServerEvent) => {
        for (const cb of subs.current) cb(e.name, e.payload);
      }),
    [model],
  );

  // Open the socket, join game:<id>, hot-plug the channel into the model.
  useEffect(() => {
    const socket = new Socket(endpoint, { params: { session } });
    socket.connect();
    const channel = socket.channel(`game:${game}`, {});
    const unbind = model.chan.bind(channel as unknown as ChannelLike, GAME_INBOUND);
    return () => {
      unbind();
      channel.leave();
      socket.disconnect();
    };
  }, [model, game, session, endpoint]);

  const bridge = useMemo<Bridge>(
    () => ({
      pushEvent: (event, payload) => model.chan.push(event, (payload ?? {}) as object),
      onServerEvent: (cb) => {
        subs.current.add(cb);
        return () => {
          subs.current.delete(cb);
        };
      },
    }),
    [model],
  );

  if (!props) return <>{fallback ?? <div className="game__empty">Подключение…</div>}</>;
  return <GameEdge {...props} bridge={bridge} />;
}
