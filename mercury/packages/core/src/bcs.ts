/**
 * The BCS boundary gate — error-as-value.
 *
 * Mirrors `EchoData.Bcs.gate/2`: it admits an id of exactly one namespace and
 * refuses everything else, adding no second parser. The namespace it admits is a
 * PARAMETER, so a boundary (a context, a route, a consumer) declares what it
 * accepts at the call site rather than core hardcoding a set.
 *
 * Core has no wasm, so the gate returns the branded id (shape + namespace
 * checked), not the decoded Snowflake — that decode is `@echo/fx`. The error
 * mirrors the Elixir gate: `"namespace"` when the id is well-formed but of the
 * wrong namespace, `"invalid"` when it is not a branded id at all.
 */
import { ok, err, type Result } from "neverthrow";
import { type BrandedId, BRANDED_ID_RE, namespaceOf } from "./branded.js";

export type GateError = "namespace" | "invalid";

/** Admit `value` iff it is a well-formed branded id in namespace `ns`. */
export function gate<NS extends string>(value: unknown, ns: NS): Result<BrandedId<NS>, GateError> {
  if (typeof value !== "string" || !BRANDED_ID_RE.test(value)) return err("invalid");
  if (value.slice(0, 3) !== ns) return err("namespace");
  return ok(value as BrandedId<NS>);
}

/** Raising form of {@link gate}. */
export function gateOrThrow<NS extends string>(value: unknown, ns: NS): BrandedId<NS> {
  const r = gate(value, ns);
  if (r.isOk()) return r.value;
  if (r.error === "namespace") {
    throw new TypeError(`expected namespace ${ns}, got ${namespaceOf(String(value)) ?? "?"}`);
  }
  throw new TypeError("invalid branded id");
}
