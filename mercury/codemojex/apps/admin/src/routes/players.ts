import type { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { ok, err, type Result, type Static } from "@echo/core";
import { db, players, guesses, walletLedger, type PlayerId } from "@mercury/db";
import { eq, desc, ilike } from "drizzle-orm";
import * as S from "../schemas.js";
import { send, notFound, type ApiError } from "../reply.js";

const walletCols = {
  id: players.id,
  name: players.name,
  tgUserId: players.tgUserId,
  clips: players.clips,
  diamonds: players.diamonds,
  availableDiamonds: players.availableDiamonds,
  bonusDiamonds: players.bonusDiamonds,
  lockedDiamonds: players.lockedDiamonds,
  keys: players.keys,
  availableKeys: players.availableKeys,
  insertedAt: players.insertedAt,
} as const;

async function getPlayer(id: PlayerId): Promise<Result<Static<typeof S.PlayerDetail>, ApiError>> {
  const [player] = await db.select(walletCols).from(players).where(eq(players.id, id));
  if (!player) return err(notFound(`player ${id} not found`));
  const recent = await db
    .select({
      id: guesses.id,
      gameId: guesses.gameId,
      percentage: guesses.percentage,
      score: guesses.score,
      insertedAt: guesses.insertedAt,
    })
    .from(guesses)
    .where(eq(guesses.playerId, id))
    .orderBy(desc(guesses.insertedAt))
    .limit(50);

  // wallet_ledger is provisional until reconciled via db:pull; tolerate absence
  let ledger: unknown[] = [];
  try {
    ledger = await db
      .select()
      .from(walletLedger)
      .where(eq(walletLedger.playerId, id))
      .orderBy(desc(walletLedger.insertedAt))
      .limit(50);
  } catch {
    ledger = [];
  }
  return ok({ player, guesses: recent, ledger });
}

export const playerRoutes: FastifyPluginAsyncTypebox = async (app) => {
  app.get(
    "/players",
    { schema: { querystring: S.PlayersQuery, response: { 200: S.PlayersList } } },
    async (req) => {
      const q = req.query.q?.trim();
      if (q) {
        return db.select(walletCols).from(players).where(ilike(players.name, `%${q}%`)).limit(200);
      }
      return db.select(walletCols).from(players).orderBy(desc(players.insertedAt)).limit(200);
    },
  );

  app.get(
    "/players/:id",
    { schema: { params: S.PlayerParams, response: { 200: S.PlayerDetail, 404: S.ErrorResponse } } },
    async (req, reply) => send(reply, await getPlayer(req.params.id)),
  );
};
