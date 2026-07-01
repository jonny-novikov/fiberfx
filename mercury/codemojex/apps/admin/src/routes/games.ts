import type { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { ok, err, type Result, type Static } from "@echo/core";
import { db, games, guesses, rooms, type GameId } from "@codemojex/db";
import { eq, desc } from "drizzle-orm";
import type { FastifyInstance } from "fastify";
import * as S from "../schemas";
import { send, notFound, type ApiError } from "../reply";
import { readBoard } from "../valkey";

// Explicit public columns — secret and keyboard are never selected.
const gameCols = {
  id: games.id,
  roomId: games.roomId,
  status: games.status,
  free: games.free,
  guessFee: games.guessFee,
  prizePool: games.prizePool,
  prizeUsd: games.prizeUsd,
  endsMs: games.endsMs,
  totals: games.totals,
  insertedAt: games.insertedAt,
} as const;

async function getGame(app: FastifyInstance, id: GameId): Promise<Result<Static<typeof S.GameDetail>, ApiError>> {
  const [game] = await db.select(gameCols).from(games).where(eq(games.id, id));
  if (!game) return err(notFound(`game ${id} not found`));
  const recent = await db
    .select({
      id: guesses.id,
      playerId: guesses.playerId,
      percentage: guesses.percentage,
      effort: guesses.effort,
      score: guesses.score,
      insertedAt: guesses.insertedAt,
    })
    .from(guesses)
    .where(eq(guesses.gameId, id))
    .orderBy(desc(guesses.insertedAt))
    .limit(50);
  const board = await readBoard(app.valkey, id, 25);
  return ok({ game, board, guesses: recent });
}

export const gameRoutes: FastifyPluginAsyncTypebox = async (app) => {
  app.get(
    "/games",
    { schema: { querystring: S.GamesQuery, response: { 200: S.GamesList } } },
    async (req) => {
      const status = req.query.status;
      const all = await db
        .select({ ...gameCols, roomName: rooms.name })
        .from(games)
        .leftJoin(rooms, eq(games.roomId, rooms.id))
        .orderBy(desc(games.insertedAt))
        .limit(200);
      return status ? all.filter((g) => g.status === status) : all;
    },
  );

  app.get(
    "/games/:id",
    { schema: { params: S.GameParams, response: { 200: S.GameDetail, 404: S.ErrorResponse } } },
    async (req, reply) => send(reply, await getGame(app, req.params.id)),
  );
};
