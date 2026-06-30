# Mercury · codemojex on Bun, pattern matching, and the eff subsystem
<show-structure depth="2"/>

codemojex — the real-money emoji-Mastermind game — is the product that rides the Mercury surface. This article reads the running system as code: the package graph as it stands after the workspace restructure, the Bun runtime the surface targets and why JavaScriptCore is the reason, ts-pattern at the decision branches, and the neverthrow-backed effect subsystem that moves errors as values from a boundary to the wire. The companion pieces argue the runtime and library choices from first principles; this one shows the choices in place.

## The system as built

The workspace splits between a generic Echo core and the codemojex product. The core is three packages — `@echo/core` (the identity format, the boundary gate, the namespace registry, schema builders, the effect vocabulary, a typed environment reader), `@echo/fx` (a Rust-to-wasm codec, Snowflake minter, and routing hash), and `@echo/cluster` (a warm-before-serve multicore HTTP runtime). None of the three names a product namespace.

The product sits above them. `@codemojex/domain` declares the codemojex namespace set against the core registry and exports the typed id aliases. `@codemojex/db` is the Drizzle read model over Postgres, the system of record the Elixir umbrella writes. `@codemojex/admin` is a Fastify console that reads Postgres and the ValKey live tier, withholds the game secret by column selection, and runs on `@echo/cluster`. The envisioned shape of the surface is in the companion `docs/mercury-echo-architecture.md`; the full layout and roadmap are in `docs/mercury-layout-roadmap.md`.

## The Bun runtime, and why JavaScriptCore

Bun extends JavaScriptCore, the engine built for Safari, and is built for fast start times. The reason the surface targets it is the functional core: the type system rewards a recursion-heavy style, and JavaScriptCore is the one major engine that implements the ES2015 proper-tail-call standard, where V8 (Node) and SpiderMonkey do not. A tail-recursive function that overflows the stack on a V8 runtime runs in constant stack on JavaScriptCore — the limit was the engine, not the language.

For multiple cores, Bun binds the same port across processes through the `reusePort` option, which sets the Linux `SO_REUSEPORT` socket flag so the kernel load-balances incoming connections across the processes. This is Linux only — Windows and macOS ignore the flag. Bun also implements `node:cluster`, documented as implemented but not battle-tested, with cross-process TCP load-balancing limited to Linux through the same socket option.

The trade-off is named in the source: each `reusePort` process is independent — no primary-to-worker channel, and no built-in per-worker restart in the bare loop. That gap is what `@echo/cluster` closes. It wraps an abstract transport with a supervisor that holds a worker out of rotation until its warm-up resolves, respawns a crashed worker back into the same logical slot, and rolls a new generation to ready before it drains the old one. The admin runs on `@echo/cluster` over the Node backend today; the Bun backend is the same supervisor over `Bun.spawn` and `reusePort` instead of `node:cluster`. The engine survey behind this is `docs/echo-runtime-engines.md`.

## Pattern matching at the branches

ts-pattern is the exhaustive matcher the surface reaches for: `import { match, P }`, then `.with(pattern, handler)` chained to `.exhaustive()`. Its value is that a forgotten case is a compile error rather than a branch that silently falls through — the checker proves the union is covered. `@echo/core` re-exports `match` and `P` next to the result type so a handler module has one import for both.

The branch style is functional: each case is a handler that returns a value, the matcher routes the input, and exhaustiveness checks the cover. The error channel of the boundary gate is a string-literal union, which is the cleanest thing ts-pattern can check:

```ts
import { match, type GateError } from "@echo/core";

// GateError is "namespace" | "invalid"; .exhaustive() fails the build
// if a new variant is added and not handled here.
function statusFor(e: GateError): number {
  return match(e)
    .with("namespace", () => 404)
    .with("invalid", () => 400)
    .exhaustive();
}
```

The same shape carries domain unions — a guess outcome, a room state — where the discriminant is a tag and each branch is a pure function of the matched value.

## The eff subsystem

The effect subsystem is error-as-value, layered on neverthrow. A `Result<T, E>` is either `Ok` carrying a `T` or `Err` carrying a typed `E`, built with `ok` and `err`; a `ResultAsync<T, E>` wraps a `Promise<Result<T, E>>` with the same combinators, and `fromThrowable` and `fromPromise` turn throwing code into a result. `@echo/core` names this vocabulary in `eff.ts`:

```ts
import { Result, ResultAsync } from "neverthrow";

export type Eff<T, E = Error> = Result<T, E>;
export type EffAsync<T, E = Error> = ResultAsync<T, E>;
export const attempt = Result.fromThrowable;
export const attemptAsync = ResultAsync.fromPromise;
```

The concrete effect at a trust boundary is the BCS gate. It admits an id of one namespace and refuses everything else, returning a result the caller branches on rather than throwing an exception that unwinds the request:

```ts
export function gate<NS extends string>(
  value: unknown,
  ns: NS,
): Result<BrandedId<NS>, GateError> {
  if (typeof value !== "string" || !BRANDED_ID_RE.test(value)) return err("invalid");
  if (value.slice(0, 3) !== ns) return err("namespace");
  return ok(value as BrandedId<NS>);
}
```

Because the error is the string union `"namespace" | "invalid"`, the gate composes with the matcher above: a pure function returns an `Eff`, and a thin adapter maps the error to a transport status. Nothing on this path throws, so nothing climbs the stack looking for a catch.

## The admin boundary

The admin composes the three. A TypeBox schema bound to the registry — `CM.idSchema("GAM")` — validates a route parameter at the door, so a malformed id is rejected at the validator with a 400 before a handler runs; a typo of an unregistered namespace is a compile error, because the schema comes from the registry. The handler returns a result, and the reply adapter turns the error channel into a status. The serializer lists only the public columns, so the game secret and the keyboard snapshot are dropped at the wire even if a query ever selected them — withholding by serializer contract.

The bench bears this out. A real game id returns the game, board, and guesses with no `secret` and no `keyboard` field; a malformed id is a 400 on the pattern `^GAM[0-9A-Za-z]{11}$`; a well-formed but unknown id is a 404; and under two clustered workers, requests fan out across both. The near-term plan for the admin — the Bun foundation and the operator dashboard — is `docs/codemojex-admin-roadmap.md`.

## What is real versus proposed

Real today: the package graph above; `@echo/core` carrying the gate, the registry, and the effect vocabulary; `@echo/cluster` proven over the Node backend; and the admin running clustered against live Postgres and ValKey, with the withholding and validation guarantees verified in the bench. Proposed: the admin on the Bun backend, and parity of the `@echo/fx` routing hash with the Elixir contract — the wasm hash is parity-pending, asserted against the contract vector but not yet certified in the build. These are named on the horizon, not folded into the claims.

## References

- Bun extends JavaScriptCore and is built for fast start: `https://bun.sh/`
- A V8 runtime overflows on a tail-recursive function that JavaScriptCore runs in constant stack: `https://www.onsclom.net/posts/javascript-tco`
- Bun `reusePort` and the Linux `SO_REUSEPORT` socket option for multi-process load balancing: `https://bun.com/docs/guides/http/cluster`
- Bun's `node:cluster` implementation, Linux-only cross-process TCP balancing, "implemented but not battle-tested": `https://bun.com/reference/node/cluster`
- ts-pattern, exhaustive `match`/`P` and `.exhaustive()` with compile-time cover checking: `https://github.com/gvergnaud/ts-pattern`
- neverthrow `Result`/`ResultAsync`, `ok`/`err`, `fromThrowable`/`fromPromise`: `https://github.com/supermacro/neverthrow`
