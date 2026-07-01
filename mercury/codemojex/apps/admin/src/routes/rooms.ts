import type { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { ok, err, type Result, type Static } from "@echo/core";
import { db, rooms, games, type RoomId } from "@codemojex/db";
import { eq, desc } from "drizzle-orm";
import * as S from "../schemas";
import { send, notFound, type ApiError } from "../reply";

const roomSummaryCols = {
  id: rooms.id,
  name: rooms.name,
  free: rooms.free,
  clipCost: rooms.clipCost,
  durationMs: rooms.durationMs,
  status: rooms.status,
  insertedAt: rooms.insertedAt,
} as const;

async function getRoom(id: RoomId): Promise<Result<Static<typeof S.RoomDetail>, ApiError>> {
  const [room] = await db.select(roomSummaryCols).from(rooms).where(eq(rooms.id, id));
  if (!room) return err(notFound(`room ${id} not found`));
  const roomGames = await db
    .select({
      id: games.id,
      status: games.status,
      free: games.free,
      prizePool: games.prizePool,
      endsMs: games.endsMs,
      insertedAt: games.insertedAt,
    })
    .from(games)
    .where(eq(games.room, id))
    .orderBy(desc(games.insertedAt));
  return ok({ room, games: roomGames });
}

async function setRoomStatus(
  id: RoomId,
  status: "open" | "closed",
): Promise<Result<Static<typeof S.RoomStatusResult>, ApiError>> {
  const [updated] = await db
    .update(rooms)
    .set({ status, updatedAt: new Date() })
    .where(eq(rooms.id, id))
    .returning({ id: rooms.id, status: rooms.status });
  if (!updated) return err(notFound(`room ${id} not found`));
  return ok(updated);
}

export const roomRoutes: FastifyPluginAsyncTypebox = async (app) => {
  app.get("/rooms", { schema: { response: { 200: S.RoomsList } } }, async () =>
    db.select(roomSummaryCols).from(rooms).orderBy(desc(rooms.insertedAt)).limit(200),
  );

  app.get(
    "/rooms/:id",
    { schema: { params: S.RoomParams, response: { 200: S.RoomDetail, 404: S.ErrorResponse } } },
    async (req, reply) => send(reply, await getRoom(req.params.id)),
  );

  app.patch(
    "/rooms/:id/status",
    {
      schema: {
        params: S.RoomParams,
        body: S.RoomStatusBody,
        response: { 200: S.RoomStatusResult, 404: S.ErrorResponse },
      },
    },
    async (req, reply) => send(reply, await setRoomStatus(req.params.id, req.body.status)),
  );
};
