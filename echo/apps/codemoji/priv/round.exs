port = String.to_integer(System.get_env("VK_PORT", "6390"))
{:ok, _} = Application.ensure_all_started(:echo_data)
{:ok, _} = Codemoji.start(port: port)
{:ok, ev} = EchoMQ.Events.start_link(connector: [port: port, protocol: 3], queue: "cm")
EchoMQ.Events.subscribe(ev, self())

drain = fn drain ->
  receive do
    {:emq_event, _n, p} -> IO.puts("   " <> p); drain.(drain)
  after
    300 -> :ok
  end
end

name = fn id -> (Codemoji.Store.player(id) || %{name: id}).name end
secret = ["🐕", "🦮", "🐕‍🦺", "🐩", "🐈", "🐈‍⬛"]

IO.puts("== Codemoji -- a live round on the bus ==")
{:ok, r} = Codemoji.start_round("dogs", secret, prize_pool: 1000, keys_cost: 1)
IO.puts("round #{r}  category dogs  prize_pool 1000  keys_cost 1")
{:ok, alice} = Codemoji.join("Alice", 5)
{:ok, bob} = Codemoji.join("Bob", 5)
{:ok, carol} = Codemoji.join("Carol", 5)
IO.puts("players: Alice #{alice} / Bob #{bob} / Carol #{carol}\n")

IO.puts("-- guesses submitted as JOBs on each player's lane; the consumer scores (event per guess) --")
{:ok, :enqueued} = Codemoji.submit(r, alice, ["🐕", "🐕‍🦺", "🦮", "🐩", "🐈‍⬛", "🐈"])
Process.sleep(300)
{:ok, :enqueued} = Codemoji.submit(r, carol, ["🐕", "🦮", "🐕‍🦺", "🦊", "🐺", "🐱"])
Process.sleep(300)
{:ok, :enqueued} = Codemoji.submit(r, bob, ["🐺", "🦊", "🐱", "🐈", "🐈‍⬛", "🐩"])
Process.sleep(300)
drain.(drain)

{:ok, board} = Codemoji.top(r, 10)
IO.puts("\n-- leaderboard cm:{round}:board   (effective = best base + first-mover tier bonus) --")
board |> Enum.with_index(1) |> Enum.each(fn {{id, eff}, i} ->
  IO.puts("#{i}. #{String.pad_trailing(name.(id), 6)} eff #{String.pad_trailing(to_string(eff), 4)} first-to-tier #{Codemoji.firsts(r, id)}")
end)

IO.puts("\n-- fair lanes: pause Bob's lane, submit (it parks), resume (it drains) --")
:ok = Codemoji.pause(bob)
{:ok, :enqueued} = Codemoji.submit(r, bob, ["🐕", "🦮", "🐕‍🦺", "🐩", "🐈", "🐈‍⬛"])
Process.sleep(300)
{:ok, d} = Codemoji.depth(bob)
IO.puts("paused: Bob's lane depth=#{d} (guess parked, unscored)")
:ok = Codemoji.resume(bob)
Process.sleep(400)
drain.(drain)
{:ok, d2} = Codemoji.depth(bob)
IO.puts("resumed: Bob's lane depth=#{d2} (drained and scored)")

IO.puts("\n-- settlement: close the round, 30% platform fee, 70% split across the top --")
{:ok, :enqueued} = Codemoji.close(r, 1000)
Process.sleep(400)
{:ok, payouts} = Codemoji.payouts(r)
IO.puts("prize_pool 1000  fee 30%  net 700")
Enum.each(payouts, fn {id, pay} -> IO.puts("payout #{String.pad_trailing(name.(id), 6)} #{pay}") end)

IO.puts("\n-- decisive point: same base, the first-mover wins (round 2) --")
{:ok, r2} = Codemoji.start_round("dogs", secret, prize_pool: 0, keys_cost: 1)
{:ok, dave} = Codemoji.join("Dave", 5)
{:ok, erin} = Codemoji.join("Erin", 5)
same = ["🐕", "🦮", "🐕‍🦺", "🦊", "🐺", "🐱"]
{:ok, :enqueued} = Codemoji.submit(r2, dave, same)
Process.sleep(300)
{:ok, :enqueued} = Codemoji.submit(r2, erin, same)
Process.sleep(300)
drain.(drain)
{:ok, b2} = Codemoji.top(r2, 10)
b2 |> Enum.with_index(1) |> Enum.each(fn {{id, eff}, i} ->
  IO.puts("#{i}. #{String.pad_trailing(name.(id), 6)} eff #{String.pad_trailing(to_string(eff), 4)} first-to-tier #{Codemoji.firsts(r2, id)}")
end)

IO.puts("\n-- BCS guess components (EchoData.Bcs.PropertyStore, GES namespace, newest first) --")
Codemoji.Store.recent_guesses(6)
|> Enum.each(fn id ->
  g = Codemoji.Store.guess(id)
  IO.puts("#{id}  #{String.pad_trailing(name.(g.player), 6)} #{String.pad_leading(to_string(g.points), 3)}pts #{String.pad_leading(to_string(g.percentage), 3)}%  tier #{g.tier}")
end)

IO.puts("\nCODEMOJI OK")
