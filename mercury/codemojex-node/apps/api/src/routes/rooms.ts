import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { z } from "zod";
import { eq } from "drizzle-orm";
import { rooms } from "@codemojex/db";
import { Rooms, idParam, paginationQuery, errorResponse } from "@codemojex/dto";

const deleted = z.object({ deleted: z.boolean() });

export async function roomRoutes(fastify: FastifyInstance) {
  const app = fastify.withTypeProvider<ZodTypeProvider>();
  const params = idParam("ROM");

  app.get(
    "/rooms",
    { schema: { querystring: paginationQuery, response: { 200: z.array(Rooms.roomSelect) } } },
    async (req) => {
      const { limit, offset } = req.query;
      return await app.db.select().from(rooms).limit(limit).offset(offset);
    },
  );

  app.get(
    "/rooms/:id",
    { schema: { params, response: { 200: Rooms.roomSelect, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.select().from(rooms).where(eq(rooms.id, req.params.id)).limit(1);
      if (!row) throw app.httpErrors.notFound("room not found");
      return row;
    },
  );

  app.post(
    "/rooms",
    { schema: { body: Rooms.createRoomBody, response: { 201: Rooms.roomSelect } } },
    async (req, reply) => {
      const [row] = await app.db.insert(rooms).values(req.body).returning();
      reply.code(201);
      return row!;
    },
  );

  app.patch(
    "/rooms/:id",
    { schema: { params, body: Rooms.updateRoomBody, response: { 200: Rooms.roomSelect, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.update(rooms).set(req.body).where(eq(rooms.id, req.params.id)).returning();
      if (!row) throw app.httpErrors.notFound("room not found");
      return row;
    },
  );

  app.delete(
    "/rooms/:id",
    { schema: { params, response: { 200: deleted } } },
    async (req) => {
      await app.db.delete(rooms).where(eq(rooms.id, req.params.id));
      return { deleted: true };
    },
  );
}
