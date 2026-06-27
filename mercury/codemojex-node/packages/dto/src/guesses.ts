import { z } from "zod";
import { createInsertSchema, createSelectSchema } from "drizzle-zod";
import { guesses } from "@codemojex/db";

// Append-only: select + create only (no update/delete DTOs).
export const guessSelect = createSelectSchema(guesses);
export const guessInsert = createInsertSchema(guesses);

export const createGuessBody = guessInsert.omit({ inserted_at: true });
export const guessResponse = guessSelect;

export type Guess = z.infer<typeof guessSelect>;
export type CreateGuess = z.infer<typeof createGuessBody>;
