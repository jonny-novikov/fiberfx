# Bootstrap Report — codemojex / fiberfx@echo_mq

Generated **2026-06-29 16:53** · host `Linux 6.18.5` · result **PASS**

## Toolchain

| tool | found | expected | status |
|------|-------|----------|--------|
| gcc | `13.3.0` | any | ok |
| python3 | `3.12.3` | 3.x | ok |
| go | `1.25.11` | 1.25.x | ok |
| node | `22.22.2` | >=22 | ok |
| corepack | `0.34.6` | any | ok |
| pnpm | `11.9.0` | any | ok |
| elixir | `1.18.4` | >=1.15 (pin 1.18.4) | ok |
| erlang/otp | `25` | >=25 | ok |
| rebar3 | `3.19.0` | any | ok |
| valkey-server | `9.1.0` | >=8 (prefer 9.x) | ok |
| valkey-cli | `9.1.0` | any | ok |
| git | `2.43.0` | any | ok |
| postgres | `16.14-0ubuntu0.24.04.1` | any | ok |

## Repository

- Path: `/root/src/fiberfx`
- Branch / HEAD: `echo_mq` / `e0c54ba`
- Umbrella: `/root/src/fiberfx/echo`
- Apps (7): `codemojex`, `echo_bot`, `echo_data`, `echo_graft`, `echo_mq`, `echo_store`, `echo_wire`

## Dependencies & compile

- `mix deps.get`: **28** packages under `deps/`
- `mix compile`: **33** built libs in `_build/dev/lib`
- Umbrella apps compiled: `codemojex`, `echo_bot`, `echo_data`, `echo_mq`, `echo_store`, `echo_wire`

## Boot smoke (no Postgres / Valkey)

```text
>> GAM -> GAM0ONV4f78EPh  (parsed ns=GAM, len=14)
>> ROM -> ROM0ONV4f7hQfo  (parsed ns=ROM, len=14)
>> PLR -> PLR0ONV4f7hQfp  (parsed ns=PLR, len=14)
>> SES -> SES0ONV4f7hQfq  (parsed ns=SES, len=14)
>> JOB -> JOB0ONV4f7hQfr  (parsed ns=JOB, len=14)
>> GES -> GES0ONV4f7hQfs  (parsed ns=GES, len=14)
>> Scoring.score perfect: %{breakdown: [{0, "0000", 0, 100, "EXACT"}, {1, "0101", 0, 100, "EXACT"}, {2, "0202", 0, 100, "EXACT"}, {3, "0303", 0, 100, "EXACT"}, {4, "0404", 0, 100, "EXACT"}, {5, "0505", 0, 100, "EXACT"}], max: 600, percentage: 100, total: 600}
```

## Services

- **Valkey** 9.1.0 built from source on `:6390` · allocator `jemalloc-5.3.0`
- **PostgreSQL** on `:5432` (dev role `postgres`/`postgres`, db `codemojex_dev`)

## Boot e2e (live Postgres + Valkey)

```text
>> EMS emoji-set-01 seeded (150 cells)
>> ROOM ROM0ONWgLNhfpA (free warm-up)
>> PLAYER PLR0ONWgLPPGbY (seeded 100 clips)
>> GAME GAM0ONWgLV5FCq (joined; keyboard + secret snapshotted)
>> submit ["0000", "0100", "0200", "0300", "0400", "0500"] -> {:ok, :enqueued}
>> SCORED (async via EchoMQ consumer on Valkey): %{eff: 0, game: "GAM0ONWgLV5FCq", pct: 0, player: "e2e-player"}
>> game_view keys: [:emojiset, :ends_ms, :free, :game, :guess_fee, :prize_pool, :prize_usd, :room, :status, :totals]
>> leaderboard: [{"PLR0ONWgLPPGbY", 0}]
>> player balance after play: %{available_diamonds: 0, available_keys: 0, bonus_diamonds: 0, clips: 99, diamonds: 0, id: "PLR0ONWgLPPGbY", inserted_at: ~U[2026-06-29 16:49:27.555197Z], keys: 0, locked_diamonds: 0, name: "e2e-player", tg_chat_id: nil, tg_user_id: nil, updated_at: ~U[2026-06-29 16:49:27.591692Z]}
>> E2E OK
```

## Notes & resolutions

- Elixir 1.18.4 satisfies the pin (1.18.4).
- Pinned Elixir installed precompiled at /opt/elixir-1.18.4 (runs on the existing OTP; no OTP rebuild).
- rebar3 wired via MIX_REBAR3=/usr/bin/rebar3 (Erlang deps: telemetry, yamerl).

## Result: PASS

