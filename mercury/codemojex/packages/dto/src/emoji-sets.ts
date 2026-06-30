import { z } from "zod";
import { createInsertSchema, createSelectSchema, createUpdateSchema } from "drizzle-zod";
import { emoji_sets } from "@codemojex/db";

export const emojiSetSelect = createSelectSchema(emoji_sets);
export const emojiSetInsert = createInsertSchema(emoji_sets);
export const emojiSetUpdate = createUpdateSchema(emoji_sets);

export const createEmojiSetBody = emojiSetInsert.omit({ inserted_at: true, updated_at: true });
export const updateEmojiSetBody = emojiSetUpdate.omit({ id: true, inserted_at: true, updated_at: true });
export const emojiSetResponse = emojiSetSelect;

export type EmojiSet = z.infer<typeof emojiSetSelect>;
export type CreateEmojiSet = z.infer<typeof createEmojiSetBody>;
export type UpdateEmojiSet = z.infer<typeof updateEmojiSetBody>;
