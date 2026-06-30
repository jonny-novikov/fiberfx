# @echo/core

Pure-TypeScript primitives shared across the echo surface. No runtime dependency
on the WebAssembly kernel; `@echo/fx` stays the authority for the codec and hash.

- **Identity contract** — `BrandedId<NS>`, the namespace registry, `isBranded`,
  `namespaceOf`, `assertBranded`. A shape guard, not a codec.
- **Error-as-value** — re-exports neverthrow (`ok`, `err`, `Result`,
  `ResultAsync`) and ts-pattern (`match`, `P`).
- **Schemas** — `BrandedIdSchema(ns)` builds a TypeBox string whose static type
  is `BrandedId<NS>`, driving validation, serialization, and types from one
  definition.
- **Env** — `loadEnv` parses a typed, frozen environment once at boot; a missing
  required value fails the boot.

`@mercury/db` re-exports the identity contract from here, so the read model and
the surface share one definition.
