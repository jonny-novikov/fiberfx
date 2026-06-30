/**
 * @echo/core — the pure-TypeScript primitives shared across the echo surface:
 * the branded-identity contract, error-as-value helpers, TypeBox schema
 * builders, and a typed environment reader. No runtime dependency on the wasm
 * kernel; the kernel (`@echo/fx`) remains the authority for the codec and hash.
 */
export * from "./namespace.js";
export * from "./branded.js";
export * from "./result.js";
export * from "./schema.js";
export * from "./env.js";
