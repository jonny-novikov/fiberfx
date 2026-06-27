import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { z } from "zod";
import { eq } from "drizzle-orm";
import { games } from "@codemojex/db";
import { Games, idParam, paginationQuery, errorResponse } from "@codemojex/dto";

// Reads serialize through `gamePublic`, which omits secret/nonce/commitment — the zod
// serializer strips those server-side columns from every response.
export async function gameRoutes(fastify: FastifyInstance) {
  const app = fastify.withTypeProvider<ZodTypeProvider>();
  const params = idParam("GAM");

  app.get(
    "/games",
    { schema: { querystring: paginationQuery, response: { 200: z.array(Games.gamePublic) } } },
    async (req) => {
      const { limit, offset } = req.query;
      return await app.db.select().from(games).limit(limit).offset(offset);
    },
  );

  app.get(
    "/games/:id",
    { schema: { params, response: { 200: Games.gamePublic, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.select().from(games).where(eq(games.id, req.params.id)).limit(1);
      if (!row) throw app.httpErrors.notFound("game not found");
      return row;
    },
  );

  app.post(
    "/games",
    { schema: { body: Games.createGameBody, response: { 201: Games.gamePublic } } },
    async (req, reply) => {
      const [row] = await app.db.insert(games).values(req.body).returning();
      reply.code(201);
      return row!;
    },
  );

  app.patch(
    "/games/:id",
    { schema: { params, body: Games.updateGameBody, response: { 200: Games.gamePublic, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.update(games).set(req.body).where(eq(games.id, req.params.id)).returning();
      if (!row) throw app.httpErrors.notFound("game not found");
      return row;
    },
  );
}
