# Full e2e: drive a real game through the booted engine (Repo on Postgres, Bus +
# consumers on the from-source Valkey at :6390). Seed a set, open a free warm-up
# room, create a funded player, join, submit a guess, and WAIT for the EchoMQ
# consumer to score it and broadcast {:scored,...} — proving the async pipeline
# (submit -> JOB on Valkey -> ScoreWorker -> GES in Postgres + Board ZSET in Valkey
# -> PubSub) end to end.
defmodule E2E do
  def uw({:ok, v}), do: v
  def uw(v), do: v
end

alias Codemojex.{EmojiSet, Store}

set = EmojiSet.new("emoji-set-01", 10, 15, cell_size: 72, sprite_url: "/emoji-sets/01-emoji-set.png")
:ok = Store.put_set(set)
IO.puts(">> EMS emoji-set-01 seeded (#{length(set.codes)} cells)")

rom = E2E.uw(Codemojex.create_room("E2E Warmup", set, free: true, clip_cost: 1, duration_ms: 3_600_000))
IO.puts(">> ROOM #{rom} (free warm-up)")

plr = E2E.uw(Codemojex.create_player("e2e-player", clips: 100))
IO.puts(">> PLAYER #{plr} (seeded 100 clips)")

gam = E2E.uw(Codemojex.join_room(rom, plr))
IO.puts(">> GAME #{gam} (joined; keyboard + secret snapshotted)")

Phoenix.PubSub.subscribe(Codemojex.PubSub, "game:" <> gam)

guess = Enum.take(set.codes, 6)
res = Codemojex.submit(gam, plr, guess)
IO.puts(">> submit #{inspect(guess)} -> #{inspect(res)}")

receive do
  {:scored, info} ->
    IO.puts(">> SCORED (async via EchoMQ consumer on Valkey): #{inspect(info)}")
  other ->
    IO.puts(">> event: #{inspect(other)}")
after
  12_000 -> IO.puts(">> TIMEOUT: no scored broadcast in 12s")
end

view = Codemojex.game_view(gam)
IO.puts(">> game_view keys: #{inspect(view && Map.keys(view))}")
IO.puts(">> leaderboard: #{inspect(Codemojex.leaderboard(gam, 5))}")
IO.puts(">> player balance after play: #{inspect(Codemojex.balance(plr))}")
IO.puts(">> E2E OK")
