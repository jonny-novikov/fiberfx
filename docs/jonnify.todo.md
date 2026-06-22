# Jonnify unsorted TODO

For Wordle and Mastermind, I'm reconsidering whether I need explicit URLs at all since the rules document already frames the game as "Wordle meets Mastermind"—I can probably describe the lineage inline without hunting down separate references. 
Oban is the only other external link I'm tracking for the Elixir queue trade-off. 
Let me focus on just those searches rather than chasing every possible citation. 
I need to run three searches for Wordle, Mastermind, and Oban to verify the URLs, then I can write the article. 
Include an academic reference on fair queueing as well as internal prose section.
For the references, I'm consolidating the Valkey documentation links—the sorted sets and ZADD command pages might be combined into a single reference. 
Looking up the documentation links for Mastermind and Oban.

```
First, analyze the Graft approach in https://github.com/orbitinghail/graft and harden Elixir implementation to fit the requirements on the way to EchoMQ 4+.
Second, rethink an approach for durability of EchoMQ as an Plugin - Postgres Journals, other options, local to develop.
What makes the Postgres journal implemented in EchoMQ beneficial over Oban fully backed by PostgreSQL? Mitigate single instance db but have reliable ValKey seems to be a balanced decision.
So, deliver new features in echo umbrella: new Graf features, EchoMQ Plug Support, Postgres Journaling.
```

## 2026-06-15 — Leftover

1. EchoMQ command registry.
2. Flip the emq.3.5 row [RECONCILE]→as-built (now that it shipped — a one-line tag edit, slug stays stable).
3. Remove the old emq.1.specs.md (the rename's other half).

## {echo_mq} {status=in_progress} emq.3.5 post-execution

```
File /Users/jonny/dev/jonnify/docs/echo_mq/emq.command-registry.md is drammatically big. The request was to create 1) a registy - echo_mq/commands/emq.commands.registry.md with
additional md table with reach column following existing pattern why, where.... 2) categorize by feature e.g. commands/groups.commands.md commands/batches.commands.md 3)
emq.commands.roadmap.md - extracted gaps, proposals, linking to roadmap emq.[N].[M] rungs.
```

## 2026-06-15 — Cross-runtime Lua script maintenance (echo_mq ⇄ echo_fs)

**Decision pending:** how to keep the server-side Lua scripts byte-identical across the
Elixir canon (`echo/apps/echo_mq`) and the in-progress F# port (`echo_fs/`), so they share
the Valkey script cache and behave identically.

### Why byte-identity is the whole game
The SHA is content-derived **client-side**, no server round-trip:
- Elixir: `echo/apps/echo_wire/lib/echo_mq/script.ex:14` — `:crypto.hash(:sha, source) |> Base.encode16(:lower)`
- F#: `echo_fs/EchoConnector/Script.fs:15` — SHA1 over `Encoding.UTF8.GetBytes`, lower-hex

Byte-identical source → identical SHA → shared cache entry → identical run. A one-byte drift
gives divergent SHAs (no shared cache) **and** possibly divergent behaviour — a silent
correctness bug the gates won't catch.

### Settled: each runtime carries its own SOURCE (not SHA-only)
`echo/apps/echo_wire/lib/echo_mq/connector.ex:60-82` runs `EVALSHA` first, and on
`NOSCRIPT` does `SCRIPT LOAD source` → asserts returned sha == `s.sha` (`{:sha_mismatch, _}`
on drift) → retries. A SHA-only F# client is rejected because:
1. **No NOSCRIPT self-recovery** — Valkey's script cache is per-node, volatile, non-replicated
   (FLUSH / restart / failover / reconnect-to-other-node → NOSCRIPT); SHA-only can't LOAD.
2. **Cross-runtime liveness coupling** — F# correctness would depend on Elixir having warmed
   *this* node. Each runtime must be a self-sufficient peer.
3. **No way to recover source from the server** — Valkey has no "dump loaded script" command
   (`SCRIPT EXISTS` only checks SHAs you already hold).

So `echo_fs` keeps `Source` in `Script.fs` (it already does); the real transport (today
`echo_fs/EchoConnector/Connector.fs:99-100` returns "EVAL … coming soon", the efs.valkey rung)
must mirror the lazy `EVALSHA → NOSCRIPT → LOAD → retry`. Preload-all (warmup) is an OPTIONAL
latency/fail-fast-integrity layer on top — never a replacement for the NOSCRIPT branch, and it
presupposes the source. Targeted precedent: `enqueue_many` loads the one script before its batch
(`echo/apps/echo_mq/lib/echo_mq/jobs.ex:101`).

### Open: how to enforce byte-identity (3 approaches, 5W matrix)

| | **A — Twin Inline + SHA Conformance** | **B — Single `.lua` + Codegen** | **C — Canonical Elixir as Oracle** |
|---|---|---|---|
| **What** | Both runtimes keep own inline copy (Elixir heredocs `jobs.ex`, F# `let`s in a `Scripts.fs`); committed golden `name→sha` table; each suite asserts its SHAs == table. | Lua lives once in canonical `.lua` files; a build-time generator emits both the Elixir attrs and F# `let`s, "GENERATED — do not edit". | `jobs.ex` is source of record; an Elixir test emits `script_shas.json` (registry of prod SHAs); F# vendors a mirror copy + asserts each `Script.create` SHA == registry. |
| **Why** | Lowest tooling; both stay idiomatic + self-contained; honours "inline, never priv/" natively. Pick when runtimes are true peers. | One source → byte-identity by construction; manual drift impossible. Pick at high script churn or when a 3rd runtime arrives. | Zero burden on the shipped runtime; guard self-updates (no hand table). Pick while F# is a follower — i.e. now. |
| **Who** | Each runtime's implementor owns its copy; evaluator owns the vector. | A generator-tool owner; both runtimes are pure consumers, never hand-edit. | Elixir implementor edits freely (oblivious to F#); F# author owns mirror + verify test. |
| **When (drift caught)** | Test time; risk = unmirrored edit ships unless golden table updated in lockstep. | Build time: "regenerate == committed" diff-gate (the `make sitemap` discipline); risk ≈ 0. | When F# suite runs — reads the live registry each run, so an Elixir edit fails F# immediately, no manual golden update. |
| **Where** | `jobs.ex` + `echo_fs/EchoMQ/Scripts.fs`; golden table as a shared fixture (the `nodes.json`↔`dataset-sync` mirror-test pattern). | Neutral `scripts/*.lua` dir (NOT `priv/` — keep it build-time-only so it can't be mistaken for a runtime read); generator under `cmd/`/`mix`. | `jobs.ex` heredocs + an Elixir oracle test emitting `script_shas.json`; mirror + verify in `echo_fs/EchoMQ.Tests`. |

**Recommendation: start with C** (cheapest faithful guard, no production-team burden,
self-updating; SHAs cross the boundary — not parsed Lua, so no brittle heredoc parser).
**Graduate to B** when a 3rd runtime appears or hand-mirroring gets costly. **A** only if F#
stops being a follower and the two become co-equal peers without wanting a generator.

> Note on B vs the "inline, never priv/" law: that law is about *runtime* reads. Codegen reads
> `.lua` at *build* time and bakes inline literals into the artifact — runtime stays inline. Keep
> the canonical `.lua` OUT of `priv/` so it isn't mistaken for a runtime load.

