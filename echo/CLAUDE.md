# CLAUDE.md — the `echo` umbrella · the BCS data-layer stack

This file guides a fresh session building in `/Users/jonny/dev/jonnify/echo`. It is the **per-umbrella
build guide** for the **Branded Component System (BCS) data-layer stack** — `echo_wire` · `echo_data` ·
`echo_mq` · `echo_store`, the Valkey-native data plane built on ETS and Lua. It records the layout, the
toolchain, the gate ladder, and the one wire invariant that must not break.

The **specs are the source of truth**, not this file: the echo_mq program canon lives in `docs/echo_mq/`
(`emq.design.md` · `emq.roadmap.md`), and the spec-driven *workflow* that ships it (Venus/Mars/Apollo, the
laws) lives in the **repo-root `CLAUDE.md`** + the `echo-mq-*` skills. This file is *how to build against the
stack from the umbrella dir*; when it disagrees with the specs, the specs win.

## Scope of this file

**In scope:** the four BCS data-layer apps and their build/test mechanics — **Valkey · EchoStore · ETS ·
EchoMQ**. The umbrella `Echo.MixProject` (`apps_path: "apps"`, no umbrella-level deps) sits under the
`jonnify` git repo on disk but is its own Mix project; it is **not** a Go module and is **not** in the
repo's `go.work` `use` block.

**Out of scope for this file** (they live in the same umbrella but are not the BCS data stack): `exchange`
(the trading capstone — Operator out-of-band), `investex`, `echo_bot` (the standalone YAML multibot engine),
and `codemojex`. Do not work those from this guide.

> Historical note: the Phoenix surface (`portal` · `portal_web` · `mercury_cms` · `mercury_live_admin` ·
> `live_svelte`) was moved out of this umbrella to its own repository. The branded-id codec it used was
> inlined into that repo; `echo_data` here stays the canonical identity library for the BCS stack.

## 1. The stack (real dependency arrows, base → top)

Engine: **Valkey 9 on `:6390`** (RESP3). Gate every wire rung with `valkey-cli -p 6390 ping` → `PONG`
before trusting a green suite.

| App | Role | In-umbrella deps |
|---|---|---|
| `echo_wire` | The **owned wire**: RESP framing, the single-owner socket connector, the script registry behind a version fence. `EchoMQ.Connector` / `RESP` / `Script` are **frozen** by committed records; `EchoWire` is the facade. | — (base) |
| `echo_data` | **Identity + structure + BCS** — pure, no in-umbrella deps. The 14-byte branded-id contract (`EchoData.{BrandedId,Snowflake,Base62}` + the optional Rust NIF `EchoData.Native`), the persistent structures (`BrandedChamp` / `BrandedMap` / `BrandedTree`, `Edges`, `Timeline`), and the BCS systems (`Bcs.{PropertyStore,EdgeStore,Archetypes,Supervisor}` + `Bcs.gate`). | — (pure) |
| `echo_mq` | **The bus** — the Valkey-native job/queue/stream system; a *system over the wire* keyed by branded `JOB` ids. Keyspace `emq:{q}:`, inline Lua, server-clock leases. | `echo_data` + `echo_wire` |
| `echo_store` | **The store** — L1 **ETS** over L2 Valkey (cache-aside), a per-group SQLite journal + a native Graft replication engine (CubDB → Tigris S3; in progress). Keyspace `ecc:{table}:{id}`; coherence is *a message about a name* (the BCS law, literally). | `echo_data` + `echo_mq` + `echo_wire` + `exqlite` |

**The BCS law** (the one mental model): encapsulation boundaries are drawn around **systems**, not objects;
the only values that cross a boundary are **identities** and **messages about identities** — no object
graphs, no shared mutable state, no embedded id lists. `echo_mq` and `echo_store` are *systems* built to this
discipline over the wire; `echo_data/lib/echo_data/bcs/` is its reference implementation. The whole-picture
frame (the CAP-segmented composition) is `docs/echo/mesh/mesh.8.1.md` — read it for the why, not the build.

## 2. ETS's role (why this is "the data plane")

ETS is the in-process substrate the BCS systems own:

- A **BCS system is an OTP process owning a `:private` ETS table** that gates every ingress on a single
  branded namespace (`EchoData.Bcs.gate/2`) and exports its store to nobody. `Bcs.PropertyStore` (entity →
  props) and `Bcs.EdgeStore` (a *relation* as a system, keyed by `{subject, object}` of names, both ends
  gated) are the two shipped shapes.
- `echo_store`'s **L1 is ETS**, with L2 Valkey behind it (cache-aside) and the store pushing invalidation
  (RESP3 `CLIENT TRACKING`). Under partition, L1 serves what it has.

The branded id is the thread that ties the in-process ETS view to the on-wire Valkey view: minted once,
carried unchanged across the boundary.

## 3. Build / run / test — the gate ladder (read first)

Toolchain (`.tool-versions`, asdf): **Elixir 1.18.4**, **Erlang/OTP 28.5.0.1**. **Re-probe `asdf current` /
`.tool-versions` from the app dir — never hardcode the toolchain** (it has drifted before; the old
`ASDF_ERLANG_VERSION=28.1` advice is dead).

The gate ladder is **per-app, NEVER umbrella-wide** — run it from inside the app's own directory:

```bash
cd /Users/jonny/dev/jonnify/echo/apps/<app>     # echo_wire | echo_data | echo_mq | echo_store
valkey-cli -p 6390 ping                          # → PONG  (the engine must be up for a wire rung)
TMPDIR=/tmp mix compile --warnings-as-errors     # the clean-compile gate
TMPDIR=/tmp mix test                             # add --include valkey for a wire/bus rung
```

- **`TMPDIR=/tmp` for ALL `mix`** — the one that actually bites. The harness tmp overlay can hit ENOSPC,
  surfacing as *spurious mid-suite ExUnit I/O failures* unrelated to any logic error.
- **Conformance** (echo_mq): `EchoMQ.Conformance.run/2` → `{:ok, n}` under the **additive-minor law** —
  prior scenarios stay byte-unchanged and git-verified, each new one is probe-registered, and the count is
  re-pinned in both pinning tests. Additive registration is a protocol *minor*; a wire break is a *major*.
- **The determinism loop is a MULTI-RUN loop**, not just multi-seed. For any **id-mint / process / lease**
  suite, ratify with a repeated full-suite loop (≥100 iterations,
  `for i in $(seq 1 150); do TMPDIR=/tmp mix test || break; done`): the hazard is *same-millisecond branded-id
  mint contention within a run*, which re-seeding does not reproduce. For a suite without that hazard, a
  multi-seed sweep + an honest determinism-posture statement is enough.

## 4. The v2 master invariant (the wire broke once — do not break it again)

> Braced `emq:{q}:` keyspace · branded `JOB` ids gated at the key builder · **every Lua key in `KEYS[]`, or
> derived from a *declared* `KEYS[n]` root** (an `ARGV`-passed base is **not** a declared root — this was
> gate-invisible on single-node Valkey) · **server clock** (`TIME`) wherever a lease is touched · **inline
> `Script.new/2`, never `priv/`**.

When a rung re-drives a shipped script, **byte-freeze the Lua**: the `Script.new` bodies stay byte-identical
to HEAD (`grep redis.call` on the lib diff must be `0`).

**Boundary:** a rung edits `echo/apps/echo_mq` (+ at most the one named `echo_wire` seam it touches). No third
app; `mix.lock` excluded unless a real dep moved. A change reaching a third app is a diff no one can review.

## Map

Program canon `docs/echo_mq/` (`emq.design.md` · `emq.roadmap.md` · `emq.progress.md`) · the spec-driven
workflow + laws → repo-root `CLAUDE.md` + the `echo-mq-*` skills + `/echo-mq-ship` · BCS reference code
`apps/echo_data/lib/echo_data/bcs/` (+ `test/bcs`) · the whole-picture frame `docs/echo/mesh/mesh.8.1.md`.
