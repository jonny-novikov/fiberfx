/**
 * The admin's read-side view of the live tier (ValKey on :6390, passwordless in
 * dev). The board is a sorted set per game written by the scoring consumer
 * (`Codemojex.Board`); the admin only reads it.
 *
 * Key layout mirrors the Elixir side. If the live key prefix differs, change it
 * in ONE place here rather than scattering literals through the routes.
 */
import { Redis } from "iovalkey";
import type { Env } from "./env";

export type Board = Array<{ player: string; score: number }>;

export function makeValkey(env: Env): Redis {
  return new Redis({
    host: env.valkeyHost,
    port: env.valkeyPort,
    lazyConnect: false,
    maxRetriesPerRequest: 2,
  });
}

const boardKey = (gameId: string) => `board:${gameId}`;

/** Top-N of a game's board, highest score first. */
export async function readBoard(
  vk: Redis,
  gameId: string,
  limit = 25,
): Promise<Board> {
  // ZREVRANGE key 0 limit-1 WITHSCORES → [member, score, member, score, ...]
  const flat = await vk.zrevrange(boardKey(gameId), 0, limit - 1, "WITHSCORES");
  const out: Array<{ player: string; score: number }> = [];
  for (let i = 0; i < flat.length; i += 2) {
    const player = flat[i];
    const score = flat[i + 1];
    if (player !== undefined && score !== undefined) {
      out.push({ player, score: Number(score) });
    }
  }
  return out;
}

/** Liveness probe used by the health route. */
export async function valkeyPing(vk: Redis): Promise<boolean> {
  try {
    return (await vk.ping()) === "PONG";
  } catch {
    return false;
  }
}
