# Codemojex specs

Spec stories and documentation produced against the freshly refreshed `echo_mq`
branch (see `ENVIRONMENT.md`). Two halves: **runnable Given/When/Then game specs
for Codemojex** (Elixir, in the repo's own self-documenting BDD style), and
**documentation + spec-story catalogues for the three libraries** underneath it.

## What's here

```
codemojex/
  test/support/codemojex/story.ex        Codemojex.Story — the BDD DSL (mirrors EchoMQ.Story)
  test/stories/                          the Given/When/Then game specs (7 feature files)
    scoring_story_test.exs               pure — runs anywhere
    economy_story_test.exs               pure
    emoji_codes_story_test.exs           pure
    rooms_and_rounds_story_test.exs      integration — @moduletag :valkey (+ Postgres)
    wallet_story_test.exs                integration
    privacy_story_test.exs               integration
    settlement_story_test.exs            integration
  lib/mix/tasks/codemojex.stories.ex     mix codemojex.stories — generates the catalogue

docs/
  echo_data.md        BCS: branded ids, snowflakes, component stores
  echo_store.md       L1-over-L2 cache, coherence, Graft replication
  echo_mq.md          lanes, jobs, flows, events, locks, the stories convention
  echo_data/stories/  authored spec-story catalogues (branded-ids, property-store)
  echo_store/stories/ authored spec-story catalogues (cache-aside, coherence)

ENVIRONMENT.md        the refresh result + the local bench check
```

## The Codemojex specs — Given/When/Then in Elixir

Each feature is a module using `Codemojex.Story`, so the same source is **both a
runnable ExUnit acceptance test and the source of a generated story** — exactly the
pattern `echo_mq` already uses (`EchoMQ.Story` + `mix echo_mq.stories`). A
`given_`/`when_`/`then_` step runs its body inline (one shared scope) and its text
is harvested at compile time into `__stories__/0`; `mix codemojex.stories` reads
that registry and writes `docs/codemojex/stories/<feature>.stories.md` without
running the suite.

- **Pure** (scoring, economy, emoji codes) need nothing but the modules — they
  encode the validated math: an exact crack is 600/100%/tier 30; points fall
  100→0 over distance 0..5; diamonds convert 10:1; 283 💎 = `$3.40`; winner-take-all
  splits a tie; an XXYY code maps to its sprite offset; the snapshot leaks no
  secret.
- **Integration** (`@moduletag :valkey`, also need Postgres + the app up) assert
  behaviour that does **not** depend on the random secret: a first join opens a
  round and a later join lands in it; a paid guess debits one key and never goes
  negative; a free guess spends a clip; the round view and history never expose the
  secret or another player's guesses; a close pays the leader winner-take-all and a
  second close is a no-op (exactly-once).

## Placement

Drop the `codemojex/` subtree into `apps/codemojex/` on the branch, and the `docs/`
subtree into the repo root. The story DSL goes in `test/support` (so it compiles
only under `MIX_ENV=test`); the generator goes in `lib/mix/tasks`. The branch
already carries `apps/codemojex` and `apps/echo_store`, so these files slot into the
canonical tree rather than creating it.

## Honest status

Written against the fresh source's real APIs; **not compiled or run** — there is no
Elixir/OTP toolchain, Postgres, or Valkey on the authoring box (see
`ENVIRONMENT.md`). The pure math was validated in Python and matches. The proof on
a real bench is:

```sh
mix cmd --app codemojex mix test                    # pure stories
mix cmd --app codemojex mix test --include valkey   # + integration stories
mix codemojex.stories                               # regenerate the catalogue
```

The `docs/echo_data/stories/*` and `docs/echo_store/stories/*` catalogues are
**authored** acceptance criteria in the generator's format (echo_mq's catalogue is
already generated in-repo, so it is documented in `echo_mq.md` rather than
duplicated). Each can be made generated-and-proven by backing it with an
`EchoData.Story` / `EchoStore.Story` test module — the same pattern as
`Codemojex.Story`.
