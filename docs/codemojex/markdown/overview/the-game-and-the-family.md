# C0.1 — The game and the family

`/codemojex/overview/the-game-and-the-family` · dive C0.1 of the Overview chapter: the Mastermind
family, the feedback function as its defining element, the code space of positions and symbols,
and the six-emoji secret.

Codemojex hides a secret of six emoji drawn from a themed set; a player submits a six-code
sequence and the game reports how close it was. That loop places Codemojex in the **Mastermind
family** — the code-guessing games in which a hidden code is attacked by repeated guesses, each
answered by a report. The defining element of the family is the **feedback function** — what a
guess reveals about the secret — over a code space of positions and symbols. The three Codemojex
modes fork precisely there: classic returns a per-guess score, the blind `golden` type returns
nothing until the reveal, and a Golden Room is a live tournament on the classic base.

## A secret of six, a guess of six

- The code space is six positions over the game's snapshotted keyboard. A code is `XXYY` — column
  then row, two digits each — addressing one cell of the sprite sheet (`Codemojex.EmojiSet`).
- The secret is drawn from that same snapshot on the start path in `Codemojex.Rooms`:
  `secret = EmojiSet.secret_from(cell_codes)` — six distinct codes from the game's snapshotted
  keyboard (`@code_length 6`) — and the game is minted as a branded `GAM` around it. The keyboard
  the player taps and the secret the player chases index the same cells.
- The guess is exactly six codes, enforced at the function head:
  `Codemojex.Guesses.submit(game, player, emojis) when length(emojis) == 6`; the validation
  requires every code to be in the game's `cell_codes`. Anything that is not a valid six-element
  guess falls to the catch-all `submit/3` clause and answers `{:error, :bad_guess}`.
- Behaviour: `stories/rooms-and-games.stories.md` — "a guess submitted on the lane is scored and
  reaches the leaderboard".

## The feedback function — the family's defining element

- The Mastermind board game fixed the loop in the early 1970s: a codemaker hides a code, a
  codebreaker probes it, and every guess is answered by a report. The family varies the number of
  positions, the symbol alphabet, and — the defining element — the feedback function. The pegs of
  the board game are one choice of feedback; a numeric score is another; silence until the end is
  a third.
- In Codemojex one authority computes the report: `Codemojex.ScoreWorker` — "the scoring
  consumer — the authority" — scores every guess with `Scoring.score(secret, emojis)` and writes
  the guess as a branded `GES` with its points, keyed to the `PLR` whose lane carried it.
- The six position comparisons fold into one report per guess; a classic game publishes it as a
  `scored` event. The report is thin — a name and a percentage, not the positions that matched.
  The distance-to-points law behind the number (`100 − 20·d` per position, summing to 600) is
  C4's ground; this dive stays with what a guess reveals, and to whom.
- Behaviour: `stories/scoring.stories.md` — "the same secret and guess always score identically
  (a re-delivered guess is safe)": the feedback function is a pure function of the pair.

## One family, three feedback policies

- `Codemojex.Rooms.policies_for/2` sets the policy: feedback `"score"` for `type:"classic"` —
  ordinary rooms and the Golden-Room tournament (`golden:true`) alike; feedback `"none"` for the
  blind `type:"golden"`.
- The blind contract: "a golden game stores the guess but emits NO per-guess feedback (the blind
  contract): the score is sealed until reveal" (`Codemojex.ScoreWorker`). Every guess is still
  scored and stored server-side; no `scored` push fires in-flight and the player's own history
  withholds points; at close the sealed pass emits one `revealed` event carrying the now-exposed
  secret, the final board, and the payouts.
- A Golden Room is not a fourth feedback shape — it is a live tournament on the classic base
  (`type:"classic"`, `golden:true`), so its feedback stays `"score"`; what changes is how the
  pool settles.
- Behaviour: `stories/golden-blind.stories.md` — "a per-guess scored push does not fire for a
  golden game".

## Interactives

1. **The feedback demo (hero)** — a fixed six-code guess row over the fixed secret it probes,
   in the real `XXYY` code shape. Selecting a position names whether the guess's code matches the
   secret's code at that position, sits elsewhere in the secret, or is absent; a seventh control
   ("the report") shows the fold into one report per guess.
2. **The feedback-policy toggle** — `"score"` vs `"none"` over a two-lane timeline: under
   `"score"` a `scored` event travels back after every guess; under `"none"` the return lane
   stays empty until the close's one `revealed` event. Source: `policies_for/2`.

## Grounding

- `echo/apps/codemojex/lib/codemojex/game.ex` — `Codemojex.Guesses.submit/3` (the
  `when length(emojis) == 6` guard, the `{:error, :bad_guess}` fall-through);
  `Codemojex.ScoreWorker` (the authority; `Scoring.score(secret, emojis)`; the classic `scored`
  publish; the blind contract).
- `echo/apps/codemojex/lib/codemojex/rooms.ex` — `policies_for/2` (feedback `"score"` vs
  `"none"`); `EmojiSet.secret_from(cell_codes)` on the start path.
- `echo/apps/codemojex/lib/codemojex/emoji_set.ex` — `@code_length 6`, the `XXYY` code shape,
  `secret_from/1`.
- Stories: `rooms-and-games.stories.md` · `scoring.stories.md` · `golden-blind.stories.md`.

## References

### Sources
- Mastermind (the board game) — the guess-against-a-hidden-code loop Codemojex plays with emoji.
  https://en.wikipedia.org/wiki/Mastermind_(board_game)
- arXiv 1607.04597 — the feedback function and minimax code-breaking; the deductive structure the
  family's play sits in. https://arxiv.org/abs/1607.04597

### Related
- `/codemojex/overview` — C0, the chapter hub · `/bcs/codemojex` — this game taught inside the
  BCS course · `/bcs` — the architecture law.
