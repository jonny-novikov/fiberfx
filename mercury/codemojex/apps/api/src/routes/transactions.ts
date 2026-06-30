import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { z } from "zod";
import { and, eq } from "drizzle-orm";
import { transactions } from "@codemojex/db";
import { Transactions, idParam, paginationQuery, errorResponse, brandedId } from "@codemojex/dto";

// Append-only ledger: list / get / create.
export async function transactionRoutes(fastify: FastifyInstance) {
  const app = fastify.withTypeProvider<ZodTypeProvider>();
  const params = idParam("TXN");
  const listQuery = paginationQuery.extend({ player: brandedId("PLR").optional() });

  app.get(
    "/transactions",
    { schema: { querystring: listQuery, response: { 200: z.array(Transactions.transactionSelect) } } },
    async (req) => {
      const { limit, offset, player } = req.query;
      const where = player ? and(eq(transactions.player, player)) : undefined;
      return await app.db.select().from(transactions).where(where).limit(limit).offset(offset);
    },
  );

  app.get(
    "/transactions/:id",
    { schema: { params, response: { 200: Transactions.transactionSelect, 404: errorResponse } } },
    async (req) => {
      const [row] = await app.db.select().from(transactions).where(eq(transactions.id, req.params.id)).limit(1);
      if (!row) throw app.httpErrors.notFound("transaction not found");
      return row;
    },
  );

  app.post(
    "/transactions",
    { schema: { body: Transactions.createTransactionBody, response: { 201: Transactions.transactionSelect } } },
    async (req, reply) => {
      const [row] = await app.db.insert(transactions).values(req.body).returning();
      reply.code(201);
      return row!;
    },
  );
}
