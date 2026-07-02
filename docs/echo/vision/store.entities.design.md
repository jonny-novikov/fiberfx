# Store · The Entity Near-Cache — Codemojex on the Cache Plane, with Time Travel { id="store-entities-design" }

> _EchoMQ is far beyond background jobs. It is the **Queue** (distribute work: enqueue, claim, retry, complete), the **Bus** (broadcast signals: pub/sub events and a retained, replayable log), and the **Cache** (serve reads: an L1 ETS / L2 Valkey near-cache kept coherent on the Bus). This design makes the Cache plane first-class for the worked product: the codemojex entities declared as cache tables, versioned by the events that change them, time-travelled on the Bus's own log, and served to both live surfaces — LiveView and the game island — through one coherence signal. Register: the store canon beside `store.design.md`; every shipped surface cited is real at `0c0fd19`; every new surface is marked PROPOSED and parked as a fork where a genuine choice remains._

## Scope and method

Grounded, not invented: the shipped `EchoStore.Table` (caller-side `fetch/3`, versioned `put/4`, `apply_coherence/4`, `coherence_handler/1`, `invalidate/3`, the three declared coherence modes `:none | :broadcast | :tracking`), `EchoStore.Coherence` (the two-identity payload, `newer?/2` on the eleven payload bytes, `drop_l2/4`, `broadcast/4`, `enqueue/5`), `EchoStore.Ring`, `EchoStore.Journal`, the Stream Tier's per-name time-travel verbs (`EchoMQ.Stream.read_window/6`, `read_since/5`), `EchoStore.StreamArchive` + `StreamHydrator`, the Graft floor, and the codemojex read facade (`view.ex` — `game_view/1`:49, `my_history/3`:92, `leaderboard/2`:105 — plus `Codemojex.Store.player/1`, a `Repo.get` per call). What is decided here: the table set, the version convention, the log-on-the-Bus time-travel shape, and the two consumer integrations. What is not claimed: any performance figure — no cache benchmark is committed in this tree, so none is cited; the wins are stated as read-shape changes (which reads leave Postgres, which fan-outs collapse), never as numbers.

## The reads this cache fronts (as-built cost shape)

Every `{:scored, …}` broadcast makes `GameLive` rebuild props for every connected viewer: `game_view/1` (a `Store.game/1` read plus assembly), `leaderboard/2` (the Board ZSET read, then — for the named rows — `Codemojex.Store.player/1` per row, each a `Repo.get(Player, id)`), and `my_history/3` per viewer. The fan-out that matters is the shared one: one scored guess with V viewers and a K-row leaderboard costs on the order of V × K player reads against Postgres, for values that changed once. The per-viewer read (`my_history`) is private and cheap by comparison. The cache's job is exactly the shared fan-out: **the same value, read by many, invalidated by one event.**

## The declared tables

The first law of Part IV holds: the cache is declared, not discovered. Four tables enter the directory; each names its kind, TTL, coherence mode, and loader (the loader is the existing facade read — the cache adds no second read path):

- **`cmx.view`** — kind `GAM`, value = the `game_view/1` map, mode `:broadcast`, TTL one game's length plus slack. Loader: `Codemojex.game_view/1`. The highest-fan-out read in the product.
- **`cmx.leader`** — kind `GAM`, value = the named leaderboard rows (top K with player names resolved), mode `:broadcast`, TTL as `cmx.view`. Loader: `leaderboard/2` composed with `cmx.player` fetches for the names — so the per-row `Repo.get` is paid once per invalidation for all viewers, not once per row per viewer per push.
- **`cmx.player`** — kind `PLR`, value = the public subset (name; never balances — F-B), mode `:broadcast`, long TTL. Loader: `Codemojex.Store.player/1` projected to the public fields.
- **`cmx.set`** — kind `EMS`, value = the emoji set snapshot, mode `:tracking`, long TTL. Sets are written rarely and read at every keyboard render; the server-assisted mode fits a value with no interesting version history — Valkey pushes the eviction, the next fetch refills.

Kept out of the directory, deliberately: the wallet (money is not cached — F-B), the room row (read inside `game_view` already; a separate table is a later measurement, not a default), and `my_history` (a composite-name read — F-A).

One mode per table is the rule: `:broadcast` carries a version and a story; `:tracking` carries an eviction and no story. A table that wants time travel below must be `:broadcast`, because the version is the log's key.

## Writers and the version convention

A version is a branded id whose eleven payload bytes are the mint clock — that is the whole coherence contract, and it invites a convention this design adopts (F-D): **the version of a cache write is the id of the event that caused it.** A scored guess mints a `GES`; the scoring worker, after writing the `GES` and the Board row, computes the fresh `cmx.view` and `cmx.leader` values and calls the shipped `Table.put/4` with the `GES` id as the version, then `Coherence.broadcast/4` on each table's channel. A wallet mutation's causing id is its `TXN` ledger row — relevant only to the job lane it would ride if money were ever cached, which it is not here. Where no causing entity exists (a settlement tick flipping `revealed?`), the writer mints a fresh id for the version — the fallback arm of F-D, used only when the primary arm has nothing to point at.

The convention buys two things beyond newer-wins: causality is legible (the version in a stale-read complaint names the exact guess that produced the value), and the time-travel log below needs no second identity — the entry's version *is* its place in time.

## Time travel — the log is the Bus's own

The Bus already owns a retained, replayable log with per-name reads; time travel for the cache is a use of it, not a new tier.

**The entity log (PROPOSED, additive).** A `:broadcast` table may declare `log: true`. With it, the versioned `put/4` path also appends one entry to the table's entity log — an EchoMQ stream on the queue **`ecc.log.<table>`** (the naming sibling of the shipped coherence queue `ecc.coh.<table>`), entry name = the entity id, fields = `{version, value}` (full snapshot — F-C). Retention is a declared policy per table, exactly as the Stream Tier requires; a trimmed log folds into the Graft floor through the shipped `StreamArchive`, and `StreamHydrator` windows it back — deep entity history without resident memory, the same law B5 already states for streams generally.

**The read verbs (PROPOSED).** Two reads over the shipped per-name stream verbs, plus the clock mapping the identity contract already carries (the snowflake's 41 millisecond bits above epoch `1704067200000` convert a version to a `DateTime` and back):

- `EchoStore.at(table, id, %DateTime{} = t)` — the value current at `t`: the last entry for `id` in `read_window(conn, "ecc.log." <> table, id, t0, t, …)`, where the window's coarse cut is time and the exact cut is the entry's own version bytes (two writes in one millisecond disambiguate by the version, which is total).
- `EchoStore.at_version(table, id, version)` — the same read with `t` derived from the version's clock bits, filtered to entries with version bytes not newer than the argument.

Both are pure reads over one queue and one name; a miss past the live tail falls to the hydrated archive window, and a miss past retention answers a named `:beyond_retention` rather than a fabricated value.

**The strong cross-entity snapshot.** Per-entity `at/3` is time-consistent by the mint clock but makes no cross-table transaction claim. Where a settled game needs a serializable whole (audits, disputes), the answer is the floor, not the cache: the settlement path commits the game's terminal state to a Graft volume, and a `CMT` snapshot read is the cross-entity time machine. The cache's time travel is for the live and recent; the floor's is for the permanent — the same division B5 draws.

## Integration — one signal, two surfaces

**The bridge (PROPOSED, one small owner-started module).** `EchoStore.CoherenceBridge`: subscribes, on its own connector lane (the `EchoMQ.Events` precedent), to each declared table's coherence channel `ecc:{table}:coh`, parses the two-identity payload, and re-broadcasts `{:ecc, table, id, version}` on `Phoenix.PubSub` under topic `"ecc:" <> table <> ":" <> id`. It applies nothing itself — the Ring applier owns L1 application; the bridge is the notification's last hop into the web layer. Opt-in, owner-started, per the library law.

**LiveView.** `GameLive` mounts, fetches its props through the tables (`fetch/3` — a caller-side ETS hit on the warm path), and subscribes to `ecc:cmx.view:<gam>` and `ecc:cmx.leader:<gam>`. On `{:ecc, _, _, version}` it re-fetches (the invalidation has already landed or the fetch coalesces onto the fill) and pushes `"game:update"` with the props **plus the version** — one new additive field `v` on `GameProps`. The `{:scored, …}` PubSub remains for game-flow concerns (sounds, toasts); the read path no longer rides it.

**The game island.** `GameEdge`'s contract stays props-are-authoritative; it gains one rule: **apply an update only if it is newer.** The check is the order theorem's client-side corollary — the base62 alphabet `0-9A-Za-z` is ASCII-ascending, so for the fixed-width eleven-byte payloads, plain string comparison equals mint order in JavaScript exactly as `Coherence.newer?/2` computes it in Elixir: `next.v.slice(3) > cur.v.slice(3)` gates application (F-E). Out-of-order delivery across a flaky socket converges to the newest value with no sequence numbers and no server state.

**The channel twin.** For the socket-served island, `RoomChannel`'s join reply carries the current `v` per entity; a client `"refresh"` may carry `since: v`, answered by nothing-newer or by a `read_since` replay of the missed frames from the entity log — reconnect catch-up as a log read, not a full re-fetch.

**Spectate and replay (the time-travel payoff).** A finished game replays from its own history: the server walks `read_window` over `cmx.view` and `cmx.leader` for the `GAM`, and the island receives the same `"game:update"` frames it would have received live, versions intact, on a clock the client controls — the golden-reveal timeline, post-game review, and dispute playback are one mechanism. A spectator joining late is the degenerate case: catch up by `read_since`, then ride the live channel.

## The forks (parked index)

| Fork | The choice | Arms (brief) | Venus recommends |
|---|---|---|---|
| **F-A · composite-name reads** | what to do with `my_history` (keyed by game *and* player) | A1 leave it a direct read · A2 cache per-guess under the `GES` id and assemble · A3 derive a pair identity | **A1** — it is per-viewer and low fan-out; the cache's mandate is shared fan-out, and a pair identity is a new identity law this design does not need |
| **F-B · money** | whether balances enter the cache | B1 job-lane coherence + a wallet table · B2 never cache money | **B2** — a wallet read is per-owner, already cheap, and a stale balance shown once costs more trust than every cached read saves |
| **F-C · log payload** | what an entity-log entry carries | C1 full value snapshot · C2 delta against the prior version | **C1** first — replay and `at/3` are one entry; sizes are measured on the committed log before C2 is considered |
| **F-D · version source** | where a write's version comes from | D1 the causing event's id (`GES`, `TXN`), fresh mint only when none exists · D2 always a fresh mint | **D1** — no extra mint on the hot path, and causality reads straight off the version |
| **F-E · stale-drop** | who enforces update monotonicity at the island | E1 client compares version bytes · E2 server sequences per socket | **E1** — the theorem makes the comparison free and stateless; per-socket state is a cost with no added guarantee |

## The gates (when the rungs build)

- **The door** — a wrong-namespace id refused before either layer, per table (the shipped `Table` law, re-drilled with each declaration).
- **Idempotence** — the same version applied twice answers stale the second time, on both lanes (the `Coherence` law as a drill).
- **One fill per herd** — N concurrent misses on one key produce one loader call (the `Table` law, drilled against the codemojex loaders specifically).
- **Replay parity** — for a recorded sequence of versioned puts, `at/3` at each write's own time reproduces exactly that write's value; the log and the cache never disagree about history.
- **Island monotonicity** — frames delivered out of order converge to the max-version state; the fixture is a shuffled frame set, the assertion is final-state equality.
- **Bridge hygiene** — subscription count returns to baseline across LiveView mount/unmount cycles (the dash.2 precedent, applied here).

## Boundaries

Every new surface here is PROPOSED and additive: the `log:` declaration and its append inside the versioned put path, `at/3` and `at_version/3`, `EchoStore.CoherenceBridge`, the `v` field on `GameProps`, and the channel's `since` refresh. Nothing shipped is edited — `put/4`, `apply_coherence/4`, the coherence verbs, `read_window`/`read_since`, the archive and hydrator are consumed as-is, and the byte-frozen bus scripts are untouched. No performance figure is asserted; the design's claims are structural (which reads leave Postgres, what one invalidation fans out to). One coherence mode per declared table; a `:tracking` table has no version and therefore no log. Money stays out of the cache by F-B until an Operator ruling says otherwise, and the cross-entity strong snapshot belongs to the Graft floor, not to this plane.
