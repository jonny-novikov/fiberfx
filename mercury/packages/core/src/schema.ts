/**
 * TypeBox schema builders for the surface. One schema drives validation,
 * serialization, and the static type at once. The branded-id builder attaches
 * the nominal BrandedId<NS> type to a pattern-checked string, so a route's
 * params are typed and shape-validated from a single definition.
 */
import { Type, type Static, type TSchema } from "@sinclair/typebox";
import type { Namespace } from "./namespace.js";
import type { BrandedId } from "./branded.js";

export { Type };
export type { Static, TSchema };

/**
 * A branded-id schema for `ns`: a fixed-length, pattern-checked string whose
 * static type is BrandedId<NS>. The pattern rejects a malformed id at the
 * validator; the authoritative decode remains `@echo/fx`.
 */
export function BrandedIdSchema<NS extends Namespace>(
  ns: NS,
  opts: { description?: string } = {},
) {
  return Type.Unsafe<BrandedId<NS>>(
    Type.String({
      pattern: `^${ns}[0-9A-Za-z]{11}$`,
      minLength: 14,
      maxLength: 14,
      description: opts.description ?? `${ns} branded id`,
    }),
  );
}

/** Allow a schema's value to also be null (mirrors a nullable column). */
export function Nullable<T extends TSchema>(schema: T) {
  return Type.Union([schema, Type.Null()]);
}
