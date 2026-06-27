import { z } from "zod";
import { createInsertSchema, createSelectSchema, createUpdateSchema } from "drizzle-zod";
import { players } from "@codemojex/db";

export const playerSelect = createSelectSchema(players);
export const playerInsert = createInsertSchema(players);
export const playerUpdate = createUpdateSchema(players);

export const createPlayerBody = playerInsert.omit({ inserted_at: true, updated_at: true });
export const updatePlayerBody = playerUpdate.omit({ id: true, inserted_at: true, updated_at: true });
export const playerResponse = playerSelect;

export type Player = z.infer<typeof playerSelect>;
export type CreatePlayer = z.infer<typeof createPlayerBody>;
export type UpdatePlayer = z.infer<typeof updatePlayerBody>;
