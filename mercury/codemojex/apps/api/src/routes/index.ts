import type { FastifyInstance } from "fastify";
import { healthRoutes } from "./health.js";
import { playerRoutes } from "./players.js";
import { roomRoutes } from "./rooms.js";
import { gameRoutes } from "./games.js";
import { guessRoutes } from "./guesses.js";
import { emojiSetRoutes } from "./emoji-sets.js";
import { transactionRoutes } from "./transactions.js";

/** Mounts every resource router. Registered under the `/api` prefix by the app. */
export async function routes(fastify: FastifyInstance) {
  await fastify.register(healthRoutes);
  await fastify.register(playerRoutes);
  await fastify.register(roomRoutes);
  await fastify.register(gameRoutes);
  await fastify.register(guessRoutes);
  await fastify.register(emojiSetRoutes);
  await fastify.register(transactionRoutes);
}
