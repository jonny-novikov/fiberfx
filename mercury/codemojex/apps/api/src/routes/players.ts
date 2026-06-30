import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { z } from "zod";
import { eq } from "drizzle-orm";
import { players } from "@codemojex/db";
import { Players, idParam, paginationQuery, errorResponse } from "@codemojex/dto";

const deleted = z.object({ deleted: z.boolean() });

export async function playerRoutes(fastify: FastifyInstance) {
  const app = fastify.withTypeProvider<ZodTypeProvider>();
  const params = idParam("PLR");

  app.get(
    "/players",
    { schema: { querystring: paginationQuery, response: { 200: z.array(Players.playerSelect) } } },
    async (req) => {
      const { limit, offset } = req.query;
      return await app.db.select().from(players).limit(limit).offset(offset);
    },
  );

  app.get(
    "/players/:id",
    { schema: { params, response: { 200: Players.playerSelect, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.select().from(players).where(eq(players.id, req.params.id)).limit(1);
      if (!row) throw app.httpErrors.notFound("player not found");
      return row;
    },
  );

  app.post(
    "/players",
    { schema: { body: Players.createPlayerBody, response: { 201: Players.playerSelect } } },
    async (req, reply) => {
      const [row] = await app.db.insert(players).values(req.body).returning();
      reply.code(201);
      return row!;
    },
  );

  app.patch(
    "/players/:id",
    { schema: { params, body: Players.updatePlayerBody, response: { 200: Players.playerSelect, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.update(players).set(req.body).where(eq(players.id, req.params.id)).returning();
      if (!row) throw app.httpErrors.notFound("player not found");
      return row;
    },
  );

  app.delete(
    "/players/:id",
    { schema: { params, response: { 200: deleted } } },
    async (req) => {
      await app.db.delete(players).where(eq(players.id, req.params.id));
      return { deleted: true };
    },
  );
}
