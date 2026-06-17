---
name: echomq-umbrella-app
description: "apps/echomq is the EchoMQ bus (a vendored BullMQ port) now wired into the echo umbrella as the 5th app; library-only, full test suite HANGS"
metadata: 
  node_type: memory
  type: project
  originSessionId: 115257c9-0f9f-4c20-8429-887322132a0e
---

**`apps/echomq`** is the **EchoMQ bus** the portal roadmap reserves for the **M4 multi-runtime tier (F7–F9)** — see `docs/elixir/specs/portal.roadmap.md` (`EchoMQ (on BullMQ) is the bus between BEAM, Node, and Go`). It is a **complete vendored port of BullMQ** (Redis-backed job queue: workers, schedulers, flows, rate-limiting, the identical `priv/scripts/*.lua` BullMQ uses, telemetry/OpenTelemetry, `package.json`/`yarn.lock` JS provenance). `EchoMQ` v1.3.0, "Unified Polyglot Message Queue", source `github.com/codemoji/echomq`. It was dropped into `apps/echomq` wholesale and **untracked**, then **initialized into the umbrella on 2026-06-06**.

**What "initialize in umbrella" meant here** (it was a standalone project, not greenfield): convert `apps/echomq/mix.exs`'s project block to the umbrella four — `build_path/config_path/deps_path/lockfile → "../../"` (+ aligned `elixir: "~> 1.18"`); remove the standalone `apps/echomq/{deps,mix.lock}` (umbrella members share `../../deps` + `../../mix.lock`); `mix deps.get` from the umbrella root. **The lock change was purely additive — 21 insertions, 0 deletions, zero churn to any portal/phoenix/ecto/bandit pin** (the only overlaps — jason/telemetry/stream_data — were already satisfied by the locked versions), so the Operator's concurrent portal work was untouched. NOT committed (the user commits out-of-band); only tracked edit = `echo/mix.lock`.

**Key facts (non-obvious):**
- **LIBRARY app — NO `Application`/`mod:`, no supervision tree.** `application/0` is just `extra_applications: [:logger, :crypto]`. Consuming apps start `EchoMQ.RedisConnection` + `EchoMQ.Worker` in THEIR own trees. So echomq adds nothing to any running OTP tree.
- **echomq depends only on `{:echo_data, in_umbrella: true}`** (uses `EchoData.Snowflake` + `EchoData.Base62` in `lib/echomq/champ.ex` — the CHAMP "Channel Message Protocol" cross-runtime Elixir↔Node envelope), and reaches no other umbrella app.
- **Reads ZERO Mix config** (`Application.get_env(:echomq,…)` grep is empty) — Queue/Worker take Redis opts as direct args. Tests read **env vars** `REDIS_URL` (default `redis://localhost:6379`) + `ECHOMQ_TEST_PREFIX` (default `echomq_test`) via `EchoMQ.TestHelper`. So NO `config :echomq` block was wired into the umbrella root, and the app-local `apps/echomq/config/{config,test}.exs` is **dead** (umbrella loads only root config) + unused + inconsistent with echo_bot (which has no app-local config) — a cleanup candidate, left in place pending a decision.

**TEST GOTCHAS (these waste time):**
- **The FULL suite HANGS (24+ min, killed).** Several concurrency/stress files (`high_concurrency_test`, `multi_worker_test`, `stress_test`, `concurrency_*_test`) appear to run **untagged** (not `:integration`/`:slow`) and spin on worker/Redis timing. Do NOT run the whole suite blind. `test/test_helper.exs` excludes `[:integration, :slow]` by default; integration is opt-in (`--include integration`, needs Redis on :6379 — Redis IS up locally).
- **Pure slice is GREEN + fast:** `mix test test/echomq/backoff_test.exs test/echomq/champ_test.exs` → **39 tests, 0 failures, 0.5s** (all async, no Redis). Use small pure-file runs to validate echomq in-umbrella.
- **First `MIX_ENV=test` compile is SLOW (minutes), separate from `_build/dev`.** echomq declares heavy `:dev`/`:test` tooling deps (`credo` 257 files, `dialyxir` 67, `opentelemetry_api`, `excoveralls`, `mox`). A short `timeout` (90–120s) SIGTERM-kills it mid-compile so it never caches → every retry restarts. Let the first test-env compile finish with NO timeout, then tests are fast.
- echomq compiles CLEAN in-umbrella (dev): "Generated echomq app", 0 warnings on its own 20 files (the lone warning is third-party `redix`'s optional CAStore SSL path — benign).

## 2026-06-12 — frozen v1 push source in the Three Movements program

`apps/echomq` is now the **v1 line frozen at 1.3.0** plus the emq.1 build-pass surface (version fence
`echomq:2.0.0` in version.ex, fence/fence_error/id/migration modules; commits `d2d8266a` "[emq.1] specs +
implementation" and `d2252a32` "VALKEY IS THE BACKEND. NOT DRAGONFLY."). In the EchoMQ-in-Three-Movements
program ([[echo-mq-three-movements]]) it is the PUSH SOURCE: untouched while the movements run, dissolving
at program end (timing operator-owned; the /redis-patterns + /echomq courses still ground in its files).
The NEW library is the sibling **`apps/echo_mq`** (BCS 2.0 port, v2.0.0, lib-only, deps = in-umbrella
echo_data only, own RESP codec — no redix). Both apps share the `EchoMQ.*` namespace with ZERO module
overlap (only echomq defines bare `EchoMQ`; echo_mq's mix project module is `EchoMq.MixProject` to dodge
the v1 `EchoMQ.MixProject` collision — umbrella loads every child mix.exs into one VM). Nothing depends on
`:echomq` (dropping it is compile-safe); `apps/echo_cache` depends on `:echo_mq`. Test-suite tagging today:
test_helper excludes `[:integration, :slow]` + engine tags; the remaining bare-`mix test` hang hazards are
the untagged Redis-touching files (flow_producer/obliterate/redis_baseline + 6 ConformanceCase files) —
per-app pure slices stay the safe gate.
