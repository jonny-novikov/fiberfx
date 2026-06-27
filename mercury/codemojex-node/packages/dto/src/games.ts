import { z } from "zod";
import { createInsertSchema, createSelectSchema, createUpdateSchema } from "drizzle-zod";
import { games } from "@codemojex/db";
import { GAME_STATUSES, GAME_TYPES } from "@codemojex/types";

export const gameSelect = createSelectSchema(games);
export const gameInsert = createInsertSchema(games);
export const gameUpdate = createUpdateSchema(games);

/** Columns the server keeps private — never serialized to players. */
export const gamePublic = gameSelect.omit({ secret: true, nonce: true, commitment: true });

export const createGameBody = gameInsert
  .omit({ inserted_at: true, updated_at: true })
  .extend({
    type: z.enum(GAME_TYPES).default("classic"),
    status: z.enum(GAME_STATUSES).default("open"),
  });

export const updateGameBody = gameUpdate
  .omit({ id: true, inserted_at: true, updated_at: true })
  .extend({
    type: z.enum(GAME_TYPES).optional(),
    status: z.enum(GAME_STATUSES).optional(),
  });

export type Game = z.infer<typeof gameSelect>;
export type GamePublic = z.infer<typeof gamePublic>;
export type CreateGame = z.infer<typeof createGameBody>;
export type UpdateGame = z.infer<typeof updateGameBody>;
