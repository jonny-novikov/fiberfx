# bcs_rung_4_4_check.exs -- gates H1..H6: the lane that remembers.
#   cd src/echo && MIX_ENV=prod mix run rungs/<group>/4_4_check.exs   (Valkey live on 6390)
alias EchoCache.{Coherence, Journal, Table}
alias EchoData.BrandedId
alias EchoMQ.{Connector, Consumer, Lanes}

case EchoData.Snowflake.start(9) do
  :ok -> :ok
  {:error, :already_started} -> :ok
end

Process.flag(:trap_exit, true)

defmodule H do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end

  def median(list), do: list |> Enum.sort() |> Enum.at(div(length(list), 2))

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

sqlite_v =
  (fn ->
     {:ok, db} = Exqlite.Sqlite3.open(":memory:")
     {:ok, st} = Exqlite.Sqlite3.prepare(db, "select sqlite_version()")
     {:row, [v]} = Exqlite.Sqlite3.step(db, st)
     Exqlite.Sqlite3.close(db)
     v
   end).()

IO.puts(
  "header: Valkey #{vv} on 6390 | SQLite #{sqlite_v} via exqlite, WAL, synchronous=NORMAL | Elixir #{System.version()} OTP #{:erlang.system_info(:otp_release)} | schedulers #{System.schedulers_online()}"
)

dir = Path.join(System.tmp_dir!(), "bcs44")
File.rm_rf!(dir)
loader = fn _ -> {:ok, "px=100.00"} end

sweep_queue = fn table_str ->
  {:ok, ks} = Connector.command(probe, ["KEYS", "emq:{" <> Coherence.queue(table_str) <> "}:*"])
  if ks != [], do: {:ok, _} = Connector.command(probe, ["DEL" | ks])
end

# H1 -- per-group files, schema, the kind law at the journal's door
g_a = BrandedId.generate!("PRT")
g_b = BrandedId.generate!("PRT")
{:ok, _} = Journal.start_link(name: :ja, group: g_a, table: "t1", dir: dir)
{:ok, _} = Journal.start_link(name: :jb, group: g_b, table: "t1", dir: dir)

files = dir |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".db")) |> Enum.sort()

bad_group =
  case Journal.start_link(name: :jx, group: "not-a-branded-id", table: "t1", dir: dir) do
    {:error, _} ->
      receive do
        {:EXIT, _, _} -> :ok
      after
        500 -> :ok
      end

      :refused

    _ ->
      :accepted
  end

schema =
  (fn ->
     {:ok, db} = Exqlite.Sqlite3.open(Path.join(dir, "journal-" <> g_a <> ".db"))
     {:ok, st} = Exqlite.Sqlite3.prepare(db, "select name from sqlite_master where type='table' order by name")

     names =
       Stream.repeatedly(fn -> Exqlite.Sqlite3.step(db, st) end)
       |> Enum.take_while(&match?({:row, _}, &1))
       |> Enum.map(fn {:row, [n]} -> n end)

     Exqlite.Sqlite3.close(db)
     names
   end).()

h1 =
  H.line(
    "H1 files",
    files == Enum.sort(["journal-" <> g_a <> ".db", "journal-" <> g_b <> ".db"]) and
      bad_group == :refused and Enum.all?(["intents", "applied"], &(&1 in schema)) and
      Journal.stats(:ja).intents == 0,
    "one journal file per group, named by the group's branded id -- two groups, two files on disk -- a non-branded group is refused at the door, and the schema carries the two memories: intents (the outbox) and applied (the lane's last word per name)"
  )

:ok = Journal.stop(:jb)

# H2 -- the outbox windows: every crash between record and mark is covered
IO.puts("derive (windows): the writer's flow is record, enqueue, mark -- two crash seams; a death before the enqueue leaves a pending intent that replay enqueues; a death after the enqueue but before the mark leaves the bus holding the job, and replay's reuse of the recorded job id lets the bus's own admission dedup absorb it; full coverage by the applied memory makes replay a no-op")
{:ok, _} = Table.start_link(name: :t1, table: "t1", kind: "AST", ttl_ms: 60_000, coherence: :job, loader: loader, connector: [port: 6390])

n1 = BrandedId.generate!("AST")
v1 = BrandedId.generate!("TXN")
jid1 = BrandedId.generate!("JOB")
{:ok, _} = Journal.record(:ja, jid1, n1, v1)
pend_a = Journal.stats(:ja).pending_enqueue

n2 = BrandedId.generate!("AST")
v2 = BrandedId.generate!("TXN")
jid2 = BrandedId.generate!("JOB")
{:ok, _} = Journal.record(:ja, jid2, n2, v2)
{:ok, :enqueued} = Lanes.enqueue(probe, Coherence.queue("t1"), g_a, jid2, Coherence.payload(n2, v2))

{:ok, rep1} = Journal.replay(:ja, probe)

{:ok, cons1} =
  Consumer.start_link(queue: Coherence.queue("t1"), connector: [port: 6390], handler: Journal.handler(:ja, :t1))

:ok = H.await(fn -> Journal.stats(:ja).remembered == 2 end)

n3 = BrandedId.generate!("AST")
v3 = BrandedId.generate!("TXN")
{:ok, _jid3} = Journal.intend_and_enqueue(:ja, probe, n3, v3)
:ok = H.await(fn -> Journal.stats(:ja).remembered == 3 end)
{:ok, rep2} = Journal.replay(:ja, probe)

h2 =
  H.line(
    "H2 windows",
    pend_a == 1 and rep1 == %{replayed: 1, deduplicated: 1} and
      Journal.last_applied(:ja, n1) == v1 and Journal.last_applied(:ja, n2) == v2 and
      rep2 == %{replayed: 0, deduplicated: 0},
    "both crash seams closed by machinery that already exists: the never-enqueued intent replayed onto the bus, the enqueued-but-unmarked one answered :duplicate at admission and was counted, both ended in the applied memory -- and once coverage is total, replay is exactly %{replayed: 0, deduplicated: 0}"
  )

:ok = Consumer.stop(cons1)

# H3 -- the title's gate: the journal remembers what the cache forgot
IO.puts("derive (memory): the applied table lives in the file, so it survives the table, the node, and the bus; after a full restart with an empty L1, a replayed old version must answer :remembered_stale from the journal alone -- no cache row consulted, none created -- while a genuinely newer version passes through and updates the memory")
hero = BrandedId.generate!("AST")
v_old = BrandedId.generate!("TXN")
v5 = BrandedId.generate!("TXN")
{:ok, _} = Journal.intend_and_enqueue(:ja, probe, hero, v5)

{:ok, cons2} =
  Consumer.start_link(queue: Coherence.queue("t1"), connector: [port: 6390], handler: Journal.handler(:ja, :t1))

:ok = H.await(fn -> Journal.last_applied(:ja, hero) == v5 end)
:ok = Consumer.stop(cons2)

:ok = Table.stop(:t1)
:ok = Journal.stop(:ja)

{:ok, _} = Journal.start_link(name: :ja2, group: g_a, table: "t1", dir: dir)
{:ok, _} = Table.start_link(name: :t1, table: "t1", kind: "AST", ttl_ms: 60_000, coherence: :job, loader: loader, connector: [port: 6390])

survived = Journal.last_applied(:ja2, hero)
before_stats = Table.stats(:t1)
{:ok, verdict_old} = Journal.apply_and_remember(:ja2, :t1, hero, v_old)
after_stats = Table.stats(:t1)
v6 = BrandedId.generate!("TXN")
{:ok, _} = Journal.apply_and_remember(:ja2, :t1, hero, v6)

h3 =
  H.line(
    "H3 memory",
    survived == v5 and verdict_old == :remembered_stale and
      after_stats.coh_applied == before_stats.coh_applied and
      after_stats.coh_stale == before_stats.coh_stale and
      :ets.lookup(:t1, hero) == [] and Journal.last_applied(:ja2, hero) == v6,
    "the journal remembered v5 across a full stop of table and journal; the replayed old version answered :remembered_stale without touching the cache -- the table's verdict counters did not move and no row appeared -- and the genuinely newer v6 passed through and became the new last word"
  )

:ok = Table.stop(:t1)
:ok = Journal.stop(:ja2)

# H4 -- the bus dies; the journal replays the lane back into existence
IO.puts("derive (loss): D-2 keeps the bus volatile, so a bus restart erases queued coherence jobs; 50 intents recorded and enqueued, 20 applied before the loss, the lane's queue keys flushed -- replay must re-enqueue exactly the 30 uncovered intents in seq order, and a consumer must drain them to a remembered count of 50")
g_c = BrandedId.generate!("PRT")
{:ok, _} = Journal.start_link(name: :jc, group: g_c, table: "t2", dir: dir)
{:ok, _} = Table.start_link(name: :t2, table: "t2", kind: "AST", ttl_ms: 60_000, coherence: :job, loader: loader, connector: [port: 6390])

cohort =
  for _ <- 1..50 do
    id = BrandedId.generate!("AST")
    v = BrandedId.generate!("TXN")
    {:ok, _} = Journal.intend_and_enqueue(:jc, probe, id, v)
    {id, v}
  end

Enum.take(cohort, 20)
|> Enum.each(fn {id, v} -> {:ok, _} = Journal.apply_and_remember(:jc, :t2, id, v) end)

sweep_queue.("t2")

{:ok, rep4} = Journal.replay(:jc, probe)

{:ok, cons4} =
  Consumer.start_link(queue: Coherence.queue("t2"), connector: [port: 6390], handler: Journal.handler(:jc, :t2))

:ok = H.await(fn -> Journal.stats(:jc).remembered == 50 end)

h4 =
  H.line(
    "H4 loss",
    rep4 == %{replayed: 30, deduplicated: 0} and Journal.stats(:jc).remembered == 50 and
      Enum.all?(cohort, fn {id, v} -> Journal.last_applied(:jc, id) == v end),
    "the bus restart erased the queue and the journal replayed the lane back: exactly 30 uncovered intents re-enqueued in seq order under their recorded job ids, the consumer drained them, and the applied memory closed at 50 of 50 names holding their final versions"
  )

:ok = Consumer.stop(cons4)

# H5 -- compaction is coverage, and memory outlives it
IO.puts("derive (compaction): an intent is retired when its name carries an applied version at least as new -- coverage, not acknowledgment -- so after H4 all 50 intents are deletable, the applied memory keeps all 50 names, replay finds nothing, and a reopen still remembers")
st_before = Journal.stats(:jc)
{:ok, retired} = Journal.compact(:jc)
st_after = Journal.stats(:jc)
{:ok, rep5} = Journal.replay(:jc, probe)
:ok = Journal.stop(:jc)
{:ok, _} = Journal.start_link(name: :jc2, group: g_c, table: "t2", dir: dir)
{hero4, vhero4} = hd(cohort)

h5 =
  H.line(
    "H5 compaction",
    st_before.intents == 50 and retired == 50 and st_after.intents == 0 and
      st_after.remembered == 50 and rep5 == %{replayed: 0, deduplicated: 0} and
      Journal.last_applied(:jc2, hero4) == vhero4,
    "all 50 intents retired by coverage in one pass, the applied memory kept its 50 names, replay over the compacted journal found nothing to do, and a fresh open of the same file still answers the last word -- the outbox empties, the memory does not"
  )

:ok = Journal.stop(:jc2)
:ok = Table.stop(:t2)

# H6 -- the price of remembering
IO.puts("derive (price): on prepared-once statements -- the single writer's privilege, with bind resetting the statement -- the writer's pair is two WAL commits and one cached rowid read at synchronous=NORMAL, so expect between 20 and 250 us on this disk; the remembered lane's end-to-end median should land between 200 us and 2 ms against the bare lane's committed 148 us: dearer, bounded, and the chapter's reason the journal is declared per group rather than assumed")
g_d = BrandedId.generate!("PRT")
{:ok, _} = Journal.start_link(name: :jd, group: g_d, table: "t3", dir: dir)
{:ok, _} = Table.start_link(name: :t3, table: "t3", kind: "AST", ttl_ms: 60_000, coherence: :job, loader: loader, connector: [port: 6390])

micro_id = BrandedId.generate!("AST")

{micro_us, :ok} =
  :timer.tc(fn ->
    Enum.each(1..1_000, fn _ ->
      jid = BrandedId.generate!("JOB")
      {:ok, _} = Journal.record(:jd, jid, micro_id, BrandedId.generate!("TXN"))
      :ok = Journal.mark_enqueued(:jd, jid)
    end)
  end)

micro_per = div(micro_us, 1_000)

test = self()

{:ok, cons6} =
  Consumer.start_link(
    queue: Coherence.queue("t3"),
    connector: [port: 6390],
    handler: fn job ->
      {:ok, id, v} = Coherence.parse(job.payload)
      {:ok, _} = Journal.apply_and_remember(:jd, :t3, id, v)
      send(test, {:done, System.monotonic_time(:microsecond)})
      :ok
    end
  )

Process.sleep(200)

e2e =
  for _ <- 1..50 do
    t0 = System.monotonic_time(:microsecond)
    {:ok, _} = Journal.intend_and_enqueue(:jd, probe, BrandedId.generate!("AST"), BrandedId.generate!("TXN"))

    receive do
      {:done, t1} -> t1 - t0
    after
      3_000 -> 3_000_000
    end
  end

e2e_med = H.median(e2e)
:ok = Consumer.stop(cons6)
:ok = Journal.stop(:jd)
:ok = Table.stop(:t3)

h6 =
  H.line(
    "H6 price",
    micro_per >= 20 and micro_per <= 250 and e2e_med >= 200 and e2e_med <= 2_000,
    "the memory's price on this disk: #{micro_per} us per record-and-mark pair at the writer's edge, and a remembered lane end-to-end median of #{e2e_med} us against the bare lane's committed 148 us -- #{Float.round(e2e_med / 148, 1)} times the latency buys an outbox, a last word per name, and a replay that survives the bus"
  )

# cleanup -- fixtures owned on both machines
for t <- ["t1", "t2", "t3"], do: sweep_queue.(t)
{:ok, keys} = Connector.command(probe, ["KEYS", "ecc:*"])
if keys != [], do: {:ok, _} = Connector.command(probe, ["DEL" | keys])
File.rm_rf!(dir)

drained = H.await(fn -> EchoCache.tables() == [] end, 2_000) == :ok

if Enum.all?([h1, h2, h3, h4, h5, h6]) and drained do
  IO.puts("PASS 6/6")
else
  IO.puts("FAIL")
  System.halt(1)
end
