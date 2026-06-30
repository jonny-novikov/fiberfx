import fp from "fastify-plugin";
import { createDb, type Database, type DbClient } from "@codemojex/db";

declare module "fastify" {
  interface FastifyInstance {
    db: Database;
    pool: DbClient["pool"];
  }
}

export interface DbPluginOptions {
  databaseUrl: string;
}

/** Opens one pg Pool + Drizzle instance for the app and decorates `fastify.db` / `fastify.pool`. */
export default fp<DbPluginOptions>(
  async (fastify, opts) => {
    const { pool, db } = createDb(opts.databaseUrl);
    fastify.decorate("db", db);
    fastify.decorate("pool", pool);
    fastify.addHook("onClose", async () => {
      await pool.end();
    });
  },
  { name: "db" },
);
