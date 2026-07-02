# C0.2 · The engine and its policies

> **Route** `/codemojex/overview/the-engine-and-its-policies` · chapter [C0 · Overview](/codemojex/overview)
> **Grounding** `echo/apps/codemojex/lib/codemojex/rooms.ex` (`policies_for/2` · `start_game/3` ·
> `do_close/2`) · `lib/codemojex/schemas/game.ex` (`schema "games"`) · design §The engine — a generic
> Mastermind, the modes are policy · `stories/rooms-and-games.stories.md`
> **Pager** prev [C0.1 · The game and the family](/codemojex/overview/the-game-and-the-family) ·
> next [C0.3 · The architecture at a glance](/codemojex/overview/the-architecture-at-a-glance)

The Game system is a generic Mastermind engine. A game — a branded `GAM` — carries a **type** and the
four policies the type selects — `feedback`, `scoring`, `settlement`, `economy` — and the secret, the
guess, and the distance math are one code path shared by every type. This dive quotes the fork that
assigns the four values, follows them onto the game's own row, and then shows the close path
dispatching on one of them at settlement. Underneath sits the BCS identity law: the brand is the
type, so a radical variant is a new set of policy values on the same entities, not new code.

**Hero interactive — the policy fork as a pattern match.** Two inputs (`type:` `"classic"`/`"golden"`,
`golden:` `false`/`true`) drive an SVG of the three `policies_for/2` clauses. Four input combinations
land on three clauses; the readout prints the exact returned map; the teal `scoring` cell reads
`linear` in every clause.

## The fork, verbatim

Three function clauses assign every policy the engine runs. `Codemojex.Rooms.policies_for/2` is a
pure lookup from `(type, golden)` to the four policy values — pattern-matched in clause order,
derived in code, never stored on the room.

```elixir
  # The (type, golden)→policy lookup: the four policies are a pure function of the
  # type and the tournament marker, derived in code and snapshotted onto the game (a
  # game stays self-describing for settlement and replay).
  #
  #   * type "golden"            → blind/sealed top-K (the commit-reveal mode), any flag;
  #   * type "classic", golden   → the live top-K tournament (cm.5 R6: live_split /
  #                                proportional — "proportional" LABELS top_k_split,
  #                                a rank-weighted split, not Economy.proportional/2);
  #   * type "classic", ordinary → live winner-take-all.
  defp policies_for("golden", _golden),
    do: %{feedback: "none", scoring: "linear", settlement: "sealed", economy: "winner_take_all"}

  defp policies_for(_classic, true),
    do: %{feedback: "score", scoring: "linear", settlement: "live_split", economy: "proportional"}

  defp policies_for(_classic, _ordinary),
    do: %{feedback: "score", scoring: "linear", settlement: "live", economy: "winner_take_all"}
```

Clause order carries the semantics. The first clause matches on the type alone — the `_golden`
wildcard discards the marker, so `type: "golden"` reaches the blind, sealed mode whatever the flag
reads. The second clause requires the marker: `policies_for(_classic, true)` is the Golden Room, a
live top-K tournament on the classic base. The third clause is the floor — an ordinary classic game,
live feedback and a winner-take-all pool.

The comment above the room map in `create_room/3` pins the distinction: `golden: true` is a
tournament marker, orthogonal to the type — a Golden Room is `type: "classic"` and fans out live;
the blind mode is reached only by an explicit `type: "golden"`.

One label carries its own gloss: in the second clause, `"proportional"` labels `top_k_split` — a
rank-weighted split over the pool — not `Economy.proportional/2`, a different function. The fork's
own comment records this.

And one value never moves: `scoring: "linear"` appears in all three clauses. The distance math —
`100 - 20·d` per position, summing to 600 for a perfect crack — is the one path every mode shares.
The fork moves only what a guess reveals, when settlement runs, and how the pool pays.

## Snapshotted onto the game

The fork's result does not stay in code. When the first player joins a waiting room and opens its
game — the first scenario of `rooms-and-games.stories.md` — `start_game/3` mints the `GAM` and copies
the type and all four policy values onto the game map. In the code's own words, a game stays
self-describing for settlement and replay.

```elixir
  defp start_game(room_id, room, player) do
    case Cache.fetch_set(room.emojiset) do
      %EmojiSet{} = set ->
        gid = EchoData.BrandedId.generate!("GAM")
        now = System.system_time(:millisecond)
        type = Map.get(room, :type, "classic")
        golden = Map.get(room, :golden, false)
        policy = policies_for(type, golden)
        …
        cell_codes = snapshot_cells(set, Map.get(room, :cell_count))
        secret = EmojiSet.secret_from(cell_codes)

        game =
          %{
            room: room_id,
            emojiset: set.id,
            type: type,
            feedback: policy.feedback,
            scoring: policy.scoring,
            settlement: policy.settlement,
            economy: policy.economy,
            secret: secret,
            …
```

The map row lands in one table. `Codemojex.Schemas.Game` declares `schema "games"` — one table for
every mode, with the discriminator and the four policies as plain columns: `field :type, :string,
default: "classic"` · `field :feedback, :string, default: "score"` · `field :scoring, :string,
default: "linear"` · `field :settlement, :string, default: "live"` · `field :economy, :string,
default: "winner_take_all"`. The schema's own comment names the shape: the engine discriminator +
the four policies the type selects (snapshotted from the room at start).

One table, not a table per type, because in BCS the brand is the type. The 14-byte `GAM` id is the
one value that crosses every boundary — the Postgres row, the near-cache entry, the bus message, the
channel topic. A per-type table would fork that one identity; the discriminator keeps one entity
whose behaviour is data.

The snapshot also protects a game in flight. The comment beside the golden props reads: Golden Rooms
props are snapshotted, so a game in flight is unaffected by a later edit to its room. The split
weights carry the same note — a game settles by the split it was created under.

## The close reads the snapshot

A close can arrive hours after the start — on a perfect crack or an expired timer — and the policy
travels with the row. `close_game/1` takes the exactly-once lock (one `SET cm:<game>:closed NX` on
the wire) and hands the game map to `do_close/2`, which dispatches on the settlement value alone.

```elixir
  defp do_close(game, r) do
    case Map.get(r, :settlement, "live") do
      "sealed" -> close_sealed(game, r)
      "live_split" -> close_split(game, r)
      _ -> close_live(game, r)
    end
  end
```

**Content interactive — the settlement dispatch.** A segbar of the settlement values (`"live"`,
`"live_split"`, `"sealed"`, plus the absent case) selects the `do_close/2` branch it reaches; an SVG
maps each value to `close_live` / `close_split` / `close_sealed`; the readout describes the payout
path, grounded in the three close functions.

All three branches end the same way: the game is written back settled and the room returns to
waiting for its next game. The difference is the pay. `close_live` ranks the board (`Board.top`) and
pays the whole pool to the max-score player (`Economy.winner_take_all`). `close_split` reads the
board wide enough to cover every member, drains the pool to the top-K by the split weights
(`Economy.top_k_split`), and grants every other member `div(score, 10)` consolation clips in one
`Wallet.distribute_pool` transaction — no reveal phase. `close_sealed` first exposes the secret and
nonce (status `:revealing`), then pays the top-K and broadcasts one fat `revealed` event carrying
the secret, the nonce, the commitment, the final board, and the payouts.

The dispatch reads `r` — the game's own map — not the room. The policy value chosen at start selects
the behaviour at close; the engine consults the game's snapshot. The three closes in depth are C4's
territory.

## What a new mode costs

The design's claim, and the shipped history behind it: a radical variant is a new set of policy
values on the same entities, not new code. The Golden Room tournament arrived exactly this way
(cm.5) — a third settlement value, `live_split`, with its economy label `proportional`, on the same
`GAM`, the same `games` table, the same linear scoring, the same secret path. No new table, no new
branded namespace, no second engine.

Four `(type, golden)` combinations land on three clauses today; a new mode is a new clause returning
a new map of the same four keys. Modes thread the course rather than owning a chapter: the secret
and its commitment are C2 (`/codemojex/rooms-and-modes`), the three closes in depth are C4
(`/codemojex/scoring-and-settlement`), the buy-in-funded pool is C5 (`/codemojex/the-economy`).

## References

### Sources

- [Mastermind — the board game](https://en.wikipedia.org/wiki/Mastermind_(board_game)) — the family
  the engine generalizes: a code space and a feedback function; everything else is policy.
- [Helland — Life Beyond Distributed Transactions](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) —
  entities behind boundaries: one identity crossing every tier, the discipline behind the one
  `games` table.
- [arXiv 1607.04597 — the feedback function and minimax code-breaking](https://arxiv.org/abs/1607.04597)
  — the deductive structure the linear distance scoring sits in.

### Related

- [/codemojex/overview](/codemojex/overview) — C0, the chapter this dive belongs to; the mode
  selector it deepens.
- [/codemojex/overview/the-game-and-the-family](/codemojex/overview/the-game-and-the-family) — C0.1,
  the family and the feedback function.
- [/codemojex/overview/the-architecture-at-a-glance](/codemojex/overview/the-architecture-at-a-glance)
  — C0.3, the four layers the engine sits in.
- [/codemojex/scoring-and-settlement](/codemojex/scoring-and-settlement) — C4, the three closes in
  depth.
- [/bcs](/bcs) — the identity law: the brand is the type.
