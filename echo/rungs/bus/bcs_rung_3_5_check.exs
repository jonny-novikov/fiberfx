# bcs_rung_3_5_check.exs -- gates B1..B6: the bus meets the stores.
for f <- ~w(base62 native snowflake branded_id) do
  Code.require_file(Path.expand("../../apps/echo_data/lib/echo_data/#{f}.ex", __DIR__))
end

(fn -> p = Path.expand("../../apps/echo_data/lib/echo_data/bcs.ex", __DIR__)
  mod = p |> Path.basename(".ex")
  _ = mod
  Code.require_file(p) end).()
(fn -> p = Path.expand("../../apps/echo_data/lib/echo_data/bcs/property_store.ex", __DIR__)
  mod = p |> Path.basename(".ex")
  _ = mod
  Code.require_file(p) end).()

for f <- ~w(resp script keyspace connector jobs lanes consumer) do
  Code.require_file(Enum.find([Path.expand("../../apps/echo_wire/lib/echo_mq/#{f}.ex", __DIR__), Path.expand("../../apps/echo_mq/lib/echo_mq/#{f}.ex", __DIR__)], &File.exists?/1))
end

:ok = EchoData.Snowflake.start(7)
alias EchoData.BrandedId
alias EchoData.Bcs.PropertyStore
alias EchoMQ.{Connector, Consumer, Keyspace, Lanes}

defmodule B do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end

  def stop_and_reason(pid) do
    ref = Process.monitor(pid)
    Process.unlink(pid)
    res = EchoMQ.Consumer.stop(pid)

    reason =
      receive do
        {:DOWN, ^ref, :process, ^pid, r} -> r
      after
        2_000 -> :timeout
      end

    {res, reason}
  end
end

{:ok, c} = Connector.start_link(port: 6390)
test = self()
q = "bus35"

purge = fn queue, ids, groups ->
  base =
    ~w(pending active schedule dead ring wake paused glimit gactive)
    |> Enum.map(&Keyspace.queue_key(queue, &1))

  lanes = Enum.map(groups, &Keyspace.queue_key(queue, "g:" <> &1 <> ":pending"))
  jobs = Enum.map(ids, &Keyspace.job_key(queue, &1))

  (base ++ lanes ++ jobs)
  |> Enum.chunk_every(200)
  |> Enum.each(fn chunk -> {:ok, _} = Connector.pipeline(c, [["DEL" | chunk]]) end)
end

# B1 -- the surface grew by exactly the stop verb
b1 =
  B.line(
    "B1 surface",
    Enum.sort(EchoMQ.Consumer.__info__(:functions)) ==
      [child_spec: 1, start_link: 1, stop: 1, stop: 2],
    "the consumer grows one verb: stop -- drain and stop, with child_spec and start_link as Chapter 3.4 shipped them; the stores' modules are untouched by this chapter"
  )

# test scaffolding: flags the rung sets per job, consumed once by the handler
:ets.new(:crash35, [:set, :public, :named_table])
:ets.new(:block35, [:set, :public, :named_table])
:ets.new(:slow35, [:set, :public, :named_table])

# the integration recipe: every row guards itself by the names it has absorbed
handler = fn %{id: job, payload: pay, attempts: att} ->
  if :ets.take(:block35, job) != [] do
    send(test, {:started, job})
    Process.sleep(10_000)
  end

  %{order: ord, portfolio: prt, qty: qty, px: px} = :erlang.binary_to_term(pay)

  if :ets.take(:slow35, job) != [] do
    send(test, {:started, job})
    Process.sleep(200)
  end

  fills =
    case PropertyStore.get(:positions35, prt) do
      {:ok, %{fills: f}} -> f
      _ -> %{}
    end

  unless Map.has_key?(fills, job) do
    f2 = Map.put(fills, job, qty)
    :ok = PropertyStore.put(:positions35, prt, %{fills: f2, qty: f2 |> Map.values() |> Enum.sum()})
  end

  if :ets.take(:crash35, job) != [], do: raise("torn between writes")

  case PropertyStore.get(:orders35, ord) do
    {:ok, %{provenance: ^job}} ->
      :ok

    _ ->
      :ok = PropertyStore.put(:orders35, ord, %{state: :filled, qty: qty, px: px, provenance: job})
  end

  send(test, {:filled, job, att})
  :ok
end

# the consumer's lane, rung-owned: it outlives the loop across restarts
{:ok, c4} = Connector.start_link(port: 6390)

# the tree: two stores and the consumer, three owners under one_for_one
{:ok, sup} =
  Supervisor.start_link(
    [
      Supervisor.child_spec({PropertyStore, [name: :orders35, namespace: "ORD"]}, id: :orders35),
      Supervisor.child_spec({PropertyStore, [name: :positions35, namespace: "PRT"]}, id: :positions35),
      Consumer.child_spec(
        id: :consumer35,
        queue: q,
        conn: c4,
        handler: handler,
        beat_ms: 150,
        lease_ms: 250,
        retry_delay_ms: 250,
        max_attempts: 3
      )
    ],
    strategy: :one_for_one
  )

child = fn id -> Supervisor.which_children(sup) |> Enum.find(&(elem(&1, 0) == id)) |> elem(1) end

prt = BrandedId.generate!("PRT")
mkfill = fn ord, qty, px -> :erlang.term_to_binary(%{order: ord, portfolio: prt, qty: qty, px: px}) end

# B2 -- the round trip: ids out, property writes back, through the tree
ord1 = BrandedId.generate!("ORD")
j1 = BrandedId.generate!("JOB")
decoded = :erlang.binary_to_term(mkfill.(ord1, 7, 105))

cargo_ok =
  Map.keys(decoded) |> Enum.sort() == [:order, :portfolio, :px, :qty] and
    BrandedId.valid?(decoded.order) and BrandedId.valid?(decoded.portfolio)

{:ok, :enqueued} = Lanes.enqueue(c, q, prt, j1, mkfill.(ord1, 7, 105))

f1 =
  receive do
    {:filled, ^j1, att} -> att
  after
    3_000 -> :timeout
  end

{:ok, ord1_row} = PropertyStore.get(:orders35, ord1)
{:ok, prt_row} = PropertyStore.get(:positions35, prt)
{:ok, gone1} = Connector.command(c, ["EXISTS", Keyspace.job_key(q, j1)])

b2 =
  B.line(
    "B2 round trip",
    cargo_ok and f1 == 1 and gone1 == 0 and
      ord1_row == %{state: :filled, qty: 7, px: 105, provenance: j1} and
      prt_row == %{fills: %{j1 => 7}, qty: 7} and BrandedId.valid?(ord1_row.provenance),
    "a fill leaves as two names and two numbers and lands as two property writes through the tree -- the ORD row filled qty 7 at 105, the PRT position absorbing the job's name as its receipt, the row on the bus gone"
  )

# B3 -- the torn effect heals: a crash between the two writes
ord2 = BrandedId.generate!("ORD")
j2 = BrandedId.generate!("JOB")
:ets.insert(:crash35, {j2, true})
pid_before_crash = child.(:consumer35)
{:ok, :enqueued} = Lanes.enqueue(c, q, prt, j2, mkfill.(ord2, 5, 99))

last_error =
  Enum.reduce_while(1..200, nil, fn _, _ ->
    case Connector.command(c, ["HGET", Keyspace.job_key(q, j2), "last_error"]) do
      {:ok, nil} ->
        Process.sleep(5)
        {:cont, nil}

      {:ok, msg} ->
        {:halt, msg}
    end
  end)

f2 =
  receive do
    {:filled, ^j2, att} -> att
  after
    3_000 -> :timeout
  end

pid_after_crash = child.(:consumer35)
{:ok, prt_row2} = PropertyStore.get(:positions35, prt)
{:ok, ord2_row} = PropertyStore.get(:orders35, ord2)

b3 =
  B.line(
    "B3 torn",
    last_error == "torn between writes" and f2 == 2 and
      pid_after_crash == pid_before_crash and
      prt_row2.qty == 12 and map_size(prt_row2.fills) == 2 and
      ord2_row == %{state: :filled, qty: 5, px: 99, provenance: j2},
    "a handler torn between two writes is one job's failure, not the loop's: the crash converts to a typed retry (last_error: torn between writes), the same pid serves attempt 2, the position declines the name it already absorbed -- qty 12 once, never 17 -- and the order completes"
  )

# B4 -- the owner drill: dead mid-fill, the tree restores it alone
ord3 = BrandedId.generate!("ORD")
j3 = BrandedId.generate!("JOB")
:ets.insert(:block35, {j3, true})
store_pids = {child.(:orders35), child.(:positions35)}
{:ok, :enqueued} = Lanes.enqueue(c, q, prt, j3, mkfill.(ord3, 3, 101))

receive do
  {:started, ^j3} -> :ok
after
  3_000 -> :timeout
end

doomed = child.(:consumer35)
Process.exit(doomed, :kill)

f3 =
  receive do
    {:filled, ^j3, att} -> att
  after
    3_000 -> :timeout
  end

reborn = child.(:consumer35)
{:ok, prt_row3} = PropertyStore.get(:positions35, prt)
{:ok, ord1_still} = PropertyStore.get(:orders35, ord1)

b4 =
  B.line(
    "B4 owner",
    f3 == 2 and reborn != doomed and store_pids == {child.(:orders35), child.(:positions35)} and
      prt_row3.qty == 15 and ord1_still.provenance == j1,
    "the consumer is one more owner: stopped dead mid-fill, the one_for_one tree restores it alone -- the stores never blink and their rows survive -- the orphaned lease reaps on the new pid's beat and qty lands 15 exactly once with token 2"
  )

# two more clean fills for the audit page
{ord4, ord5} = {BrandedId.generate!("ORD"), BrandedId.generate!("ORD")}
{j4, j5} = {BrandedId.generate!("JOB"), BrandedId.generate!("JOB")}
{:ok, :enqueued} = Lanes.enqueue(c, q, prt, j4, mkfill.(ord4, 2, 100))

receive do
  {:filled, ^j4, 1} -> :ok
after
  3_000 -> :timeout
end

{:ok, :enqueued} = Lanes.enqueue(c, q, prt, j5, mkfill.(ord5, 1, 103))

receive do
  {:filled, ^j5, 1} -> :ok
after
  3_000 -> :timeout
end

# B5 -- the audit dividend: the store is the trail
{:ok, page} = PropertyStore.page_desc(:orders35, 5)
{:ok, prt_row5} = PropertyStore.get(:positions35, prt)

provenance_ok =
  Enum.all?(page, fn ord ->
    {:ok, row} = PropertyStore.get(:orders35, ord)
    BrandedId.valid?(row.provenance) and BrandedId.namespace(row.provenance) == "JOB"
  end)

b5 =
  B.line(
    "B5 audit",
    page == [ord5, ord4, ord3, ord2, ord1] and provenance_ok and
      prt_row5.qty == 18 and map_size(prt_row5.fills) == 5,
    "the audit trail is the store itself: five fills page newest-first by name alone, every row carrying the JOB that wrote it, the position remembering all five names for qty 18"
  )

# B6 -- stop is a drain on both paths
ord6 = BrandedId.generate!("ORD")
{j6, j7} = {BrandedId.generate!("JOB"), BrandedId.generate!("JOB")}
:ets.insert(:slow35, {j6, true})
{:ok, :enqueued} = Lanes.enqueue(c, q, prt, j6, mkfill.(ord6, 4, 102))

receive do
  {:started, ^j6} -> :ok
after
  3_000 -> :timeout
end

{:ok, :enqueued} = Lanes.enqueue(c, q, prt, j7, mkfill.(BrandedId.generate!("ORD"), 9, 100))
:ok = Supervisor.terminate_child(sup, :consumer35)

drained =
  receive do
    {:filled, ^j6, 1} -> true
  after
    0 -> false
  end

{:ok, depth_left} = Lanes.depth(c, q, prt)
{:ok, j7_att} = Connector.command(c, ["HGET", Keyspace.job_key(q, j7), "attempts"])

{:ok, bare} = Consumer.start_link(queue: "bare35", connector: [port: 6390], handler: fn _ -> :ok end, beat_ms: 150)
Process.sleep(100)
{bare_stop, bare_down} = B.stop_and_reason(bare)

b6 =
  B.line(
    "B6 stop",
    drained and depth_left == 1 and j7_att == "0" and bare_stop == :ok and bare_down == :normal,
    "stop is a drain on both paths: the supervisor's terminate_child settles the fill in hand and never claims the next -- depth 1 remains with attempts 0 -- and a bare loop answers stop with a normal exit"
  )

# cleanup
Supervisor.stop(sup)
purge.(q, [j1, j2, j3, j4, j5, j6, j7], [prt])
purge.("bare35", [], [])

if Enum.all?([b1, b2, b3, b4, b5, b6]) do
  IO.puts("PASS 6/6")
else
  IO.puts("FAIL")
  System.halt(1)
end
