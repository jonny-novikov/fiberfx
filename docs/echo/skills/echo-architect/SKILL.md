---
name: echo-mq-architect
description: >-
  Provision a developer bench for the fiberfx echo_mq umbrella and boot codemojex
  end to end. Use whenever the user wants to set up, clone, download, or work on the
  fiberfx / echo_mq / EchoMQ / BCS source; says "clone the echo_mq branch", "set me up
  to work on echo_mq", "boot codemojex", "run the e2e", or needs a Valkey + Postgres +
  BEAM bench to run the EchoMQ connector and BCS components against. Trigger even when
  only the repo, branch, or EchoMQ/BCS is named. ALL STEPS ARE MANDATORY on the first
  call: env (+ $REPO_ROOT), clone, gcc, Valkey 9.1.0 BUILT FROM SOURCE + valkey-cli,
  PostgreSQL, Python, Go 1.25, Node 22+ with corepack + pnpm, `mix deps.get`,
  `mix compile`, `ecto.create` + migrate, a boot smoke, a FULL end-to-end game against
  live Postgres + Valkey, and a generated Markdown bootstrap report attached at the end.
  Bundles architecture references (vision, layering, per-component) under references/.
---

# echo-mq-architect

Stands up the bench for `jonny-novikov/fiberfx@echo_mq` and proves it by playing a real
game through the codemojex engine against live Postgres and Valkey. One entry point runs
every step in order:

```bash
bash scripts/bootstrap.sh
```

Every step is idempotent (detect-and-reuse / skip-if-present), so re-running is a fast
verify. Most tools install out of the box (package managers, precompiled releases). The
one deliberate exception is **Valkey, built from source** at the pinned 9.1.0 — the
source build links the bundled jemalloc (`mem_allocator: jemalloc-5.3.0`).

## Architecture references

This skill bundles a reference set for the umbrella it provisions, under `references/`.
Read these for the design context behind the bench — what the components are, how they
layer, and why — rather than re-deriving it from the source:

- `references/vision-and-purpose.md` — why Echo exists and the principles that hold across
  every app (branded identity owned by one module, native-or-pure parity, declared-not-
  discovered caches, fairness constructed not hashed, park-don't-poll, the named wire,
  boot-time self-checks, a single scoring authority).
- `references/architecture.md` — the dependency layering, the branded-id and Snowflake
  contract, the life of a request through all the tiers, the boot order, and the
  deployment surfaces.
- `references/components.md` — a page per application: `echo_data`, `echo_wire`, `echo_mq`,
  `echo_store`, `echo_bot`, `echo_graft`, and `codemojex`.
- `references/README.md` — the one-screen overview and the map of the set.

## Environment (step 1)

`setup_env.sh` writes `$BENCH_HOME/.bcs-env` (the single source of truth, also sourced
from `~/.bashrc`) and exports:

| var | default | meaning |
|-----|---------|---------|
| `BENCH_HOME` | `$HOME/.bcs-bench` | bench state, logs, the report |
| `REPO_ROOT` | `$HOME/src/fiberfx` | **the git checkout** |
| `UMBRELLA` | `$REPO_ROOT/echo` | the Elixir umbrella inside it |
| `GOROOT` / `GOPATH` | `/usr/local/go` / `$HOME/go` | Go toolchain |
| `GO_VERSION` | `1.25` | Go line |
| `NODE_MIN` | `22` | Node floor |
| `VALKEY_MIN` / `VALKEY_PREFERRED` | `8` / `9` | floor / preferred line |
| `VALKEY_VERSION` / `VALKEY_PORT` | `9.1.0` / `6390` | **from-source pin** / bus port |
| `ELIXIR_MIN` / `ELIXIR_PIN` | `1.15` / `1.18.4` | floor and repo pin |
| `OTP_MIN` | `25` | Elixir 1.18 runs on OTP 25-27 |

## Steps (all mandatory, in order)

| # | step | script | what |
|---|------|--------|------|
| 1 | env | `setup_env.sh` | exports above incl `$REPO_ROOT`; writes `.bcs-env` |
| 2 | clone | `clone_repo.sh` | `git clone --branch echo_mq git@github.com:jonny-novikov/fiberfx.git` (HTTPS fallback; ff-only pull if present) |
| 3 | apt base | `install_apt.sh` | gcc / build-essential, Python 3, git, curl, headers |
| 4 | valkey | `install_valkey.sh` | **Valkey 9.1.0 BUILT FROM SOURCE** + `valkey-cli`; floor-gated; started on `:6390` (bundled jemalloc) |
| 4b | postgres | `install_postgres.sh` | PostgreSQL (apt), started, dev role `postgres`/`postgres` on `:5432` |
| 5 | go | `install_go.sh` | Go 1.25 |
| 6 | node | `install_node.sh` | Node 22+ , corepack, pnpm |
| 6b | beam | `install_beam.sh` | Elixir (≥ 1.15, pin 1.18.4) + Erlang + rebar3 + Hex — see resolution |
| 7 | deps | `umbrella_deps.sh` | `mix deps.get` (mirror fallback on a blocking proxy) |
| 7b | compile | `compile.sh` | `mix compile` — whole umbrella incl `codemojex` |
| 7c | migrate | `migrate.sh` | `mix ecto.create` + `mix ecto.migrate` (`codemojex_dev`) |
| 8 | verify | `verify.py` | toolchain table / CI gate |
| 9 | smoke | `boot_smoke.sh` | mint a branded id in every namespace + score (no services) |
| 9b | **e2e** | `e2e.sh` + `e2e_game.exs` | **boot the app + play a real game** against live Postgres + Valkey |
| 10 | **report** | `report.py` | **MANDATORY** — writes `bootstrap-report.md`, which is attached |

## OTP / Elixir resolution

The existing distro BEAM is often **not** compatible with the pinned stack, and the
bootstrap resolves it rather than stopping:

- **Elixir floor is 1.15, not 1.14.** `postgrex 0.22.2` uses a 1.15 bitstring form
  (`^var` in construction); on Elixir 1.14 it is a hard `CompileError`
  (`cannot use ^positions_bytes outside of match clauses`). `install_beam.sh` reuses an
  Elixir ≥ 1.15 if present; otherwise it installs the **pinned 1.18.4 precompiled,
  matched to the OTP major already installed** (`elixir-otp-25.zip` / `-26` / `-27`),
  which runs on the existing OTP — **no OTP rebuild** — persisted onto `PATH` in
  `.bcs-env`.
- **OTP below 25.** Elixir 1.18 needs OTP ≥ 25. If the box has an older or no OTP, the
  step installs a precompiled Erlang (apt); if still too old it prints the asdf path to
  the exact pin (`asdf install erlang 28.5.0.1`) and stops with a clear note.
- **rebar3** (Erlang deps `telemetry`, `yamerl`): reuse → apt `rebar3` (built for the
  system OTP) → a matching escript. A *latest* escript may fail on OTP 25 with
  `op i_bif2`; the apt build is the reliable choice. Wired via `MIX_REBAR3`.
- **Hex**: precompiled archive; if `repo.hex.pm/installs` is unreachable, compile from
  GitHub (needs `erlang-dev` for `leexinc.hrl`, which the step installs).

## Restricted networks (egress proxy)

Some proxies serve `curl` but intercept TLS and reset Erlang's client to `repo.hex.pm`
(`TLS Fatal - Unknown CA`, then `upstream connect error … connection termination`). Two
switches handle it, both baked in: `HEX_CACERTS_PATH=/etc/ssl/certs/ca-certificates.crt`
(deps/compile set it; harmless otherwise), and `hex_offline_mirror.sh`, which builds a
**local Hex mirror** from the bytes curl can fetch (`/versions`, each `/packages/<name>`
and `/tarballs/<name>-<ver>.tar` for the `mix.lock` versions) and points Hex at it via
`HEX_MIRROR`. `umbrella_deps.sh` falls back to it automatically.

## Stage — a real run

Console from an actual bootstrap on Ubuntu 24.04 (kernel 6.18, OTP 25), step by step.

**1 — env**
```text
== env ==
   REPO_ROOT  = /root/src/fiberfx   (clone target)
   UMBRELLA   = /root/src/fiberfx/echo
   valkey     >= 8 (prefer 9.x)   elixir >= 1.15 (pin 1.18.4)
```

**2 — clone** (`git@…` first; this sandbox has no ssh, so the HTTPS fallback)
```text
== clone (branch echo_mq) ==
   cloned -> /root/src/fiberfx   branch echo_mq @ e0c54ba
```

**3 — apt base**: gcc 13.3.0, Python 3.12.3, git, curl — present/installed.

**4 — Valkey 9.1.0 from source**
```text
== valkey 9.1.0 (from source) ==
   built + installed: Valkey server v=9.1.0 sha=c9e8005e:0 malloc=jemalloc-5.3.0 bits=64
   start on :6390 (dev: no auth)
   ping -> PONG  allocator -> jemalloc-5.3.0
```
The build clones the `9.1.0` tag and runs `make BUILD_TLS=yes && make install`; the
floor gate rejects anything below 8.x. It is the only from-source component.

**4b — PostgreSQL**
```text
== postgresql ==
   cluster: PostgreSQL 16
   tcp auth ok (postgres/postgres @ 127.0.0.1:5432)
```

**5 — Go 1.25**: `installed go1.25.11 -> /usr/local/go`.

**6 — Node 22+, corepack, pnpm**: `reuse node v22.22.2 ; corepack 0.34.6 ; pnpm 11.9.0`.

**6b — BEAM resolution**
```text
== beam (elixir >= 1.15, pin 1.18.4) + rebar3 + hex ==
   erlang/otp: 25
   Elixir 1.14.0 is below 1.15 (postgrex 0.22 needs >=1.15) — installing pinned 1.18.4
   installed Elixir 1.18.4 (otp-25) at /opt/elixir-1.18.4 -> prepended to PATH in .bcs-env
   rebar3 (apt): rebar 3.19.0 on Erlang/OTP 25
```

**7 — umbrella deps** (direct fetch reset by the proxy → automatic mirror fallback)
```text
== umbrella deps (mix deps.get) ==
   direct fetch failed/empty (egress proxy?) — falling back to the local Hex mirror
   mirrored 28 packages / 28 tarballs (miss=0) ; serving on http://127.0.0.1:8899
   deps now: 28 packages (mix exit 0)
```

**7b — compile**
```text
== mix compile ==
   ==> codemojex
   Generated codemojex app
   compiled apps: 33 in _build/dev/lib
```

**7c — migrate**
```text
== ecto.create + migrate ==
The database for Codemojex.Repo has been created
== Migrated 20260618000000 ... 20260628120000 (create_codemojex, golden_rooms,
   revenue_ledger, key_shop) — 5 migrations
```

**8 — verify** (Valkey now 9.1.0, Postgres present — every required row green)
```text
   tool                 found           expect        status
   go                   1.25.11         1.25.x        ok
   node                 22.22.2         >=22          ok
   elixir               1.18.4          >=1.15        ok
   valkey-server        9.1.0           >=8 (9.x)     ok
   postgres             16.14           any           ok
   umbrella deps        28              >0            ok
```

**9 — boot smoke** (compiled engine, no services): mints `GAM…/ROM…/PLR…/SES…/JOB…/GES…`
and `Scoring.score` returns `%{max: 600, percentage: 100, total: 600, …}`.

**9b — FULL e2e** (boots the app; Repo on Postgres, Bus + four `EchoMQ.Consumer`s on
Valkey `:6390`; plays a real game)
```text
== e2e game (boot + play) ==
>> EMS emoji-set-01 seeded (150 cells)
>> ROOM ROM0ONWgLNhfpA (free warm-up)
>> PLAYER PLR0ONWgLPPGbY (seeded 100 clips)
>> GAME GAM0ONWgLV5FCq (joined; keyboard + secret snapshotted)
>> submit ["0000","0100","0200","0300","0400","0500"] -> {:ok, :enqueued}
>> SCORED (async via EchoMQ consumer on Valkey): %{eff: 0, game: "GAM0ONWgLV5FCq", pct: 0, player: "e2e-player"}
>> leaderboard: [{"PLR0ONWgLPPGbY", 0}]
>> player balance after play: %{... clips: 99 ...}
>> E2E OK
```
`submit` charges a clip in Postgres (100→99) and enqueues a branded `JOB` on the
player's EchoMQ lane in Valkey; the consumer scores it, writes the `GES` + the Board
ZSET, and broadcasts `{:scored,…}` on PubSub — the whole async pipeline, live.

**10 — report**: `report.py` writes `bootstrap-report.md` (result **PASS**) and prints
the path. That file is the attached deliverable.

## The bootstrap report

`report.py` (step 10, mandatory) reads `.bcs-env`, probes every tool, inspects the
checkout / deps / `_build`, queries the running services, embeds the boot-smoke and the
e2e lines, and writes one Markdown file. Format:

- **Header** — timestamp, host, overall `PASS` / `INCOMPLETE`.
- **Toolchain** — `tool | found | expected | status` (incl Valkey, Postgres).
- **Repository** — path, branch / HEAD, umbrella apps.
- **Dependencies & compile** — `deps.get` count, `compile` lib count, apps compiled.
- **Boot smoke** — the minted ids + the score (no services).
- **Services** — Valkey version + allocator + port; Postgres port + dev db.
- **Boot e2e** — the live game: room, player, submit, `{:scored}`, leaderboard, balance.
- **Notes & resolutions** — the Elixir/OTP resolution, rebar3 wiring, mirror use.
- **Result** — `PASS` only when every required tool is `ok` and deps + compile are
  present.

A real sample is shipped alongside this skill as `bootstrap-report.md` (it reads
**PASS**).

## Files

Scripts (`scripts/`):

- `bootstrap.sh` — runs all steps in order (the entry point).
- `setup_env.sh` — env + `$REPO_ROOT`, writes `.bcs-env`.
- `clone_repo.sh` — clone-or-pull the `echo_mq` branch (ssh → https).
- `install_apt.sh` — gcc / python / base.
- `install_valkey.sh` — **Valkey 9.1.0 from source** + cli, started on `:6390`.
- `install_postgres.sh` — PostgreSQL, started, dev role.
- `install_go.sh` — Go 1.25.
- `install_node.sh` — Node 22+ , corepack, pnpm.
- `install_beam.sh` — Elixir/OTP resolution + rebar3 + Hex.
- `umbrella_deps.sh` — `mix deps.get` with mirror fallback.
- `hex_offline_mirror.sh` — restricted-network Hex mirror.
- `compile.sh` — `mix compile`.
- `migrate.sh` — `ecto.create` + `ecto.migrate`.
- `boot_smoke.sh` — branded-id + scoring smoke.
- `e2e.sh` + `e2e_game.exs` — the full live game.
- `verify.py` — toolchain table / CI gate.
- `report.py` — the mandatory Markdown report generator.

References (`references/`): `vision-and-purpose.md`, `architecture.md`, `components.md`,
`README.md` — the design context for the umbrella the scripts provision.

## Bench facts & benchmark appendix

The from-source Valkey reports `jemalloc-5.3.0` (`valkey-cli -p 6390 INFO memory |
grep mem_allocator`). The EchoMQ connector points at a host **tuple** `{127,0,0,1}` (not
a binary string) on port 6390, with drill servers on 6391/6392. The optional
from-source comparison bench (pinned jemalloc + Valkey + a kerl OTP for allocator/latency
runs) is a separate appendix.
