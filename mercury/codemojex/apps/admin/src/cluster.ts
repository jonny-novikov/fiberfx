/**
 * Clustered entry: run the admin across cores with @echo/cluster.
 *
 * The same file is executed by the supervisor and by each worker. The bundle
 * warms first — build Fastify and `ready()`, which opens the ValKey and Postgres
 * pools — and only then serves, so a worker binds the port while already hot. The
 * admin uses the `node` backend (the `node:cluster` primary distributes), which
 * runs on Node now and on Bun later without change.
 */
import { runCluster } from "@echo/cluster";
import type { FastifyInstance } from "fastify";
import type { Env } from "./env";
import { loadEnv } from "./env";
import { buildServer } from "./server";

const port = Number(process.env.PORT ?? 3000);
const workersRaw = Number(process.env.WORKERS ?? 0);
const workers = workersRaw > 0 ? { workers: workersRaw } : {};

await runCluster<{ app: FastifyInstance; env: Env }>(
  {
    async warmup() {
      const env = loadEnv();
      const app = buildServer(env);
      await app.ready();
      return { app, env };
    },
    async serve({ app, env }, ctx) {
      await app.listen({ host: env.host, port: ctx.port });
      return { stop: () => app.close() };
    },
  },
  { port, backend: "node", ...workers },
);
