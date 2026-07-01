# Mercury · The workspace, its layout, principles, and developer roadmap

Mercury is one pnpm workspace, split between a generic Echo core and the codemojex product. This article is the developer's map: the layout as it stands after the restructure, the principles that hold it together, what ships today, and the roadmap from the running admin to a `@echo/mq` bus. Decision of record: the earlier `mercury/echo/` layout described in `docs/mercury-echo-architecture.md` is superseded here — the core packages moved under `packages/`, the product moved under `codemojex/`, and `@echo/core` was made namespace-agnostic with a BCS registry rather than carrying a fixed product namespace set.

## The layout

pnpm reads a `pnpm-workspace.yaml` to find the member packages. An internal dependency is declared with the `workspace:*` protocol, which refuses to resolve to anything other than the local workspace package; the workspace keeps a single root lockfile; and `pnpm -r` runs scripts in topological order over the dependency graph, so a package builds before its dependents. Strictness is preserved by construction: a package can import only what its own `package.json` declares.

The tree:

```text
packages/
  core/      @echo/core      identity format, BCS gate, namespace registry,
                             schema builders, effect vocabulary, env reader
  fx/        @echo/fx        Rust-to-wasm codec, Snowflake minter, routing hash
  cluster/   @echo/cluster   warm-before-serve multicore HTTP runtime
codemojex/
  packages/
    domain/  @codemojex/domain   the codemojex namespace set + typed ids
    db/      @codemojex/db        Drizzle read model over Postgres
  apps/
    admin/   @codemojex/admin     Fastify console on @echo/cluster
docs/                             architecture notes
```

The split is the point. `packages/` is generic Echo, with no product namespace anywhere inside it; `codemojex/` is the product. Keeping reusable packages apart from deployable apps is the standard workspace shape, and here it draws the same line the BCS registry draws in the type system — the core owns the format, the product owns the set.

## The principles

A handful of rules hold across the tree, and across the boundary into the Elixir umbrella.

NO-INVENT: only real modules, files, and committed outputs are cited; a surface a chapter will build is written as a thing the chapter builds. Generic core, product owns namespaces: the core knows the id format and the gate but no namespace set, and the product declares its set with `defineNamespaces` and runs its pipelines against the returned registry. One identity contract: a fourteen-byte branded id sits under every record that crosses Postgres or ValKey, the same string on the Elixir and TypeScript sides. Error as value: a boundary returns a result rather than throwing, and the gate is the worked example. Warm before serve: a worker binds its port only after its warm-up resolves, so the kernel never routes to a cold worker. The voice gate: every article passes the sweep before it ships, losses recorded beside wins. The umbrella side of these principles is the subject of `docs/mercury-echo-architecture.md`.

## What ships today

`@echo/core` carries the generic identity, the gate, the registry, the schema builders, the effect vocabulary, and the env reader, built and tested. `@echo/cluster` is the warm-before-serve runtime over a Node and a Bun backend, with the supervisor proven against a fake transport and live under the admin. `@echo/fx` is the Rust-to-wasm codec, minter, and routing hash, shipped prebuilt so a clean install needs no Rust toolchain. `@codemojex/domain` and `@codemojex/db` are the namespace set and the read model. `@codemojex/admin` is the Fastify console, running clustered against live Postgres and ValKey, withholding the game secret and validating ids at the registry-bound edge. The reading of that running system, branch by branch, is `docs/codemojex-bun-eff.md`.

## The roadmap

Near term: the admin on the Bun backend, and parity of the `@echo/fx` routing hash with the Elixir contract vector. Mid term: a `@echo/wire` RESP connector and a `@echo/mq` bus on ValKey Streams, both built on the identity contract — the compliance ground for that bus is `docs/bcs-echo-mq-bus.md`.

On the horizon is ephemeral job execution. The FLAME pattern — Fleeting Lambda Application for Modular Execution, introduced by Chris McCord — runs code in short-lived machines without standing up queues or storage, and its author notes that any language with reasonable concurrency primitives can take advantage of the pattern. The surface targets that model for short-lived jobs on Fly Machines, with the bus feeding the work. The admin-specific near-term plan and gate ladder are in `docs/codemojex-admin-roadmap.md`.

## Extending the workspace

The recipe is one package and one call. A new application creates a domain package and declares its namespaces against the same registry, and in return it gets typed ids, a bound gate, and bound schemas, with a typo of an unregistered namespace caught at compile time:

```ts
import { defineNamespaces, type BrandedId } from "@echo/core";

export const APP = defineNamespaces({ USR: "user", ORD: "order" } as const);
export type OrderId = BrandedId<"ORD">;
```

It then plugs the registry in at its boundaries — `APP.idSchema("ORD")` on a route parameter, `APP.gate("ORD", value)` at a seam — and mints and decodes through `@echo/fx`, which carries the core brand. `packages/core` and `packages/fx` do not change; each app registers its own set and runs its own pipelines. The step-by-step form of this recipe is the workspace README.

## What is proposed

Named as proposed, not shipped: the admin on the Bun backend; `@echo/fx` hash parity with the Elixir contract; the `@echo/wire` connector; the `@echo/mq` bus; and ephemeral job execution on Fly Machines. Everything else in this article is in the tree and built.

## References

- pnpm workspaces: the `workspace:*` protocol, the single root lockfile, and topological `pnpm -r`: `https://pnpm.io/workspaces`
- FLAME — Fleeting Lambda Application for Modular Execution, ephemeral machines, and the note that any language with reasonable concurrency primitives can use the pattern: `https://fly.io/blog/rethinking-serverless-with-flame/`
