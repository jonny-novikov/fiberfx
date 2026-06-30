/**
 * TypeBox schema builders. One schema drives validation, serialization, and the
 * static type at once. The branded-id builder is generic over the namespace: it
 * attaches the nominal `BrandedId<NS>` static to a pattern-checked string, so a
 * route's params are typed and shape-validated from a single definition. The
 * pattern rejects a malformed id at the validator; the authoritative decode is
 * `@echo/fx`.
 */
import { Type, type Static, type TSchema } from "@sinclair/typebox";
import type { BrandedId } from "./branded.js";

export { Type };
export type { Static, TSchema };

/** A branded-id schema for `ns`: fixed-length, pattern-checked, typed as `BrandedId<NS>`. */
export function BrandedIdSchema<NS extends string>(
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

/** The concrete schema type returned by {@link BrandedIdSchema} for `ns`. */
export type TBrandedId<NS extends string> = ReturnType<typeof BrandedIdSchema<NS>>;

/** Allow a schema's value to also be null (mirrors a nullable column). */
export function Nullable<T extends TSchema>(schema: T) {
  return Type.Union([schema, Type.Null()]);
}
