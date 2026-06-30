import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { z } from "zod";
import { eq } from "drizzle-orm";
import { emoji_sets } from "@codemojex/db";
import { EmojiSets, idParam, paginationQuery, errorResponse } from "@codemojex/dto";

const deleted = z.object({ deleted: z.boolean() });

export async function emojiSetRoutes(fastify: FastifyInstance) {
  const app = fastify.withTypeProvider<ZodTypeProvider>();
  const params = idParam("EMS");

  app.get(
    "/emoji-sets",
    { schema: { querystring: paginationQuery, response: { 200: z.array(EmojiSets.emojiSetSelect) } } },
    async (req) => {
      const { limit, offset } = req.query;
      return await app.db.select().from(emoji_sets).limit(limit).offset(offset);
    },
  );

  app.get(
    "/emoji-sets/:id",
    { schema: { params, response: { 200: EmojiSets.emojiSetSelect, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.select().from(emoji_sets).where(eq(emoji_sets.id, req.params.id)).limit(1);
      if (!row) throw app.httpErrors.notFound("emoji set not found");
      return row;
    },
  );

  app.post(
    "/emoji-sets",
    { schema: { body: EmojiSets.createEmojiSetBody, response: { 201: EmojiSets.emojiSetSelect } } },
    async (req, reply) => {
      const [row] = await app.db.insert(emoji_sets).values(req.body).returning();
      reply.code(201);
      return row!;
    },
  );

  app.patch(
    "/emoji-sets/:id",
    { schema: { params, body: EmojiSets.updateEmojiSetBody, response: { 200: EmojiSets.emojiSetSelect, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.update(emoji_sets).set(req.body).where(eq(emoji_sets.id, req.params.id)).returning();
      if (!row) throw app.httpErrors.notFound("emoji set not found");
      return row;
    },
  );

  app.delete(
    "/emoji-sets/:id",
    { schema: { params, response: { 200: deleted } } },
    async (req) => {
      await app.db.delete(emoji_sets).where(eq(emoji_sets.id, req.params.id));
      return { deleted: true };
    },
  );
}
