# bcs_rung_4_2_check.exs -- gates F1..F6: coherence by mint time.
#   cd /Users/jonny/dev/jonnify/echo && mix run --no-start rungs/cache/bcs_rung_4_2_check.exs   (Valkey live on 6390)
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
alias EchoCache.{Coherence, Table}
alias EchoData.BrandedId
alias EchoMQ.{Connector, Consumer}

defmodule F do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end

  def median(list), do: list |> Enum.sort() |> Enum.at(div(length(list), 2))
end

{:ok, probe} = Connector.start_link(port: 6390)
test = self()

loader = fn _ -> {:ok, "px=100.00"} end

{:ok, _} =
  Table.start_link(
    name: :qa,
    table: "quotes",
    kind: "AST",
    ttl_ms: 60_000,
    coherence: :broadcast,
    loader: loader,
    connector: [port: 6390]
  )

{:ok, _} =
  Table.start_link(
    name: :qb,
    table: "quotes",
    kind: "AST",
    ttl_ms: 60_000,
    coherence: :broadcast,
    loader: loader,
    connector: [port: 6390]
  )

{:ok, _} =
  Table.start_link(
    name: :qc,
    table: "quotes",
    kind: "AST",
    ttl_ms: 60_000,
    coherence: :job,
    loader: loader,
    connector: [port: 6390]
  )

Process.sleep(150)

# F1 -- the surface and the message
{:ok, qa_spec} = EchoCache.spec(:qa)
{:ok, qc_spec} = EchoCache.spec(:qc)
pay = Coherence.payload("AST0KHTOWnGLuC", "TXN0NgWEfAEJfs")
{:ok, p2} = Connector.start_link(port: 6390, protocol: 2)

f1 =
  F.line(
    "F1 surface",
    Enum.all?(
      [channel: 1, queue: 1, payload: 2, parse: 1, newer?: 2, drop_l2: 4, broadcast: 4, enqueue: 5],
      &(&1 in EchoCache.Coherence.__info__(:functions))
    ) and
      {:apply_coherence, 4} in EchoCache.Table.__info__(:functions) and
      {:coherence_handler, 1} in EchoCache.Table.__info__(:functions) and
      qa_spec.coherence == :broadcast and qc_spec.coherence == :job and
      byte_size(pay) == 29 and Coherence.parse(pay) == {:ok, "AST0KHTOWnGLuC", "TXN0NgWEfAEJfs"} and
      Coherence.parse("garbage") == :error and
      Connector.push_command(p2, ["SUBSCRIBE", "x"]) == {:error, :requires_resp3},
    "the vocabulary is whole: channel, queue, a twenty-nine-byte payload of two names, parse refusing garbage; tables declare their lane in the directory; and the connector's push path refuses a protocol 2 connection with a typed :requires_resp3"
  )

# F2 -- newer-wins has teeth: the late stale message cannot erase a newer row
v_old = BrandedId.generate!("TXN")
Process.sleep(2)
v_new = BrandedId.generate!("TXN")
ast = BrandedId.generate!("AST")
:ok = Table.put(:qa, ast, "px=105.00", v_new)
{:ok, stale_verdict} = Table.apply_coherence(:qa, ast, v_old)
{:ok, survived, :hit} = Table.fetch(:qa, ast)
{:ok, l2_drop_stale} = Coherence.drop_l2(probe, "quotes", ast, v_old)
{:ok, <<^v_new::binary-14, _::binary>>} = Connector.command(probe, ["GET", EchoCache.Keyspace.key("quotes", ast)])
{:ok, applied_verdict} = Table.apply_coherence(:qa, ast, BrandedId.generate!("TXN"))
{:ok, replay_verdict} = Table.apply_coherence(:qa, ast, v_old)

f2 =
  F.line(
    "F2 newer-wins",
    stale_verdict == :stale and survived == "px=105.00" and l2_drop_stale == 0 and
      applied_verdict == :applied and replay_verdict == :stale and
      Coherence.newer?(v_new, v_old) and not Coherence.newer?(v_old, v_new),
    "a late stale invalidation bounced off both layers -- the L1 row survived holding px=105.00 and the L2 drop script answered 0 -- while a genuinely newer version applied and the replay of the old one stayed stale: idempotence is a comparison, not a log"
  )

# F3 -- the broadcast lane, measured
IO.puts("derive (broadcast): the lane is one PUBLISH hop on the wire whose committed sequential floor is 29,456 round trips per second, near 34 us each -- expect a median push latency between 30 and 500 us, and the receiver's apply is one ETS comparison on top")
{:ok, sub} = Connector.start_link(port: 6390, protocol: 3, push_to: test, heartbeat_ms: 0)
:ok = Connector.subscribe(sub, Coherence.channel("quotes"))

receive do
  {:emq_push, ["subscribe" | _]} -> :ok
after
  2_000 -> :no_confirm
end

lat_us =
  for i <- 1..100 do
    t0 = System.monotonic_time(:microsecond)
    {:ok, _} = Coherence.broadcast(probe, "quotes", ast, BrandedId.generate!("TXN"))

    receive do
      {:emq_push, ["message", _, _]} -> System.monotonic_time(:microsecond) - t0
    after
      2_000 -> 2_000_000 + i
    end
  end

push_med = F.median(lat_us)

# end-to-end across nodes: writer puts on qa, broadcasts; qb drops and refills from L2
ast2 = BrandedId.generate!("AST")
{:ok, _, :fill} = Table.fetch(:qa, ast2)
{:ok, "px=100.00", :l2} = Table.fetch(:qb, ast2)
v2 = BrandedId.generate!("TXN")
:ok = Table.put(:qa, ast2, "px=106.00", v2)
{:ok, receivers} = Coherence.broadcast(probe, "quotes", ast2, v2)
Process.sleep(100)
{:ok, fresh, fresh_src} = Table.fetch(:qb, ast2)

f3 =
  F.line(
    "F3 broadcast",
    push_med >= 30 and push_med <= 500 and receivers >= 3 and
      fresh == "px=106.00" and fresh_src == :l2,
    "median push latency #{push_med} us over 100 messages, inside the derived band; the cross-node round trip holds -- the writer put px=106.00, #{receivers} subscribers heard the name, and the other node's next read fell through its dropped L1 to the shared L2 and answered fresh"
  )

# F4 -- fire-and-forget priced: the lane a surface did not ride
ast3 = BrandedId.generate!("AST")
{:ok, _, :fill} = Table.fetch(:qc, ast3)
v3 = BrandedId.generate!("TXN")
:ok = Table.put(:qa, ast3, "px=107.00", v3)
{:ok, _} = Coherence.broadcast(probe, "quotes", ast3, v3)
Process.sleep(100)
{:ok, still_old, :hit} = Table.fetch(:qc, ast3)

f4 =
  F.line(
    "F4 loss",
    still_old == "px=100.00",
    "the price of fire-and-forget, stated as a gate: :qc declared the job lane and holds no subscription, so the broadcast passed it by and it still serves px=100.00 -- bounded staleness until its own lane delivers, which is the next gate's business"
  )

# F5 -- the job lane: at-least-once through a crash, idempotent on redelivery
IO.puts("derive (job lane): a consumer crash after claim strands the coherence job on a lease; the reaper returns it, a second consumer applies it with token 2, and reapplication is harmless because newer-wins is a comparison -- expect attempts 2 and exactly one effective drop")
grp = BrandedId.generate!("PRT")
{:ok, :enqueued} = Coherence.enqueue(probe, "quotes", grp, ast3, v3)

{:ok, victim} =
  Consumer.start_link(
    queue: Coherence.queue("quotes"),
    connector: [port: 6390],
    beat_ms: 100,
    lease_ms: 250,
    handler: fn job ->
      send(test, {:claimed, job.id})
      Process.sleep(:infinity)
    end
  )

claimed_id =
  receive do
    {:claimed, jid} -> jid
  after
    5_000 -> :timeout
  end

Process.exit(victim, :kill)

receive do
  {:EXIT, ^victim, :killed} -> :ok
after
  1_000 -> :no_exit_signal
end

Process.sleep(400)

{:ok, healer} =
  Consumer.start_link(
    queue: Coherence.queue("quotes"),
    connector: [port: 6390],
    beat_ms: 100,
    lease_ms: 5_000,
    handler: Table.coherence_handler(:qc)
  )

healed =
  Enum.reduce_while(1..100, :stale, fn _, _ ->
    case Table.fetch(:qc, ast3) do
      {:ok, "px=107.00", _} -> {:halt, :fresh}
      _ -> Process.sleep(20) && {:cont, :stale}
    end
  end)

{:ok, job_exists} =
  Connector.command(probe, ["EXISTS", EchoMQ.Keyspace.job_key(Coherence.queue("quotes"), claimed_id)])

{:ok, replay_after_heal} = Table.apply_coherence(:qc, ast3, v3)
:ok = Consumer.stop(healer)

f5 =
  F.line(
    "F5 job lane",
    healed == :fresh and job_exists == 0 and replay_after_heal == :stale and is_binary(claimed_id),
    "the lane that survives: the first consumer died holding the job, the reaper returned it, the healer applied it -- :qc dropped its stale row and now serves px=107.00 from the shared L2 -- the completed job left no row to browse, and replaying the same version answers stale: at-least-once delivery, exactly-once effect"
  )

# F6 -- the two lanes priced side by side
IO.puts("derive (price): the broadcast lane is one wire hop; the job lane pays three to five hops -- enqueue, wake, claim, complete -- so a parked consumer should land its median between 80 us and 2 ms, the same order as the bus's committed 0.3 ms end-to-end median, carrying the guarantee the push cannot")
{:ok, pricer} =
  Consumer.start_link(
    queue: Coherence.queue("quotes"),
    connector: [port: 6390],
    beat_ms: 5_000,
    handler: fn job ->
      {:ok, _id, _v} = Coherence.parse(job.payload)
      send(test, {:applied, System.monotonic_time(:microsecond)})
      :ok
    end
  )

Process.sleep(200)

job_us =
  for _ <- 1..50 do
    t0 = System.monotonic_time(:microsecond)
    {:ok, :enqueued} = Coherence.enqueue(probe, "quotes", grp, ast3, BrandedId.generate!("TXN"))

    receive do
      {:applied, t1} -> t1 - t0
    after
      3_000 -> 3_000_000
    end
  end

job_med = F.median(job_us)
:ok = Consumer.stop(pricer)

f6 =
  F.line(
    "F6 price",
    job_med >= 80 and job_med <= 2_000 and push_med < job_med,
    "the two lanes on one row: broadcast median #{push_med} us fire-and-forget, job lane median #{div(job_med, 1)} us at-least-once -- the guarantee costs #{Float.round(job_med / max(push_med, 1), 1)} times the latency, and gates F4 and F5 are the reason a surface pays it"
  )

# cleanup -- fixtures owned on both machines
{:ok, keys} = Connector.command(probe, ["KEYS", "ecc:*"])
if keys != [], do: {:ok, _} = Connector.command(probe, ["DEL" | keys])
{:ok, qkeys} = Connector.command(probe, ["KEYS", "emq:{ecc.coh.quotes}:*"])
if qkeys != [], do: {:ok, _} = Connector.command(probe, ["DEL" | qkeys])
for t <- [:qa, :qb, :qc], do: :ok = Table.stop(t)

if Enum.all?([f1, f2, f3, f4, f5, f6]) and EchoCache.tables() == [] do
  IO.puts("PASS 6/6")
else
  IO.puts("FAIL")
  System.halt(1)
end
