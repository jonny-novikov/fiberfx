# EWR.1.2 · EchoWire.Cmd / EchoWire.Command — the fluent builder + the immutable command value + the full `cf`-flag vocabulary (advisory)

> **Status: BUILT** — shipped green and Director-verified (the ruled arm, Arm 3 + full-cf, the Operator's ruling
> `2026-06-18`: [`ewr.1.2.design.md`](ewr.1.2.design.md) §4). The second rung of the EchoWire client-core program
> ([`../../ewr.roadmap.md`](../../ewr.roadmap.md), Movement I). `ewr.1.2` builds, inside `echo/apps/echo_wire`,
> the **complete rueidis-faithful command core** as two new modules:
> - **`EchoWire.Command`** (`lib/echo_wire/command.ex`) — the immutable command value, the faithful Elixir port
>   of rueidis `Completed` (`go/valkey-go/internal/cmds/cmds.go:117`: `{cs *CommandSlice; cf uint16; ks
>   uint16}` = parts + bit-packed flags + key-slot): a `%EchoWire.Command{parts, flags, slot}` struct carrying
>   the **full `cf` flag vocabulary** (`cmds.go:5-23`) + the **key-slot** (CRC16 over the key / `{hashtag}`,
>   `slot.go:5`), the **flag predicates** (`readonly?/1` · `block?/1` · `pipe?/1` · `noreply?/1` ·
>   `static_ttl?/1` · `retryable?/1` · `opt_in?/1` · `mt_get?/1` · `unsub?/1` · `scr_ro?/1`) + `slot/1` +
>   `parts/1`, and a `raw/1` escape-hatch constructor.
> - **`EchoWire.Cmd`** (`lib/echo_wire/cmd.ex`) — the **fluent builder** that mints a `%Command{}`:
>   `EchoWire.Cmd.set("k") |> EchoWire.Cmd.value("v") |> EchoWire.Cmd.ex(60) |> EchoWire.Cmd.build()` (the rueidis
>   type-state chain reimagined as `|>`), a curated builder across the same six Valkey data families `Pipe`
>   curates, **plus `EchoWire.Cmd.run/2`** — running a built command (or a list) against a conn-or-pool through
>   the opaque `via` dispatch (mirroring `Pipe`). `run/2` is on `EchoWire.Cmd`, **never** a 12th `EchoWire`
>   facade verb (the chapter design's §4 correction).
>
> It integrates with the as-built **`EchoWire.Pipe`** (`ewr.1.1`) by a **single additive seam**:
> `EchoWire.Pipe.command/2` (`pipe.ex:490`) accepts a `%EchoWire.Command{}` in addition to a raw command-list,
> extracting its `.parts` — so a built `%Command{}` composes into a `Pipe` batch; `Pipe`'s struct / curated
> verbs / `add/2` / `exec/1` are **byte-identical to HEAD**. **The flags are ADVISORY** — nothing in the wire
> reads them this rung (roadmap seam 4: no retry / cluster-routing / caching consumer exists yet); the value
> carries them for a future consumer, and the proof the value is sound is **byte-equivalence** (a built+flagged
> command runs identically to its bare verb). This is **design-Arm B realized** — the additive command-value
> sibling to `Pipe`, with `Pipe` remaining the primary batch surface — not a reopening of Arm A. The change is
> **additive by construction**: `EchoMQ.Connector` / `RESP` / `Script` / `Pool` are frozen and reused; the
> `EchoWire` facade stays at its 11 verbs (`lib/echo_wire.ex:19-31`, pinned by `echo_wire_facade_test.exs`); no
> Lua enters the wire; the `echo_mq` conformance **stays byte-stable — the wire registers no scenario and writes
> no `registry.json`; the count is emq-owned (it has drifted 52 → 53 → 54 within this program's life, from emq's
> out-of-band control-plane work — not the wire's to pin)**. The new layer (`Command` + `Cmd` + the seam + story
> tests) lives *above* the conformance boundary.
>
> **As-built reconcile (BUILT, Director-verified).** The shipped surface realizes the ruled arm:
> - `EchoWire.Command` (`echo/apps/echo_wire/lib/echo_wire/command.ex`) — `%Command{parts, flags, slot}` with
>   `flags` an **integer bitfield** mirroring the rueidis `cf` uint16, **the bit-inclusion baked into the
>   constants** (`@readonly = (1 <<< 13) ||| @retryable`; `@noreply ⊇ @readonly | @pipe`; `@unsub ⊇ @noreply`;
>   `@mt_get`/`@scr_ro ⊇ @readonly`). The predicates **subset-match** (`flags &&& tag == tag`), so `readonly?` ⇒
>   `retryable?` **holds for free** — INV3's bit-inclusion is a property of the constants, not a separate check.
>   Flags are stamped **static per-verb** (by verb name, never parsed from `parts`); `slot` is a **CRC16-XMODEM**
>   port of `slot.go` with the `{hashtag}` rule (vectors: `slot_of("123456789") == 12_739`;
>   `slot_of("{user}:1") == slot_of("{user}:2")`). The full predicate set + `raw/1`/`raw/2` + `slot/1`/`parts/1`
>   ship.
> - `EchoWire.Cmd` (`echo/apps/echo_wire/lib/echo_wire/cmd.ex`) — the fluent `set |> value |> ex |> build`
>   builder across the six families + `run/2` (conn-or-pool `via` dispatch); **`EchoWire.run/2` is ABSENT** — the
>   facade stays 11.
> - The **one additive `EchoWire.Pipe.command/2` head** accepting a `%EchoWire.Command{}` (extract `.parts`), with
>   a one-line `@spec` widening to `command(t(), command() | EchoWire.Command.t())` and an extended `@doc` — and
>   `Pipe`'s struct / curated verbs / `add/2` / `exec/1` **byte-identical to HEAD**. The flags/slot are dropped at
>   the seam; only `.parts` reach the wire, so a flagged `%Command{}` flushes **byte-identically** to the bare
>   verb (the acceptance theorem).
> - **The gate is green:** `echo_wire` **109/0** (the facade-freeze still 11 verbs, `EchoWire.run` absent); the
>   new wire `:valkey` command stories **8/0**; the `echo_mq` conformance byte-stable (the count is emq-owned);
>   byte-equivalence proven (a `%Command{}` via `run/2` and via `Pipe.command/2` runs identically to the bare
>   verb); the INV3 (static-per-verb / bit-inclusion) and INV4 (the wire-sees-only-`.parts`) mutations **KILLED**.
>   The touch-set is the two new modules + their offline tests + the one additive `pipe.ex` `command/2` head + the
>   `wire_pipe_command_*_story_test.exs` stories + the generated `docs/echo_mq/wire/stories/`.

## Goal

`ewr.1.2` builds the wire's **immutable command value + its fluent builder**: a faithful Elixir port of the
rueidis `Completed` (parts + the full `cf` flag vocabulary + key-slot) as pure data, plus the `set |> value |>
build` builder that mints it and a `run/2` that runs it. `ewr.1.1`'s `EchoWire.Pipe` already covers *batch
construction* (thread many commands, flush once) — this rung adds the **per-command** surface: a single command
becomes an inspectable, flag-bearing value, and `EchoWire.Cmd` is the builder + runner for it. The two surfaces
have a crisp division of authority — **`Pipe` builds a batch to flush; `EchoWire.Cmd`/`Command` builds one
flagged value to carry or `run/2`** — and meet at exactly one point: `Pipe.command/2` accepts a built
`%Command{}`, so a command composes *into* a batch. The reference is the valkey-go command core: the value
(`Completed{cs, cf, ks}`, `cmds.go:117`), the builder's type-state chain (`Builder.Set()` → `Set.Key(k)` →
`SetKey.Value(v)` → `SetValue.ExSeconds(s)` → `SetValue.Build()`, `gen_string.go:1487,1956,1998,2043`) reimagined
as `|>`, the per-verb flag stamp (`Get()` stamps `readonly`, `gen_string.go:231`), and the cluster key-slot
(`slot(key)`, `slot.go:5`). **The flags are advisory** (seam 4): the connector does not act on them, so the value
is built, carried, and `run/2`'d, never consumed-for-routing, this rung.

## Rationale (5W)

- **Why** — `ewr.1.1` holds a command as a bare list the moment it is appended (`add/2`, `pipe.ex:538`): it
  carries no record of whether it is a read or a write, whether it is replayable across a reconnect, which
  cluster slot its key hashes to, or whether it is cacheable. The valkey-go client's *actual* signature core is
  exactly this missing structure — `Completed{cs, cf, ks}` (`cmds.go:117`) minted by a fluent type-state builder,
  where the flags drive retry (`IsReadOnly()`, cmds.go:183), routing (`Slot()`, cmds.go:210), dedicated-connection
  dispatch (`IsBlock()`, cmds.go:168), and client-side caching (`IsStaticTTL()`, cmds.go:155). `echo_wire` has no
  home for that value or its builder; a future retry / cluster / caching layer would have to re-parse `parts` to
  recover what the verb already knew at build time. The Operator's ruling provisions the **complete** core now —
  the faithful builder and the whole `cf` vocabulary — ahead of the consumers that will read it (seam 4 — the
  flags stay advisory until then).
- **What** — two new modules:
  - `EchoWire.Command` — the `%Command{parts, flags, slot}` struct (the rueidis `Completed` ported as pure data);
    the **full `cf` flag vocabulary** as a flag set with the rueidis **bit-inclusion** preserved (`readonly`
    includes `retryable`, `noreply`/`noRetTag` includes `readonly | pipe`, `unsub` includes `noreply`, …,
    cmds.go:5-23); the predicates `readonly?/1` · `write?/1` · `block?/1` · `pipe?/1` · `noreply?/1` ·
    `static_ttl?/1` · `retryable?/1` · `opt_in?/1` · `mt_get?/1` · `unsub?/1` · `scr_ro?/1` (mirroring the
    accessors, cmds.go:147-210) + `slot/1` (`Slot()`) + `parts/1` (`Commands()`); and a `raw/1` constructor for an
    un-modeled command (flags default to write/unknown, slot from the identified key or `nil`).
  - `EchoWire.Cmd` — the **fluent builder**: verb-openers (`set/1`, `get/1`, … one per principal verb across the
    six families) returning an *un-built builder value*, the chainable token-setters (`value/2`, `ex/2`, `nx/1`,
    `key/2`, …) that append tokens, and `build/1` that freezes the builder into a `%EchoWire.Command{}` (stamping
    `parts` + the **static per-verb flags** + the `slot`); **plus `EchoWire.Cmd.run/2`** running a built
    `%Command{}` or a `[%Command{}]` against a conn-or-pool through the opaque `via` dispatch (default
    `EchoMQ.Connector`, `EchoMQ.Pool` via `opts[:via]`), extracting `.parts` into `pipeline/3`.
  Plus **one integration seam:** `EchoWire.Pipe.command/2` accepts a `%EchoWire.Command{}` (extracting `.parts`)
  in addition to a raw command-list; `exec/1` is unchanged. The exact builder/value SHAPE (the `flags`
  representation, the un-built-builder representation, the per-verb table form) is the implementor's design-make
  (D1).
- **Who** — a caller who wants the rueidis builder ergonomics + an inspectable flagged value to carry or `run/2`;
  primarily a *future* `ewr` retry / cluster-routing / caching rung (the flag + slot consumers, seam 4). The
  everyday batch caller keeps `ewr.1.1`'s `Pipe` verbs unchanged — `EchoWire.Cmd`/`Command` is the **additive
  per-command sibling**, not a replacement for the batch surface. No downstream rung gates by name on `ewr.1.2`;
  `ewr.1.3` (the error split) wraps the `run/2` / `exec` return independently.
- **When** — Movement I, rung 2, now: `ewr.1.1` is shipped and frozen, and the complete command core is the
  prerequisite the later flag consumers need. It precedes any retry / cluster / caching rung because those *read*
  the value this rung *defines*. It follows `ewr.1.1` because it integrates with — and must not disturb — the
  shipped `Pipe`.
- **Where** — the **modules + pure tests live in `echo_wire`**: `echo/apps/echo_wire/lib/echo_wire/command.ex` +
  `echo/apps/echo_wire/lib/echo_wire/cmd.ex` (both **new**, beside the shipped `lib/echo_wire/pipe.ex`) + new
  `test/echo_wire/command_test.exs` + `test/echo_wire/cmd_test.exs`. The **one shipped-file edit** is a single
  additive clause on `EchoWire.Pipe.command/2` (`echo/apps/echo_wire/lib/echo_wire/pipe.ex:490`) — a new function
  head accepting `%EchoWire.Command{}`; the rest of `pipe.ex` (the struct, `add/2`, every curated verb, `exec/1`)
  is **untouched**. The **BDD story tests live in `echo_mq`** (`echo_mq` depends on `echo_wire` —
  `echo/apps/echo_mq/mix.exs:31` — so a story test can drive all three modules, where the reverse would invert
  the dependency): `echo/apps/echo_mq/test/stories/wire_pipe_command_*_story_test.exs` (named so `mix
  echo_mq.stories --match wire_pipe` scopes them — L-1). The generated `.stories.md` land in the wire docs
  (`docs/echo_mq/wire/stories/`). The frozen `lib/echo_mq/` runtime and the `lib/echo_wire.ex` facade are
  untouched; `echo/mix.lock` is unchanged.

## Scope

- **In** — the `EchoWire.Command` module (the `%Command{parts, flags, slot}` struct; the full `cf` flag
  vocabulary with bit-inclusion; the predicates + `slot/1` + `parts/1`; `raw/1`); the `EchoWire.Cmd` module (the
  fluent builder across the six families — verb-openers + token-setters + `build/1`, each `build/1` stamping
  parts + the static per-verb flags + the key-slot; `run/2` over a conn-or-pool via the opaque `via`); the **one
  additive `EchoWire.Pipe.command/2` clause** accepting a `%Command{}`; the offline construction suites in
  `echo_wire` (the parts/flags/slot pins + the full predicate truth table incl. the bit-inclusion + the
  builder-chain assertions + the `command/2`-accepts-`%Command{}` equivalence); the **BDD `:valkey` story layer**
  in `echo_mq/test/stories/wire_pipe_command_*` (the byte-equivalence round-trip: a built+flagged command flushed
  via `run/2` and via `Pipe.command/2` runs identically to the bare `Pipe` verb) + the generated `.stories.md`;
  the byte-stable re-pin of the facade-freeze and the conformance posture (byte-stable, the count emq-owned —
  not the wire's to pin).
- **Out** — **acting on the flags** (retry-on-`readonly`, cluster slot-routing, caching by `static_ttl`): the
  flags are **advisory** this rung; no connector / dispatch behaviour reads them (→ a future seam-4 consumer
  rung). The two-tier error split (→ `ewr.1.3`). Client-side caching / CLIENT TRACKING (→ Movement II). Any
  rewrite of `ewr.1.1`'s shipped `Pipe` verbs or `add/2` or `exec/1` (Arm 2, not ruled — only the one additive
  `command/2` clause is in scope). **Enriching the `Pipe` verbs to emit `%Command{}` internally** (Arm 2, not
  ruled). Any edit to the connector, RESP, Script, Pool, or the facade; any `echo_mq` **lib runtime** edit; any
  new Lua; the `EchoMQ.Keyspace` edge (noted, not deepened — roadmap seam 5). Compile-time type-state enforcement
  of the builder chain (dynamic Elixir does not provide it — `build/1` is a runtime token; a forgotten `build/1`
  is a runtime contract error, not a wire error).

## Deliverables

- **`EWR.1.2-D1` — the design-make gate (FIRST).** Before any artifact, re-probe the as-built floor (the lag-1
  law) and rule the decisions that are the implementor's, not the Operator's: (a) confirm the seam anchors — the
  shipped `EchoWire.Pipe.command/2` (`pipe.ex:490`), `add/2` (`pipe.ex:538`), `exec/1` (`pipe.ex:503`); (b)
  confirm the rueidis value + builder anchors — `Completed{cs, cf, ks}` (`cmds.go:117`), the **full** `cf`
  constants (`cmds.go:5-23`), the accessors (`cmds.go:147-210`), `slot(key)` (`slot.go:5`), the type-state chain
  + per-verb flag stamp + `Build()` (`gen_string.go:231,1487,1956,1998,2043,37`); (c) **realize the flag
  representation** — the **binding contract** is that a command's flags are derived from a **static per-verb
  property** at build time (the verb decides the flag, e.g. `get/1` is `readonly`; **never** parsed from the
  assembled `parts`), the **rueidis bit-inclusion is preserved** (a `readonly` command answers `retryable?`
  true), and the `slot` is a **pure function of the command's key** (`crc16(key | {hashtag}) & 16_383`); the
  exact SHAPE (`flags` as a `MapSet` of atoms, a keyword, or a bitfield integer mirroring `cf`; the per-verb
  table's form; the un-built-builder representation) is the implementor's design-make. (d) realize the **builder
  surface** — the `set |> value |> ex |> build` chain shape (the verb-opener / token-setter / `build/1` split)
  and `run/2`'s conn-or-pool dispatch (mirroring `Pipe`'s `via`, `run/2` on `EchoWire.Cmd` — not the facade). (e)
  finalize the curated builder membership across the six families (D3). (f) place the modules at
  `lib/echo_wire/command.ex` + `lib/echo_wire/cmd.ex`, the seam clause on `pipe.ex:490`, and the story tests at
  `echo_mq/test/stories/wire_pipe_command_*`. No `.ex`/test artifact predates this ledger entry.
- **`EWR.1.2-D2` — the command value + the full `cf` vocabulary.** `%EchoWire.Command{}` — `defstruct [:parts,
  :flags, :slot]` (or the subset D1 rules): `parts` a flat `[binary | integer | atom]` (the same token shape
  `Pipe` flushes), `flags` the **full `cf` flag set** (D1's shape, the ten tags with bit-inclusion: `opt_in` ·
  `block` · `readonly` · `noreply` · `mt_get` · `scr_ro` · `unsub` · `pipe` · `retryable` · `static_ttl`), `slot`
  the key-slot integer (`0..16_383`, or `nil` when no key is identifiable). The struct is **immutable** and pure
  data: building one performs no I/O and starts no process. The predicates (D5) read this flag set.
- **`EWR.1.2-D3` — the fluent builder across the six data families.** `EchoWire.Cmd` exposes a verb-opener per
  principal verb across the **six core Valkey data families** + the chainable token-setters + `build/1`. The
  chain shape mirrors rueidis's type-state builder reimagined as `|>` (`set("k") |> value("v") |> ex(60) |>
  build()`); `build/1` freezes a `%EchoWire.Command{}` stamping: `parts` (the verb + key + options as trailing
  tokens — the **same rendering `Pipe` uses**, grounded in valkey-go's `gen_*.go` builders); the **static
  per-verb `flags`** (the verb's read/write/block/cacheable property, from the per-verb table — never parsed from
  `parts`); and `slot` (CRC16 over the command's key). The membership mirrors `ewr.1.1`'s curated families (the
  implementor need not curate every option; an un-modeled command rides `Command.raw/1`, INV6):
  - **strings** (`gen_string.go`): `get/1` (`readonly`), `set/1` (+ `value/2`/`ex/2`/`px/2`/`nx/1`/`xx/1`/
    `keepttl/1`/`get/1` setters; `write`), `getset/1`, `getdel/1`, `mget/1` (`readonly`), `mset/1`, `incr/1`,
    `incrby/2`, `decr/1`, `append/2`, `strlen/1` (`readonly`), `setex/3`, `setnx/2`, … (the principal verbs).
  - **keys / generic + expiry** (`gen_generic.go`): `del/1` (`write`), `unlink/1`, `exists/1` (`readonly`),
    `expire/2`, `ttl/1` (`readonly`), `pttl/1` (`readonly`), `persist/1`, `type/1` (`readonly`), `rename/2`,
    `scan/1`, `touch/1`, `copy/2`, …
  - **hashes** (`gen_hash.go`): `hset/3` (`write`), `hset_all/2`, `hget/2` (`readonly`), `hmget/2` (`readonly`),
    `hgetall/1` (`readonly`), `hdel/2`, `hexists/2` (`readonly`), `hincrby/3`, `hkeys/1` (`readonly`), `hvals/1`
    (`readonly`), `hlen/1` (`readonly`), …
  - **lists** (`gen_list.go`): `lpush/2` (`write`), `rpush/2`, `lpop/1`, `rpop/1`, `lrange/3` (`readonly`),
    `llen/1` (`readonly`), `lindex/2` (`readonly`), `lrem/3`, `ltrim/3`, `rpoplpush/2`, `lmove/4`, … (NB: the
    blocking forms `BLPOP`/`BRPOP`/`BLMOVE` carry `block` — a `block`-flagged builder or `Command.raw/1`).
  - **sets** (`gen_set.go`): `sadd/2` (`write`), `srem/2`, `smembers/1` (`readonly`), `sismember/2` (`readonly`),
    `scard/1` (`readonly`), `spop/1`, `srandmember/1` (`readonly`), `smismember/2` (`readonly`), `sscan/2`, …
  - **sorted sets** (`gen_sorted_set.go`): `zadd/1` (+ `score/3`/`nx/1`/`gt/1`/`ch/1`/`incr/1` setters; `write`),
    `zrem/2`, `zrange/3` (`readonly`), `zrevrange/3` (`readonly`), `zscore/2` (`readonly`), `zcard/1`
    (`readonly`), `zrank/2` (`readonly`), `zincrby/3`, `zpopmin/1`, `zpopmax/1`, `zcount/3` (`readonly`),
    `zscan/2`, …

  The arities + the exact opener/setter split are the implementor's design-make (the body names the verb +
  family + the flag + the valkey-go reference, **not** a frozen `{fun, arity}` table — `EchoWire.Cmd` is **not**
  the facade and is **not** arity-frozen; INV1). The curated builder is **comprehensive across the six families
  but never a ceiling** — `Command.raw/1` (D4) covers every un-curated verb and family (INV6). *Flag-derivation
  note (the load-bearing port fact):* a verb's flag comes from the **static per-verb table** (the rueidis
  `Builder.<Verb>()` stamps it at construction, `gen_string.go:231`), never from inspecting the assembled `parts`
  — `EchoWire.Cmd.get("k") |> build()` is `readonly` because the *verb is* `GET`, decided when the builder runs,
  not by matching `"GET"` in a list.
- **`EWR.1.2-D4` — the `raw/1` escape hatch.** `EchoWire.Command.raw(parts)` (and an optional `raw(parts, key)`
  to identify the slot key) constructs a `%Command{parts, flags, slot}` from a raw command-list verbatim — the
  parts are taken as given, the flags default to **write/unknown** (the conservative assume-mutating,
  non-replayable default), and the slot is computed from the identified key (or `nil`). So any un-modeled verb
  (e.g. `["CLIENT","INFO"]`, a `SCRIPT` admin call) is reachable as a command value without a curated builder. The
  curated builder is convenience; this guarantees completeness, exactly as `Pipe.command/2` does for the batch
  surface.
- **`EWR.1.2-D5` — the predicates + accessors (the full `cf` reader set).** On `EchoWire.Command`:
  `readonly?/1` (`IsReadOnly()`, cmds.go:183), `write?/1` (`IsWrite()`, :188), `block?/1` (`IsBlock()`, :168),
  `pipe?/1` (`IsPipe()`, :193), `noreply?/1` (`NoReply()`, :173), `static_ttl?/1` (`IsStaticTTL()`, :155),
  `retryable?/1` (`IsRetryable()`, :198), `opt_in?/1` (`IsOptIn()`, :147), `unsub?/1` (`IsUnsub()`, :178),
  `mt_get?/1` / `scr_ro?/1` (the `mtGetTag`/`scrRoTag` reads); `slot/1` returns the key-slot integer (or `nil`,
  `Slot()` :210); `parts/1` returns the raw `[binary | integer | atom]` (the bytes a flush would carry,
  `Commands()` :205). **The rueidis bit-inclusion is preserved**: a `readonly?`-true command is also
  `retryable?`-true; a `noreply?`-true command is also `readonly?`- and `pipe?`-true; an `unsub?`-true command is
  `noreply?`-true. **These are the ADVISORY readers — they exist for a future consumer; nothing in the wire calls
  them this rung** (INV7).
- **`EWR.1.2-D6` — the builder runner + the `Pipe` integration seam.**
  - **`EchoWire.Cmd.run/2`** runs a built `%Command{}` or a `[%Command{}]` against a conn-or-pool: `run(cmd_or_list,
    conn_or_opts)` extracts the command(s)' `.parts` and flushes once through the opaque `via.pipeline/3` (default
    `EchoMQ.Connector`, `EchoMQ.Pool` via the `:via` option — mirroring `Pipe`'s dispatch), answering `{:ok,
    [RESP.reply()]}` / `{:error, term}`. `run/2` accepts conn-or-pool and **never inspects** the reference (INV3's
    opacity, carried from `ewr.1.1` INV3). `run/2` is on `EchoWire.Cmd`, **never** the facade (INV1).
  - **The `Pipe` seam (the ONE shipped-file edit):** `EchoWire.Pipe.command/2` (`pipe.ex:490`) gains **one
    additive function head** accepting a `%EchoWire.Command{}` — it extracts the command's `.parts` and appends
    them via the existing private `add/2` (exactly as the raw-list head does), so a `%Command{}` and the
    equivalent raw list produce a byte-identical `cmds` entry. The existing raw-list head (`command(pipe, parts)
    when is_list(parts)`) and **everything else in `pipe.ex`** — the struct, the curated verbs, `add/2`,
    `exec/1`, `exec_txn/1`, `exec_noreply/1` — are **untouched**. `exec/1`'s return and wire shape are **frozen**:
    appending a `%Command{}` flushes the same `[[binary]]` the bare verb would, and the flags (advisory) are
    dropped at the seam — they live on the value for a consumer to read, never reach the wire (INV4, INV5).
- **`EWR.1.2-D7` — the gate.** The per-app ladder green from inside `echo/apps/echo_wire/`:
  `mix compile --warnings-as-errors`; the construction unit suites (offline — the parts/flags/slot pins, the
  **full** predicate truth table incl. the bit-inclusion, the builder-chain assertions [`set |> value |> ex |>
  build` yields the expected `%Command{}`; an un-built builder is a distinct intermediate], the
  `Pipe.command/2`-accepts-`%Command{}` equivalence, and a `run/2`-vs-bare-verb `parts` equivalence); **then from
  `echo/apps/echo_mq/`** the `@tag :valkey` story suite on `6390` (the byte-equivalence round-trip: `run/2` and
  `Pipe.command/2` over a built+flagged command run identically to the bare `Pipe` verb) +
  `mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories` regenerating the `.stories.md`
  **idempotently** (the `--match wire_pipe` filter — L-1 — scopes the regen to the wire features, leaving the
  sibling `docs/echo_mq/stories/` git-clean: **assert the bus dir is byte-unchanged** — the shared-tool no-harm
  check); the facade-freeze test still green (11 verbs); the `echo_mq` conformance byte-stable (the count is
  emq-owned — not the wire's to pin; if the gate cites the floor, the as-built count, currently 54); a
  multi-seed sweep + the determinism-posture statement (no id-mint/process/lease → no ≥100 loop). The two-app
  ladder is intrinsic to the dep direction (the modules in `echo_wire`, the story tests in `echo_mq` above it).

## Invariants

- **`EWR.1.2-INV1` — the facade stays at 11 verbs; `run/2` is on `EchoWire.Cmd`.** `EchoWire.Command` and
  `EchoWire.Cmd` are **new modules**, never `defdelegate`s on `EchoWire`; `EchoWire.Cmd.run/2` is **not** a 12th
  facade verb. `echo_wire_facade_test.exs` is unchanged and still asserts exactly the 11 verbs
  (`lib/echo_wire.ex:19-31`). *Check:* the facade test's exported-function list is byte-identical to HEAD;
  `EchoWire.run/2` does not exist (`function_exported?(EchoWire, :run, 2)` is `false`).
- **`EWR.1.2-INV2` — additive; the frozen runtime is untouched; the only shipped-file edit is the one
  `Pipe.command/2` seam clause; `echo_mq` is test-only; conformance byte-stable (the count emq-owned).** No edit
  to `EchoMQ.Connector` / `RESP` / `Script` / `Pool`; no new Lua (`grep redis.call` on the lib diff is `0`); the
  `echo_mq` conformance **stays byte-stable — the wire registers no scenario and writes no `registry.json`; the
  count is emq-owned (it has drifted 52 → 53 → 54 within this program's life, from emq's out-of-band
  control-plane work — not the wire's to pin)** — the layer is *above* the conformance boundary, so the
  additive-minor *registration* law is **not engaged**. The `echo_wire` lib touch is the two new modules (`command.ex` +
  `cmd.ex`) **plus one additive head on `pipe.ex`'s `command/2`** — no other `pipe.ex` line changes (the struct,
  the verbs, `add/2`, `exec/1` are byte-identical to HEAD). The `echo_mq` touch is **test-only** under
  `echo_mq/test/stories/`. *Check:* `git diff` touches only the new
  `echo/apps/echo_wire/lib/echo_wire/{command,cmd}.ex` + the new
  `echo/apps/echo_wire/test/echo_wire/{command,cmd}_test.exs` + a single added function head in
  `echo/apps/echo_wire/lib/echo_wire/pipe.ex` (the `command/2` `%Command{}` clause — `git diff pipe.ex` shows
  *only* added lines, no edit to the struct/verbs/`add`/`exec`) + the new
  `echo/apps/echo_mq/test/stories/wire_pipe_command_*_story_test.exs` + the regenerated
  `docs/echo_mq/wire/stories/`; **no** frozen-runtime `lib/` file (`Connector`/`RESP`/`Script`/`Pool`), the
  facade unchanged, and `echo/mix.lock` unchanged.
- **`EWR.1.2-INV3` — the flags are STATIC per-verb (never parsed from the parts); the bit-inclusion is
  preserved; the slot is a pure function of the key; `run/2` carries the dispatch opaquely.** A `%Command{}`'s
  `flags` are stamped from the verb's static read/write/block/cacheable property at build time (the rueidis
  `Builder.<Verb>()` stamp, `gen_string.go:231`), **not** computed by inspecting the assembled `parts`; the
  rueidis bit-inclusion holds (`readonly?` ⇒ `retryable?`; `noreply?` ⇒ `readonly?` ∧ `pipe?`); the `slot` is
  `crc16(key | {hashtag}) & 16_383` (`slot.go:5`), a pure function of the command's key; and `EchoWire.Cmd.run/2`
  dispatches through `via` **without inspecting** the conn-or-pool reference (carried, not detected — `ewr.1.1`
  INV3's opacity). *Check:* `EchoWire.Cmd.get(k) |> build()` is `readonly?` (and therefore `retryable?`) and
  `EchoWire.Cmd.set(k) |> value(v) |> build()` is `write?` regardless of the key/values; the builder's flag
  derivation does not pattern-match the verb string out of `parts`; `slot/1` over a `{tag}`ged key and a bare key
  matches the CRC16 rule (a known vector, e.g. `slot("{user}:1") == slot("{user}:2")`); `run/2`'s body contains
  no `is_struct`/`is_atom`/module-name guard on the reference.
- **`EWR.1.2-INV4` — the value carries the flags; the wire never sees them (both the seam and `run/2` drop
  them).** The flags + slot live on the `%Command{}` value for a future consumer; `EchoWire.Pipe.command/2` and
  `EchoWire.Cmd.run/2` extract **only** `.parts`, so the flushed `[[binary]]` is byte-identical to the bare-verb
  form and **no flag byte reaches the wire**. The command value contributes *annotation*, never a second wire
  representation. *Check:* a pipe built with `Pipe.command(p, EchoWire.Cmd.get(k) |> build())`, a `run/2` of the
  same built command, and a pipe built with `Pipe.get(p, k)` all flush the identical command-list (assert `cmds`
  / `parts` equality offline) and produce identical replies on `6390`.
- **`EWR.1.2-INV5` — `exec/1`'s shipped contract is frozen; the seam adds no behaviour; `run/2` is a thin
  pass-through.** Appending a `%Command{}` changes neither `exec/1`'s return (`{:ok, [RESP.reply()]}` / `{:error,
  term}`) nor its wire shape nor the empty-pipe guard (`{:error, :empty_pipeline}`); `exec_txn/1` / `exec_noreply/1`
  are untouched and stay `Connector`-only. `EchoWire.Cmd.run/2` is exactly one `via.pipeline/3` over the
  command(s)' parts — it adds no pipelining, no retry, no routing this rung (the flags are advisory). *Check:*
  `exec/1`'s body is byte-identical to HEAD; `run/2`'s body reduces to one `pipeline/3` call; the story suite
  drives `exec`/`run/2` over `%Command{}`-built pipes and the returns match the `ewr.1.1` shapes exactly.
- **`EWR.1.2-INV6` — escape-hatch completeness.** Any command expressible as a `[[binary]]` list is reachable as
  a `%Command{}` via `EchoWire.Command.raw/1` (the curated builder is never a ceiling), and a `raw/1`-built
  command flushed through `Pipe.command/2` (or `run/2`) produces the same reply as the curated equivalent.
  *Check:* a command built via `EchoWire.Command.raw(["GET", k])` flushes identically to `EchoWire.Cmd.get(k) |>
  build()` and to `Pipe.get(p, k)` — the three forms are wire-equivalent.
- **`EWR.1.2-INV7` — the full `cf` flags are ADVISORY this rung (no consumer in the wire).** Nothing in
  `echo_wire`'s runtime reads any predicate (`readonly?` / `block?` / `static_ttl?` / `slot/1` / …) to change
  behaviour — the connector still fails in-flight callers `:disconnected` without replay (connector.ex:21), there
  is no slot router, there is no blocking-command dispatcher, there is no cache. The predicates exist for a
  *future* seam-4 consumer (retry / cluster / caching). *Check:* `grep -rE "readonly\?|block\?|static_ttl\?|
  pipe\?|noreply\?|retryable\?|Command\.slot|\.flags" echo/apps/echo_wire/lib/echo_mq/` is `0` (no frozen-runtime
  file consults the flags); the predicates are exercised only by the construction suites + the story layer, never
  by a dispatch path. The roadmap (seam 4) and this body both state the advisory status as a fact, not an
  omission.
- **`EWR.1.2-INV8` — a generated story exists only because a real `:valkey` test passed, and the wire stories
  regenerate idempotently + leave the bus dir byte-unchanged (the gate specifies its own liveness).** Each
  scenario in `docs/echo_mq/wire/stories/wire-pipe-command-*.stories.md` is harvested from a real `EchoMQ.Story`
  `:valkey` ExUnit test under `echo_mq/test/stories/wire_pipe_command_*_story_test.exs` that builds an
  `EchoWire.Command` (via `EchoWire.Cmd`), runs it (via `run/2` and via `Pipe.command/2`), and asserts the
  **byte-equivalence** outcome (the flagged command's reply equals the bare verb's reply — the flags being
  advisory is *proven* by the round-trip being unchanged) plus the value's flag/slot is the expected one — a
  no-op or a story authored without a passing test does **not** satisfy this letter. *Check:*
  `mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories` regenerates the wire `.stories.md` from
  `__stories__/0` **idempotently** — the committed `docs/echo_mq/wire/stories/` equals a fresh `--match
  wire_pipe` generation **byte-for-byte**, the generated scenario set equals the
  `test/stories/wire_pipe_command_*_story_test.exs` set **one-for-one**, and the sibling `docs/echo_mq/stories/`
  is **byte-unchanged** by the regen (the shared-tool no-harm assertion — L-1 sharpening); the `:valkey` story
  suite is green from `echo/apps/echo_mq/`.
- **`EWR.1.2-INV9` — the two story layers are distinct and non-contradicting.** `specs/ewr.1/ewr.1.2.stories.md`
  is the **hand-authored USER stories** (the rung acceptance — Connextra, INVEST, Given/When/Then prose a person
  signs); `docs/echo_mq/wire/stories/wire-pipe-command-*.stories.md` is the **GENERATED self-documenting proof**
  harvested from the as-built `_story_test.exs` ("the tests written back to specs"). The user stories are the
  acceptance face; the generated stories are the evidence — neither is edited to fork from the body, and the
  user-story coverage names the same command-core behaviours (the byte-equivalence proof, the full-`cf`
  truth table, the builder chain, `run/2`) the generated stories prove. *Check:* the generated-stories directory
  and the user-stories file name the same behaviour set; the body is the single authority both derive from.

**The closed error set.** `EchoWire.Command` / `EchoWire.Cmd` introduce **no new error** at the wire: they are
pure construction + a thin `run/2`, and a built `%Command{}` flushed through `Pipe.command/2` or `run/2` reuses
`ewr.1.1`'s vocabulary verbatim — `{:error, :disconnected}` / `{:error, :overloaded}` / `{:error,
{:version_fence, got}}` / `{:error, term}` on the flush, a server error carried in-band as the value
`{:error_reply, msg}` (`resp.ex:47`, which `ewr.1.3` classifies), and `{:error, :empty_pipeline}` on an empty
`exec` (unchanged from `ewr.1.1`); `EchoWire.Cmd.run/2` of an empty list answers `{:error, :empty_pipeline}` for
parity. The **builder's** only failure modes are **caller programming errors** raised at build time — an unknown
/ malformed verb argument, or `build/1` on an incomplete chain (a missing required token), raises an
`ArgumentError` (the standard Elixir contract-violation, not a wire error and not a new typed member), exactly as
a bad argument to a `Pipe` verb does; a forgotten `build/1` (passing an un-built builder to `run/2` /
`Pipe.command/2`) raises a `FunctionClauseError` / `ArgumentError` at the call boundary (the runtime cost of the
type-state token the Operator accepted). No new wire error is introduced.

## Definition of Done

- [x] `EWR.1.2-D1` — the design-make was ruled and ledgered (the flag representation — an **integer bitfield**
      mirroring `cf` with the bit-inclusion baked into the constants, static per-verb, never-parsed; the slot a
      pure CRC16-XMODEM key function; the `set |> value |> ex |> build` chain shape + `run/2` dispatch; the
      **full-cf** flag membership; the curated membership across the six families; the placement: `command.ex` +
      `cmd.ex` + the one `pipe.ex:490` seam clause + `echo_mq/test/stories/wire_pipe_command_*`) **before** any
      `.ex`/test artifact existed.
- [x] `EWR.1.2-D2`/`D3`/`D4` — `EchoWire.Command` ships the `%Command{parts, flags, slot}` struct with the full
      `cf` vocabulary as an integer bitfield (bit-inclusion baked into the constants) + `raw/1`/`raw/2`;
      `EchoWire.Cmd` ships the fluent builder across the six families (each `build/1` stamping parts + the static
      per-verb flags + the key-slot); every builder yields an immutable `%Command{}`.
- [x] `EWR.1.2-D5` — the full predicate set (`readonly?` · `write?` · `block?` · `pipe?` · `noreply?` ·
      `static_ttl?` · `retryable?` · `opt_in?` · `mt_get?` · `unsub?` · `scr_ro?`) + `slot/1` + `parts/1` answer
      from the value's flags/slot by subset-match (`flags &&& tag == tag`), so the rueidis bit-inclusion
      (`readonly?` ⇒ `retryable?`) holds for free.
- [x] `EWR.1.2-D6` — `EchoWire.Cmd.run/2` runs a built command/list against a conn-or-pool via the opaque `via`
      (on `EchoWire.Cmd`, not the facade); the **one additive `EchoWire.Pipe.command/2` clause** accepts a
      `%Command{}` (extracting `.parts`, with a one-line `@spec` widening); `pipe.ex`'s struct/verbs/`add`/`exec`
      are byte-identical to HEAD; `exec/1`'s return + wire shape are unchanged.
- [x] `EWR.1.2-INV1`/`INV2` — the facade is still 11 verbs (`EchoWire.run/2` does not exist); no frozen-runtime
      edit; the only shipped-file change is the single `pipe.ex` `command/2` head (added lines only); the
      `echo_mq` touch is test-only; no new Lua; conformance byte-stable (the count is emq-owned, not the wire's to
      pin); `echo/mix.lock` unchanged.
- [x] `EWR.1.2-INV3`/`INV4`/`INV5` — flags are static per-verb (never parsed from parts) with the bit-inclusion
      in the constants, slot is a pure key function, `run/2` carries the dispatch opaquely; the seam + `run/2`
      drop the flags (the wire sees only `.parts`, byte-identical to the bare verb — proven, and the mutation
      KILLED); `exec/1` is frozen and `run/2` is a thin pass-through.
- [x] `EWR.1.2-INV6`/`INV7` — `Command.raw/1` reaches any `[[binary]]` (wire-equivalent to the curated form); the
      full `cf` flags are advisory — no frozen-runtime file consults them (`grep` is `0`).
- [x] `EWR.1.2-INV8`/`INV9` — every generated story has a passing `:valkey` test behind it (the byte-equivalence
      proof + the flag/slot truth; **8/0**); the wire stories regenerate idempotently and leave the bus dir
      byte-unchanged; the user-story and generated-story layers name the same behaviour set and neither forks the
      body.
- [x] `EWR.1.2-D7` — the two-app gate ladder is green (`echo_wire` **109/0**, facade still 11 / `EchoWire.run`
      absent; the wire `:valkey` command stories **8/0**; the `echo_mq` conformance byte-stable, the count
      emq-owned; the `--match wire_pipe` regen idempotent + the bus dir byte-unchanged); the multi-seed sweep
      passes; the determinism posture is stated (no id-mint/process/lease → no ≥100 loop).

---

Stories: [`ewr.1.2.stories.md`](ewr.1.2.stories.md) · Agent brief: [`ewr.1.2.llms.md`](ewr.1.2.llms.md) ·
Runbook: [`ewr.1.2.prompt.md`](ewr.1.2.prompt.md) · Design (the ruling): [`ewr.1.2.design.md`](ewr.1.2.design.md) ·
Ledger: [`../progress/ewr-1-2.progress.md`](../progress/ewr-1-2.progress.md) · Chapter design:
[`../../design/ewr.design.md`](../../design/ewr.design.md) · Roadmap: [`../../ewr.roadmap.md`](../../ewr.roadmap.md) ·
Method: [`../../../../aaw/aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md)
