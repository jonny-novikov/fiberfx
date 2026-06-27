import { z } from "zod";
import { createInsertSchema, createSelectSchema } from "drizzle-zod";
import { transactions } from "@codemojex/db";
import { CURRENCIES } from "@codemojex/types";

// Append-only ledger: select + create only.
export const transactionSelect = createSelectSchema(transactions);
export const transactionInsert = createInsertSchema(transactions);

export const createTransactionBody = transactionInsert
  .omit({ inserted_at: true })
  .extend({ currency: z.enum(CURRENCIES) });

export const transactionResponse = transactionSelect;

export type Transaction = z.infer<typeof transactionSelect>;
export type CreateTransaction = z.infer<typeof createTransactionBody>;
