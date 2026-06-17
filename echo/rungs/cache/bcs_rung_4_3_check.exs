# bcs_rung_4_3_check.exs -- gates G1..G6: the single writer and the ring.
#   cd /Users/jonny/dev/jonnify/echo && mix run --no-start rungs/cache/bcs_rung_4_3_check.exs   (Valkey live on 6390)
for f <- ~w(base62 native snowflake branded_id) do
  Code.require_file(Path.expand("../../apps/echo_data/lib/echo_data/#{f}.ex", __DIR__))
end

for f <- ~w(resp script keyspace connector jobs lanes consumer) do
  Code.require_file(Enum.find([Path.expand("../../apps/echo_wire/lib/echo_mq/#{f}.ex", __DIR__), Path.expand("../../apps/echo_mq/lib/echo_mq/#{f}.ex", __DIR__)], &File.exists?/1))
end

for f <- ~w(keyspace echo_cache coherence ring table) do
  Code.require_file(Path.expand("../../apps/echo_cache/lib/echo_cache/#{f}.ex", __DIR__))
end

:ok = EchoData.Snowflake.start(9)
Process.flag(:trap_exit, true)
alias EchoCache.{Coherence, Ring, Table}
alias EchoData.BrandedId
alias EchoMQ.Connector

defmodule G do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end

  def await(fun, deadline_ms \\ 5_000) do
    t0 = System.monotonic_time(:millisecond)

    Enum.reduce_while(Stream.cycle([nil]), :pending, fn _, _ ->
      cond do
        fun.() -> {:halt, :ok}
        System.monotonic_time(:millisecond) - t0 > deadline_ms -> {:halt, :timeout}
        true -> Process.sleep(5) && {:cont, :pending}
      end
    end)
  end
end

{:ok, probe} = Connector.start_link(port: 6390)
{:ok, info} = Connector.command(probe, ["INFO", "server"])

vv =
  info
  |> String.split("\r\n")
  |> Enum.find_value(fn
    "valkey_version:" <> v -> v
    _ -> nil
  end)

IO.puts(
  "header: Valkey #{vv} on 6390 | Elixir #{System.version()} OTP #{:erlang.system_info(:otp_release)} | schedulers #{System.schedulers_online()}"
)

test = self()

# G1 -- the surface and the declaration
loader = fn _ -> {:ok, "px=100.00"} end

{:ok, _} =
  Table.start_link(
    name: :g1b,
    table: "g1b",
    kind: "AST",
    ttl_ms: 60_000,
    coherence: :broadcast,
    ring_capacity: 512,
    loader: loader,
    connector: [port: 6390]
  )

{:ok, _} =
  Table.start_link(
    name: :g1n,
    table: "g1n",
    kind: "AST",
    ttl_ms: 60_000,
    coherence: :none,
    loader: loader,
    connector: [port: 6390]
  )

{:ok, sb} = EchoCache.spec(:g1b)
{:ok, sn} = EchoCache.spec(:g1n)

g1 =
  G.line(
    "G1 surface",
    Enum.all?(
      [start_link: 1, publish: 2, occupancy: 1, stats: 1, stop: 1],
      &(&1 in EchoCache.Ring.__info__(:functions))
    ) and
      {:apply_batch, 2} in EchoCache.Table.__info__(:functions) and
      sb.ring == {:coh, :g1b} and sb.ring_capacity == 512 and
      sn.ring == nil and sn.ring_capacity == nil and
      Ring.occupancy({:coh, :g1b}) == 0,
    "the ring's surface is whole -- publish, occupancy, stats, stop, a generic one-batch apply function -- and the declaration tells the truth: the broadcast table carries its ring name and capacity 512 in the directory, the :none table carries nil, and a fresh ring stands at occupancy 0"
  )

:ok = Table.stop(:g1b)
:ok = Table.stop(:g1n)

# G2 -- arrival order through batches, one wake per busy period
IO.puts("derive (order): the applier drains everything between head and tail in one pass, so concatenating the batches must reproduce publish order exactly; wakes are edge-triggered on the empty-to-nonempty transition, so 1000 items published into a draining ring should cost a handful of wakes -- well under fifty -- and more than one batch proves the batching is real")
{:ok, _} =
  Ring.start_link(
    name: :g2,
    capacity: 2_048,
    apply_fn: fn b ->
      send(test, {:g2, b})
      Process.sleep(1)
      :ok
    end
  )

Enum.each(1..1_000, fn i -> :ok = Ring.publish(:g2, i) end)
:ok = G.await(fn -> Ring.stats(:g2).applied == 1_000 end)

flush = fn flush, acc ->
  receive do
    {:g2, b} -> flush.(flush, acc ++ b)
  after
    0 -> acc
  end
end

items = flush.(flush, [])
st2 = Ring.stats(:g2)
:ok = Ring.stop(:g2)

g2 =
  G.line(
    "G2 order",
    items == Enum.to_list(1..1_000) and st2.applied == 1_000 and st2.batches > 1 and
      st2.batches < 1_000 and st2.max_batch > 1 and st2.wakes <= st2.batches and st2.wakes < 50,
    "1000 items crossed the ring in publish order exactly -- the concatenated batches reproduce the sequence -- through #{st2.batches} batches (largest #{st2.max_batch}) on #{st2.wakes} wakes: one message per busy period, not one per item"
  )

# G3 -- occupancy as the gauge, then the ring priced
IO.puts("derive (throughput): a publish is one ETS insert and three atomics operations, near 0.5 to 1 us, and the apply side amortizes to nothing over batches -- so publish cost alone governs, and the end-to-end rate on one scheduler should land between 100,000 and 2,500,000 items per second, floor 80,000; mid-storm occupancy must sit strictly between zero and capacity and drain to exactly zero")
{:ok, _} =
  Ring.start_link(
    name: :g3a,
    capacity: 4_096,
    apply_fn: fn _b ->
      Process.sleep(5)
      :ok
    end
  )

Enum.each(1..600, fn i -> :ok = Ring.publish(:g3a, i) end)
mid_occ = Ring.occupancy(:g3a)
:ok = G.await(fn -> Ring.stats(:g3a).applied == 600 end)
occ_after = Ring.occupancy(:g3a)
:ok = Ring.stop(:g3a)

{:ok, _} = Ring.start_link(name: :g3b, capacity: 131_072, apply_fn: fn _ -> :ok end)
n = 100_000
t0 = System.monotonic_time(:microsecond)
Enum.each(1..n, fn i -> :ok = Ring.publish(:g3b, i) end)
:ok = G.await(fn -> Ring.stats(:g3b).applied == n end)
wall_us = System.monotonic_time(:microsecond) - t0
rate = trunc(n * 1_000_000 / wall_us)
st3 = Ring.stats(:g3b)
:ok = Ring.stop(:g3b)

g3 =
  G.line(
    "G3 occupancy",
    mid_occ > 0 and mid_occ <= 4_096 and occ_after == 0 and
      rate >= 80_000 and rate <= 2_500_000 and st3.dropped == 0,
    "mid-storm the gauge read #{mid_occ} of 4096 and drained to exactly 0; priced, the ring moved #{n} items in #{div(wall_us, 1000)} ms -- #{rate} items per second end to end on one scheduler, inside the derived band, largest batch #{st3.max_batch}, nothing dropped"
  )

# G4 -- full is a counted refusal, never a block and never an overwrite
IO.puts("derive (full): with capacity 64 and the applier held inside its first apply, exactly 64 publishes are accepted and 136 are refused and counted; releasing the applier drains the 64, and the next publish lands -- the ring under storm refuses, recovers, and keeps serving")
gate = :atomics.new(1, [])

{:ok, _} =
  Ring.start_link(
    name: :g4,
    capacity: 64,
    apply_fn: fn b ->
      wait = fn wait ->
        if :atomics.get(gate, 1) == 0 do
          Process.sleep(1)
          wait.(wait)
        else
          :ok
        end
      end

      wait.(wait)
      send(test, {:g4, length(b)})
      :ok
    end
  )

verdicts = Enum.map(1..200, fn i -> Ring.publish(:g4, i) end)
oks = Enum.count(verdicts, &(&1 == :ok))
drops = Enum.count(verdicts, &(&1 == :dropped))
:atomics.put(gate, 1, 1)
:ok = G.await(fn -> Ring.stats(:g4).applied == 64 end)
post = Ring.publish(:g4, 201)
:ok = G.await(fn -> Ring.stats(:g4).applied == 65 end)
st4 = Ring.stats(:g4)
:ok = Ring.stop(:g4)

g4 =
  G.line(
    "G4 full",
    oks == 64 and drops == 136 and st4.dropped == 136 and post == :ok and
      st4.applied == 65 and st4.occupancy == 0,
    "the bound held its shape: 64 accepted, 136 refused with :dropped and counted -- never blocked, never overwritten -- then the release drained all 64 and publish 201 landed and applied: a storm bends the lane's at-most-once contract no further than the contract already bends"
  )

# G5 -- the storm over the real wire, with the owner decoupled
IO.puts("derive (storm): 500 invalidations published on the wire ride push frames at the committed 72 us median into the owner, which only parses and publishes -- application happens on the ring's applier, so a fetch fired mid-storm answers without queueing behind 500 applies; expect the storm applied within two seconds and the mid-storm fill well under 50 ms")
{:ok, _} =
  Table.start_link(
    name: :qs,
    table: "storm",
    kind: "AST",
    ttl_ms: 60_000,
    coherence: :broadcast,
    ring_capacity: 4_096,
    loader: loader,
    connector: [port: 6390]
  )

Process.sleep(150)
names = for _ <- 1..500, do: BrandedId.generate!("AST")
v_old = BrandedId.generate!("TXN")
Enum.each(names, fn id -> :ok = Table.put(:qs, id, "px=100.00", v_old) end)

hero = hd(names)
v_hero = BrandedId.generate!("TXN")
:ok = Table.put(:qs, hero, "px=109.00", v_hero)

storm_versions = for _ <- names, do: BrandedId.generate!("TXN")
before5 = Table.stats(:qs)
t5 = System.monotonic_time(:microsecond)

storm =
  Task.async(fn ->
    Enum.zip(names, storm_versions)
    |> Enum.each(fn {id, v} -> {:ok, _} = Coherence.broadcast(probe, "storm", id, v) end)
  end)

Process.sleep(5)
extra = BrandedId.generate!("AST")
{fetch_us, {:ok, _, :fill}} = :timer.tc(fn -> Table.fetch(:qs, extra, 30_000) end)
Task.await(storm, 10_000)
:ok = G.await(fn -> Table.stats(:qs).coh_applied - before5.coh_applied == 500 end)
storm_ms = div(System.monotonic_time(:microsecond) - t5, 1000)
gone = Enum.all?(names, fn id -> :ets.lookup(:qs, id) == [] end)
{:ok, hero_val, :l2} = Table.fetch(:qs, hero)
ring5 = Ring.stats({:coh, :qs})

g5 =
  G.line(
    "G5 storm",
    gone and hero_val == "px=109.00" and storm_ms < 2_000 and
      div(fetch_us, 1000) < 50 and ring5.dropped == 0 and
      Table.stats(:qs).coh_applied - before5.coh_applied == 500,
    "500 invalidations crossed the wire and the ring in #{storm_ms} ms with nothing dropped; every stormed row left L1, the one name whose writer placed a new value answers px=109.00 from the shared L2, and a fill fired mid-storm completed in #{div(fetch_us, 1000)} ms -- the owner parses and publishes while the applier applies, and neither waits for the other"
  )

:ok = Table.stop(:qs)

# G6 -- adversarial orderings converge, and the counters are invariant
IO.puts("derive (convergence): for each of 200 names holding version v2, a shuffled stream delivers either v1,v3,v1 or v1,v1 -- whatever the arrival order, a row is dropped if and only if a version newer than v2 appeared, and the per-name verdict counts are invariant under permutation: exactly 100 applied and 400 stale")
{:ok, _} =
  Table.start_link(
    name: :qz,
    table: "conv",
    kind: "AST",
    ttl_ms: 60_000,
    coherence: :broadcast,
    ring_capacity: 4_096,
    loader: loader,
    connector: [port: 6390]
  )

Process.sleep(150)

cohort =
  for i <- 1..200 do
    v1 = BrandedId.generate!("TXN")
    v2 = BrandedId.generate!("TXN")
    v3 = BrandedId.generate!("TXN")
    id = BrandedId.generate!("AST")
    :ok = Table.put(:qz, id, "held", v2)
    {i, id, v1, v3}
  end

messages =
  cohort
  |> Enum.flat_map(fn {i, id, v1, v3} ->
    if i <= 100, do: [{id, v1}, {id, v3}, {id, v1}], else: [{id, v1}, {id, v1}]
  end)
  |> Enum.shuffle()

before6 = Table.stats(:qz)
Enum.each(messages, fn {id, v} -> {:ok, _} = Coherence.broadcast(probe, "conv", id, v) end)

:ok =
  G.await(fn ->
    s = Table.stats(:qz)
    s.coh_applied + s.coh_stale - before6.coh_applied - before6.coh_stale == 500
  end)

after6 = Table.stats(:qz)
stormed_gone = cohort |> Enum.filter(fn {i, _, _, _} -> i <= 100 end) |> Enum.all?(fn {_, id, _, _} -> :ets.lookup(:qz, id) == [] end)
quiet_held = cohort |> Enum.filter(fn {i, _, _, _} -> i > 100 end) |> Enum.all?(fn {_, id, _, _} -> match?({:ok, "held", :hit}, Table.fetch(:qz, id)) end)

g6 =
  G.line(
    "G6 convergence",
    stormed_gone and quiet_held and
      after6.coh_applied - before6.coh_applied == 100 and
      after6.coh_stale - before6.coh_stale == 400,
    "500 shuffled messages converged: the 100 names that saw a newer version lost their rows, the 100 that saw only older versions still answer :hit, and the verdict counters landed exactly on 100 applied and 400 stale -- arrival order changed nothing, because every application is the same comparison"
  )

:ok = Table.stop(:qz)

# cleanup -- fixtures owned
{:ok, keys} = Connector.command(probe, ["KEYS", "ecc:*"])
if keys != [], do: {:ok, _} = Connector.command(probe, ["DEL" | keys])

if Enum.all?([g1, g2, g3, g4, g5, g6]) and EchoCache.tables() == [] do
  IO.puts("PASS 6/6")
else
  IO.puts("FAIL")
  System.halt(1)
end
