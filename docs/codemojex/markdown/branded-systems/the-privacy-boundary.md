# C1.3 — The privacy boundary

> Route `/codemojex/branded-systems/the-privacy-boundary` · dive of C1 · stamp `CMX0OSU7SXsSOa`
> Grounding re-found in `Codemojex.View` + `schemas/game.ex` + design §Privacy + `privacy.stories.md`
> on 2026-07-02.

The privacy boundary is structural, not a filter at the edge. The secret exists in exactly one
place a player can never read — the `games` row in Postgres and its immutable cache copy — and no
player-facing view selects it. The reads are shaped to carry only what is public: a player sees
their own attempt history and no one else's, and the live events and the leaderboard carry a name
and a score, never the code or the guess. A golden (blind) game tightens the gate further: it
publishes the commit-reveal commitment but never its preimage, and emits no per-guess result until
the sealed reveal at close. Privacy is a property of the shape of the reads, enforced in
`Codemojex.View` — not a redaction bolted on at the API edge.

## Shaped reads, not edge filters

`Codemojex.View`'s moduledoc states the invariant: "nothing here returns the secret, and nothing
returns another player's guesses." The three player-facing reads carry it in their shape:

- `game_view/1` builds the public map — the emojiset snapshot, the prize, the timer, the status,
  and (once revealed) the totals. It never puts `:secret`.
- `my_history/3` reads `Store.guesses_for(player, n)` — scoped to the caller — and takes
  `[:emojis, :points, :at_ms]`. A player sees their own attempts and no one else's.
- `leaderboard/2` returns `{player, max_score}` rows via `Board.top`, never the emojis.

The acceptance catalogue (`privacy.stories.md`, generated from
`test/stories/privacy_story_test.exs`) pins each:

1. the game view never carries the secret — "there is no `:secret` key anywhere in the view — only
   the keyboard snapshot."
2. a player's history shows only their own attempts — "Alice sees her own guess and nothing of
   Bob's."
3. the leaderboard exposes scores, never guess content — "every row is a `{player, score}` pair
   with no emojis attached."

## The golden gate widens

For a golden (blind) game the gate widens, and the rule is one function:

```
defp revealed?(r) do
  Map.get(r, :feedback, "score") != "none" or not is_nil(Map.get(r, :revealed_ms))
end
```

A game's score is visible when it is not blind (`feedback != "none"`) or once it has revealed
(`revealed_ms` set). So:

- **Classic** — `revealed?` is true; a guess is scored and shown live, and the totals and
  leaderboard cross the wire. There is no commitment, and the secret never leaves the server.
- **Golden, before reveal** — `revealed?` is false (`feedback == "none"`, `revealed_ms` nil). Only
  the commitment crosses the wire; it binds the server to the secret fixed at open. No per-guess
  score, no totals, no leaderboard.
- **Golden, after the sealed reveal at close** — `revealed_ms` is set, so `revealed?` is true: the
  secret and the nonce are published, a player recomputes `SHA-256(secret ‖ nonce)` and verifies
  the commitment, and the totals and leaderboard open.

## The secret's one place

`Codemojex.Schemas.Game`'s moduledoc is explicit: "the secret (and, for a golden game, the nonce)
is a server-side column and is never serialized to players." The `secret` and `nonce` fields are
written server-side and never sent; the `commitment` is published from open (public by design — it
binds the server); `revealed_ms` is the gate that opens the score. The boundary is drawn in the
shape of the data, so there is no edge that could forget to redact — the reads simply do not select
what a player must not see.

## References

### Sources

- Helland — *Life Beyond Distributed Transactions* (CIDR 2007) — the privacy seam: entities behind
  boundaries expose names, not internals. https://ics.uci.edu/~cs223/papers/cidr07p15.pdf
- Commitment scheme — Wikipedia — the hiding and binding properties the golden commitment needs.
  https://en.wikipedia.org/wiki/Commitment_scheme

### Related

- `/codemojex/branded-systems` — the chapter hub.
- `/codemojex/branded-systems/the-four-layers` — C1.2, the tier the secret rests on.
- `/codemojex/rooms-and-modes` — C2, the secret and its commitment, next.
- `/bcs` — the systems and privacy discipline.
