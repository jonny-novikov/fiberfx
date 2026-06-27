import { z } from "zod";
import { NAMESPACES, type Namespace } from "@codemojex/types";

const BRANDED_ID = /^[A-Z]{3}[0-9A-Za-z]{11}$/;

/** A branded id of a given namespace: 14 chars, `NS(3)+base62(11)`, nominally typed. */
export const brandedId = <B extends Namespace>(ns: B) =>
  z
    .string()
    .regex(BRANDED_ID, "must be a 14-char branded id")
    .refine((s) => s.startsWith(ns), { message: `expected namespace ${ns}` })
    .brand<B>();

/** `:id` path param for a resource of namespace `ns`. */
export const idParam = <B extends Namespace>(ns: B) => z.object({ id: brandedId(ns) });

/** List query: bounded limit/offset, coerced from the query string. */
export const paginationQuery = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});
export type PaginationQuery = z.infer<typeof paginationQuery>;

/** The error envelope Fastify / @fastify/sensible emit. */
export const errorResponse = z.object({
  statusCode: z.number(),
  error: z.string(),
  message: z.string(),
});

export const namespaces = NAMESPACES;
