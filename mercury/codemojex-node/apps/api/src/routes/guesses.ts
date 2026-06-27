import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { z } from "zod";
import { and, eq } from "drizzle-orm";
import { guesses } from "@codemojex/db";
import { Guesses, idParam, paginationQuery, errorResponse, brandedId } from "@codemojex/dto";

// Append-only: list / get / create (no update or delete).
export async function guessRoutes(fastify: FastifyInstance) {
  const app = fastify.withTypeProvider<ZodTypeProvider>();
  const params = idParam("GES");
  const listQuery = paginationQuery.extend({
    game: brandedId("GAM").optional(),
    player: brandedId("PLR").optional(),
  });

  app.get(
    "/guesses",
    { schema: { querystring: listQuery, response: { 200: z.array(Guesses.guessSelect) } } },
    async (req) => {
      const { limit, offset, game, player } = req.query;
      const filters = [
        game ? eq(guesses.game, game) : undefined,
        player ? eq(guesses.player, player) : undefined,
      ].filter((c): c is NonNullable<typeof c> => c !== undefined);
      const where = filters.length ? and(...filters) : undefined;
      return await app.db.select().from(guesses).where(where).limit(limit).offset(offset);
    },
  );

  app.get(
    "/guesses/:id",
    { schema: { params, response: { 200: Guesses.guessSelect, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.select().from(guesses).where(eq(guesses.id, req.params.id)).limit(1);
      if (!row) throw app.httpErrors.notFound("guess not found");
      return row;
    },
  );

  app.post(
    "/guesses",
    { schema: { body: Guesses.createGuessBody, response: { 201: Guesses.guessSelect } } },
    async (req, reply) => {
      const [row] = await app.db.insert(guesses).values(req.body).returning();
      reply.code(201);
      return row!;
    },
  );
}
