/**
 * codemojex admin — an operator surface for browsing rooms, active games, and
 * players, plus light management. Postgres (via @codemojex/db) is the system of
 * record; ValKey (:6390) is read for the live board. The server never scores or
 * mutates game state beyond explicit management endpoints.
 *
 * Routes are schema-driven through the TypeBox type provider: one schema per
 * route yields the static types, the request validator, and the response
 * serializer, and the response schemas omit the game secret so it is stripped at
 * the wire.
 *
 * This module is a library: `buildServer` constructs the app without listening
 * (used by the cluster worker after `warmup`), and `start` is the standalone
 * single-process path. Closing the app also quits ValKey and ends the Postgres
 * pool through an onClose hook, so one `app.close()` drains everything.
 */
import "dotenv/config";
import Fastify from "fastify";
import type { FastifyInstance } from "fastify";
import cors from "@fastify/cors";
import sensible from "@fastify/sensible";
import { TypeBoxValidatorCompiler } from "@fastify/type-provider-typebox";
import type { TypeBoxTypeProvider } from "@fastify/type-provider-typebox";
import type { Redis } from "iovalkey";
import { sql } from "@codemojex/db";
import type { Env } from "./env.js";
import { loadEnv } from "./env.js";
import { makeValkey, valkeyPing } from "./valkey.js";
import { roomRoutes } from "./routes/rooms.js";
import { gameRoutes } from "./routes/games.js";
import { playerRoutes } from "./routes/players.js";

declare module "fastify" {
  interface FastifyInstance {
    valkey: Redis;
  }
}

/** Build the configured app. Does not listen. */
export function buildServer(env: Env): FastifyInstance {
  const app = Fastify({ logger: { level: env.logLevel } })
    .setValidatorCompiler(TypeBoxValidatorCompiler)
    .withTypeProvider<TypeBoxTypeProvider>();

  // Stamp the answering worker so fan-out is observable (supervisor sets the env).
  const workerTag = process.env.ECHO_CLUSTER_WORKER ?? "solo";
  app.addHook("onSend", async (_req, reply, payload) => {
    reply.header("x-echo-worker", workerTag);
    return payload;
  });

  app.register(cors, { origin: true });
  app.register(sensible);

  const vk = makeValkey(env);
  app.decorate("valkey", vk);

  app.get("/health", async () => {
    const valkey = await valkeyPing(app.valkey);
    let postgres = false;
    try {
      await sql`select 1`;
      postgres = true;
    } catch {
      postgres = false;
    }
    return { ok: postgres && valkey, postgres, valkey, worker: workerTag };
  });

  app.register(roomRoutes);
  app.register(gameRoutes);
  app.register(playerRoutes);

  app.addHook("onClose", async () => {
    await vk.quit();
    await sql.end({ timeout: 5 });
  });

  return app;
}

/** Standalone single-process entry: build, listen, drain on signal. */
export async function start(): Promise<void> {
  const env = loadEnv();
  const app = buildServer(env);
  await app.ready();
  const close = async (signal: string): Promise<void> => {
    app.log.info({ signal }, "shutting down");
    await app.close();
    process.exit(0);
  };
  process.on("SIGINT", () => void close("SIGINT"));
  process.on("SIGTERM", () => void close("SIGTERM"));
  await app.listen({ host: env.host, port: env.port });
}
