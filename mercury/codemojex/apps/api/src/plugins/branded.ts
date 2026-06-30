// branded.ts — the Fastify integration for @echo/core branded ids.
//
// The branded-id contract (the pure codec + the nominal `BrandedId` type) lives
// in @echo/core; this is its Fastify edge. The serialization problem dissolves
// by construction: the branded string IS the wire type, so params, bodies and
// replies never carry a bigint near a serializer. What remains is validation,
// and that belongs to the schema compiler — one pass, before the handler, 400
// on failure — not to handler code. Two pieces: an ajv plugin registering one
// format per namespace, and a TypeBox constructor whose static type is the
// branded type, so the type provider infers BrandedId<'CRS'> for request.params
// with no casts.

import type { Ajv } from "ajv";
import { Type } from "@sinclair/typebox";
import { isBrandedId, inNamespace } from "@echo/core";
import type { BrandedId } from "@echo/core";

/** Ajv plugin: pass via Fastify({ ajv: { plugins: [brandedFormats([...])] } }). */
export const brandedFormats = (namespaces: readonly string[]) => (ajv: Ajv): Ajv => {
  ajv.addFormat("branded-id", { type: "string", validate: isBrandedId });
  for (const ns of namespaces) {
    ajv.addFormat(`branded-${ns.toLowerCase()}`, { type: "string", validate: inNamespace(ns) });
  }
  return ajv;
};

/** Schema constructor: JSON-schema shape for the validator, branded type for
 *  inference. Wrong-namespace ids fail validation — a USR id on a CRS route is
 *  a 400 before the handler runs, the gate doctrine as HTTP. */
export const TBranded = <N extends string>(ns: N) =>
  Type.Unsafe<BrandedId<N>>({
    type: "string",
    format: `branded-${ns.toLowerCase()}`,
    minLength: 14,
    maxLength: 14,
  });
