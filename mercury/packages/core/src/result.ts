/**
 * Error-as-value primitives. Re-exports neverthrow's Result type and helpers,
 * and ts-pattern's matcher, so the surface has one import for both. The handler
 * style is: a pure function returns a Result, and a thin adapter matches it to a
 * transport response. See the Mercury research piece on functional patterns.
 */
export * from "neverthrow";
export { match, P } from "ts-pattern";
