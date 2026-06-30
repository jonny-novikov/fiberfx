/**
 * Effect-as-value vocabulary, layered on neverthrow. `Eff` is a synchronous
 * result, `EffAsync` an asynchronous one; `attempt` wraps a throwing function and
 * `attemptAsync` a promise, both turning exceptions into typed errors. The BCS
 * `gate` is the concrete effect the surface uses at its boundaries: a pure
 * function returns an `Eff`, and a thin adapter matches it to a transport reply.
 */
import { Result, ResultAsync } from "neverthrow";

/** A synchronous result: a value of `T` or a typed error `E`. */
export type Eff<T, E = Error> = Result<T, E>;

/** An asynchronous result. */
export type EffAsync<T, E = Error> = ResultAsync<T, E>;

/** Wrap a throwing function so it returns an `Eff` instead of raising. */
export const attempt = Result.fromThrowable;

/** Wrap a promise so it resolves to an `EffAsync` instead of rejecting. */
export const attemptAsync = ResultAsync.fromPromise;
