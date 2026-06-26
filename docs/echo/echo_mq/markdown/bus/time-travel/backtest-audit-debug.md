# Backtest, audit, debug

> Route: `/echomq/bus/time-travel/backtest-audit-debug` · Pillar II — the Bus · Module 04, dive 03.
> Grounds in `EchoMQ.Stream.read_window/6` + a page-own `codemojex` example (`Codemojex.Guesses.submit/3`,
> `Codemojex.Scoring.score/2`, `Codemojex.Rooms.close_game/1`, the real `GES` brand). As-shipped, no version labels,
> no `file:line`, **no Lua**.

## One read, three questions

The mint-instant window answers three different questions with the **same** call. Each is a `read_window/6` over a
`[t0, t1]` interval — no resident memory of the window required, because the store holds the log and the read returns
only the slice.

- **Backtest** — *how would this have behaved over that slice?* Replay a past window of events through a strategy or a
  fold, deterministically, as many times as you like. The log is the input; the window selects the slice.
- **Audit** — *what happened between X and Y?* Read exactly the entries in the interval, in mint order, as the record
  of what occurred. The branded `EVT` id on each is the canonical receipt — who, when, in what order.
- **Debug** — *what did the state look like at that moment?* Fold the window up to an instant to reconstruct a past
  state, without having kept that state around. The log remembers; the read reconstructs.

None of the three needs a side table, a snapshot store, or a resident buffer of the window. The retained log plus a
bounded read is the whole apparatus.

## A worked example — replaying a codemojex round

Take the live consumer, **codemojex** (a Telegram emoji-guessing game on this stack). Each guess is scored and
recorded with its own branded **`GES`** id and a millisecond timestamp: `Codemojex.Guesses.submit/3` validates the
guess, `Codemojex.Scoring.score/2` scores it against the secret, and the result is persisted under a freshly minted
`GES` id. Publish that same lifecycle moment to a retained stream — a `GES`-branded `EVT` activity record per scored
guess — and a round's activity becomes a **replayable log**.

Now a round runs from when it opens to when `Codemojex.Rooms.close_game/1` settles it (a perfect score or an expired
timer). To reconstruct that round's history — for an after-the-fact audit, a scoring backtest, or a debug of a
disputed result — you do not need to have streamed it live. You read the window:

```elixir
# A page-own codemojex example — replay one round's activity by its mint-time window.
# The round's guess events were appended to the stream as they happened (the GES record
# the live game already mints in Codemojex.Guesses.submit/3, scored by Scoring.score/2);
# here we read the window [opened_at, settled_at] back, in mint order, after the fact.

# the round's open and settle instants (settle is when Rooms.close_game/1 fired)
{:ok, opened_at}  = DateTime.from_iso8601("2024-05-01T14:30:00Z") |> elem(0) |> ok()
{:ok, settled_at} = DateTime.from_iso8601("2024-05-01T14:32:00Z") |> elem(0) |> ok()

# read exactly the round's window — a closed [t0, t1], both edges inclusive.
# No resident memory of the window: the store held the log; the read returns the slice.
{:ok, activity} =
  EchoMQ.Stream.read_window(conn, "cm", "round-feed", opened_at, settled_at)

# fold the GES guess events into the round's history — in mint order, by construction.
history =
  Enum.map(activity, fn {ges_id, fields} ->
    %{
      id: ges_id,                          # the branded GES receipt — who/when, canonical
      player: fields["player"],
      emojis: fields["emojis"],
      points: fields["points"]             # the Scoring.score/2 result, as recorded
    }
  end)
```

The window is the round; the slice is the round's guesses; the mint order is the order they were played. The branded
`GES` id on each entry is both the receipt and the dedup key — read the same window twice and you get the same history,
folded the same way. That is the backtest property: **deterministic replay over a past slice.**

(The **redis** course builds the same activity feed from the *pattern* side — its R5.05 workshop assembles a codemojex
activity feed on the Stream Tier. This page reads it from the *pillar-depth* side: the mint-instant window over the
retained log.)

## What time-travel covers — and the door past it

`read_window/6` reads the **live log** — the entries still resident on the stream. That covers the recent past in full.
**Deep history** — the entries a retention policy has already trimmed off the live log — is not lost: it has folded to
the durable floor. The archive's merge-read serves *archived ∪ live* as one mint-ordered stream, so a window that
reaches before the live log still resolves. That is the next module's surface — retention bounds the live log, and
`EchoStore.StreamArchive` folds what it trims into the durable **Graft** floor — and it is the Bus pillar's door to
**Echo Persistence** (`/echo-persistence`). The mint-instant read here and the archive's merge-read there are the same
idea at two depths: time is the address, whether the entry is on the live tail or on disk.

## The interactive

Pick a use case (backtest · audit · debug) and an interval over a fixed row of `GES` activity entries. The readout
shows the `read_window/6` call it issues, the mint-ordered slice it returns, and what each use case does with the slice
— replay (backtest), list (audit), fold-to-state (debug) — over a fixed dataset, no wire.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** event sourcing replays a slice of the log to reconstruct state or test a
  change; an audit reads the range of what happened. [Streams & Events](/redis-patterns/streams-events) teaches the
  replay, and its R5.05 workshop builds the codemojex feed from the pattern side.
- **The implementation (echo_mq):** one `read_window/6` over a `[t0, t1]` mint-instant interval answers all three —
  backtest, audit, debug — deterministically and without resident memory, the branded `GES` id the receipt and the
  dedup key. Deep history beyond the live log folds to the archive (`/echo-persistence`).

## Recap

Backtest, audit, and debug are one read — `read_window/6` over a mint-instant interval — applied three ways. The
codemojex round example folds a window of `GES` guess events into the round's history, deterministically, with the
branded id as receipt and dedup key. Time-travel covers the live log; deep history beyond it is the archive's
merge-read, the door to Echo Persistence. That completes the mint-instant read; retention and the archive are next.

## References

### Sources
- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — the range read `read_window/6` delegates to.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the retained log a window replays over.
- [Kreps — The Log](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — the log as the source from which state is replayed.
- [Lamport — Time, Clocks, and the Ordering of Events](https://dl.acm.org/doi/10.1145/359545.359563) — the order a replay reads by.

### Related in this course
- `/echomq/bus/time-travel/the-two-reads` — the `read_window/6` this dive applies.
- `/echomq/bus/the-stream-log` — the append that put the `GES` events on the log.
- `/redis-patterns/streams-events` — the pattern side, and the R5.05 codemojex activity-feed workshop.
- `/echo-persistence` — the durable floor deep history folds into.
- `/echomq/bus/time-travel` — the module hub.
- `/bcs/bus` — the manuscript chapter (B3) this module realizes.
