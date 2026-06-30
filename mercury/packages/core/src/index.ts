/**
 * @echo/core — pure-TypeScript primitives shared across the echo surface. It
 * owns the branded-identity FORMAT (generic over the namespace), the BCS
 * boundary gate, the namespace registry an app plugs into, TypeBox schema
 * builders, error-as-value helpers, and a typed environment reader. It knows
 * nothing of any product's namespaces and has no runtime dependency on the wasm
 * kernel — `@echo/fx` remains the authority for the codec and routing hash.
 */
export * from "./branded.js";
export * from "./bcs.js";
export * from "./registry.js";
export * from "./schema.js";
export * from "./result.js";
export * from "./eff.js";
export * from "./env.js";
