import { z } from "zod";
import { createInsertSchema, createSelectSchema, createUpdateSchema } from "drizzle-zod";
import { rooms } from "@codemojex/db";
import { ROOM_TYPES } from "@codemojex/types";

export const roomSelect = createSelectSchema(rooms);
export const roomInsert = createInsertSchema(rooms);
export const roomUpdate = createUpdateSchema(rooms);

export const createRoomBody = roomInsert
  .omit({ inserted_at: true, updated_at: true })
  .extend({ type: z.enum(ROOM_TYPES).default("classic") });

export const updateRoomBody = roomUpdate
  .omit({ id: true, inserted_at: true, updated_at: true })
  .extend({ type: z.enum(ROOM_TYPES).optional() });

export const roomResponse = roomSelect;

export type Room = z.infer<typeof roomSelect>;
export type CreateRoom = z.infer<typeof createRoomBody>;
export type UpdateRoom = z.infer<typeof updateRoomBody>;
