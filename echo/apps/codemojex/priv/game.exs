# A live game, end to end, on the current API.
#
# Requires Postgres (mix ecto.create && mix ecto.migrate) and Valkey on $VK_PORT.
# Run with:  mix run priv/game.exs
# The app (Repo, PubSub, EchoMQ bus + consumers, endpoint) boots automatically
# under mix, so there is no manual start here.

alias Codemojex.EmojiSet

# A 6x6 emoji set (codes default to all 36 cells), and a paid room templated on it.
# create_room/3 persists the set and warms the cache itself.
set = EmojiSet.new("Dogs", 6, 6, sprite_url: "https://cdn.example/dogs.png", cell_size: 72)

{:ok, room} =
  Codemojex.create_room("Dog House", set,
    seed_pool: 200,
    guess_fee: 1,
    duration_ms: 600_000
  )

IO.puts("== Codemojex -- a live game on the bus, persisted in Postgres ==")
IO.puts("room #{room}")

# Players with an opening key balance (a row in `players`, a CHECK keeping it >= 0).
{:ok, alice} = Codemojex.create_player("Alice", keys: 5)
{:ok, bob} = Codemojex.create_player("Bob", keys: 5)

# The first join opens the game: snapshots the keyboard, mints the secret (server-
# side, in `games.secret`), and starts the timer. The second join lands in the same game.
{:ok, game} = Codemojex.join_room(room, alice)
{:ok, ^game} = Codemojex.join_room(room, bob)
IO.puts("game #{game}\n")

# Guesses are JOBs on each player's lane; the single ScoreWorker scores them, writes
# a `guesses` row, updates the Valkey leaderboard, and broadcasts :scored on PubSub.
guess = ["0000", "0101", "0202", "0303", "0404", "0505"]
{:ok, _} = Codemojex.submit(game, alice, guess)
{:ok, _} = Codemojex.submit(game, bob, ["0000", "0101", "0202", "0303", "0404", "0501"])
Process.sleep(400)

IO.puts("leaderboard (max score per player, no guesses leaked):")

Codemojex.leaderboard(game, 10)
|> Enum.with_index(1)
|> Enum.each(fn {{p, s}, i} -> IO.puts("  #{i}. #{p}  #{s}") end)

bal = Codemojex.balance(alice)
IO.puts("\nalice balance: keys=#{bal.keys} diamonds=#{bal.diamonds}")
IO.puts("alice history (own attempts only): #{inspect(Codemojex.my_history(game, alice, 3))}")

IO.puts("\ngame view served to clients (note: no :secret key):")
IO.inspect(Codemojex.game_view(game), pretty: true)

IO.puts("\nCODEMOJI OK")
