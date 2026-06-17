# bcs_rung_3_4_check.exs -- gates G1..G8: fair lanes.
for f <- ~w(base62 native snowflake branded_id) do
  Code.require_file(Path.expand("../../apps/echo_data/lib/echo_data/#{f}.ex", __DIR__))
end

for f <- ~w(resp script keyspace connector jobs lanes consumer) do
  Code.require_file(Enum.find([Path.expand("../../apps/echo_wire/lib/echo_mq/#{f}.ex", __DIR__), Path.expand("../../apps/echo_mq/lib/echo_mq/#{f}.ex", __DIR__)], &File.exists?/1))
end

:ok = EchoData.Snowflake.start(7)
alias EchoData.BrandedId
alias EchoMQ.{Connector, Consumer, Jobs, Keyspace, Lanes}

defmodule G do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end
end

{:ok, c} = Connector.start_link(port: 6390)
test = self()

purge = fn q, ids, groups ->
  base =
    ~w(pending active schedule dead ring wake paused glimit gactive)
    |> Enum.map(&Keyspace.queue_key(q, &1))

  lanes = Enum.map(groups, &Keyspace.queue_key(q, "g:" <> &1 <> ":pending"))
  jobs = Enum.map(ids, &Keyspace.job_key(q, &1))

  (base ++ lanes ++ jobs)
  |> Enum.chunk_every(200)
  |> Enum.each(fn chunk -> {:ok, _} = Connector.pipeline(c, [["DEL" | chunk]]) end)
end

# G1 -- the surface grew by exactly the lanes and the loop
g1 =
  G.line(
    "G1 surface",
    Enum.sort(EchoMQ.Lanes.__info__(:functions)) ==
      [claim: 3, depth: 3, enqueue: 5, limit: 4, pause: 3, resume: 3] and
      Enum.all?([child_spec: 1, start_link: 1], &(&1 in EchoMQ.Consumer.__info__(:functions))),
    "the lanes surface: enqueue, claim, limit, pause, resume, depth -- six verbs over the same machine; the consumer exports start_link and child_spec -- the loop is a supervised citizen"
  )

# G2 -- the ring is the rota: strict rotation, mint order inside every lane
q2 = "fair34"
[p1, p2, p3] = for _ <- 1..3, do: BrandedId.generate!("PRT")

enq2 =
  for n <- 1..4, grp <- [p1, p2, p3] do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(c, q2, grp, id, "t#{n}")
    {grp, id}
  end

by_lane = Enum.group_by(enq2, &elem(&1, 0), &elem(&1, 1))

claims2 =
  for _ <- 1..12 do
    {:ok, {id, _pay, 1, grp}} = Lanes.claim(c, q2, 60_000)
    {grp, id}
  end

rotation_ok = Enum.map(claims2, &elem(&1, 0)) == List.duplicate([p1, p2, p3], 4) |> List.flatten()
served_by_lane = Enum.group_by(claims2, &elem(&1, 0), &elem(&1, 1))
fifo_ok = Enum.all?([p1, p2, p3], fn g -> served_by_lane[g] == by_lane[g] end)

raised =
  try do
    Lanes.enqueue(c, q2, "desk-7", BrandedId.generate!("JOB"), "x")
  rescue
    ArgumentError -> :raised
  end

g2 =
  G.line(
    "G2 rotation",
    rotation_ok and fifo_ok and raised == :raised,
    "twelve claims walk the ring four full turns -- three lanes, strict rotation -- and every lane serves in mint order; a lane named by a non-id raises before any wire is touched"
  )

purge.(q2, Enum.map(enq2, &elem(&1, 1)), [p1, p2, p3])

# G3 -- the starvation refusal: a 400-job storm cannot bury a 20-job lane
q3 = "storm34"
qf = "flood34"
hot = BrandedId.generate!("PRT")
quiet = BrandedId.generate!("PRT")

hot_ids =
  for _ <- 1..400 do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(c, q3, hot, id, "hot")
    id
  end

quiet_ids =
  for _ <- 1..20 do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(c, q3, quiet, id, "quiet")
    id
  end

order =
  for _ <- 1..420 do
    {:ok, {_id, _pay, 1, grp}} = Lanes.claim(c, q3, 60_000)
    grp
  end

qpos =
  order
  |> Enum.with_index(1)
  |> Enum.filter(fn {g, _} -> g == quiet end)
  |> Enum.map(&elem(&1, 1))

qmax = Enum.max(qpos)

# flat control: same arrival order, its own fresh jobs
flat_hot_ids =
  for _ <- 1..400 do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(c, qf, id, "hot")
    id
  end

flat_quiet_ids =
  for _ <- 1..20 do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(c, qf, id, "quiet")
    id
  end

flat400 =
  for _ <- 1..400 do
    {:ok, {_, pay, _}} = Jobs.claim(c, qf, 60_000)
    pay
  end

{:ok, {_, first_after_storm, _}} = Jobs.claim(c, qf, 60_000)

g3 =
  G.line(
    "G3 starvation",
    qmax == 40 and length(qpos) == 20 and hd(qpos) == 2 and
      Enum.all?(flat400, &(&1 == "hot")) and first_after_storm == "quiet",
    "the storm stays in its lane: the quiet lane's last job is served at position 40 of 420 while the flat queue, fed the same arrival order, serves its first quiet job at position 401 -- rotation is the refusal"
  )

purge.(q3, hot_ids ++ quiet_ids, [hot, quiet])
purge.(qf, flat_hot_ids ++ flat_quiet_ids, [])

# G4 -- the ceiling: limit 2, the third claim answers empty, one complete reopens
q4 = "limit34"
a4 = BrandedId.generate!("PRT")
:ok = Lanes.limit(c, q4, a4, 2)

ids4 =
  for _ <- 1..5 do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(c, q4, a4, id, "work")
    id
  end

{:ok, {id4a, _, 1, ^a4}} = Lanes.claim(c, q4, 60_000)
{:ok, {_id4b, _, 1, ^a4}} = Lanes.claim(c, q4, 60_000)
third = Lanes.claim(c, q4, 60_000)
{:ok, gact4} = Connector.command(c, ["HGET", Keyspace.queue_key(q4, "gactive"), a4])
:ok = Jobs.complete(c, q4, id4a, 1)
fourth = Lanes.claim(c, q4, 60_000)

g4 =
  G.line(
    "G4 limit",
    third == :empty and gact4 == "2" and match?({:ok, {_, _, 1, ^a4}}, fourth),
    "limit 2 holds: two leases out and the third claim answers empty with the lane parked at its ceiling and gactive reading 2; one complete reopens the lane and the next claim is served"
  )

purge.(q4, ids4, [a4])

# G5 -- pause stops new claims with the backlog intact; resume returns the lane
q5 = "pause34"
a5 = BrandedId.generate!("PRT")
b5 = BrandedId.generate!("PRT")

ids5 =
  for grp <- [a5, b5], _ <- 1..3 do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(c, q5, grp, id, "p")
    id
  end

:ok = Lanes.pause(c, q5, a5)

after_pause =
  for _ <- 1..3 do
    {:ok, {_, _, 1, grp}} = Lanes.claim(c, q5, 60_000)
    grp
  end

empty5 = Lanes.claim(c, q5, 60_000)
{:ok, depth_a} = Lanes.depth(c, q5, a5)
:ok = Lanes.resume(c, q5, a5)

after_resume =
  for _ <- 1..3 do
    {:ok, {_, _, 1, grp}} = Lanes.claim(c, q5, 60_000)
    grp
  end

g5 =
  G.line(
    "G5 pause",
    after_pause == [b5, b5, b5] and empty5 == :empty and depth_a == 3 and
      after_resume == [a5, a5, a5],
    "pause removes the lane from rotation with its backlog intact at depth 3; resume returns it and the ring serves the parked three in mint order"
  )

purge.(q5, ids5, [a5, b5])

# G6 -- park, don't poll: a measured poller, then a parked consumer at zero
q6 = "park34"
g6grp = BrandedId.generate!("PRT")
{:ok, c2} = Connector.start_link(port: 6390)

poll0 = Connector.stats(c2).commands
poll_until = System.monotonic_time(:millisecond) + 400

poller = fn poller ->
  if System.monotonic_time(:millisecond) < poll_until do
    _ = Lanes.claim(c2, q6, 1_000)
    Process.sleep(10)
    poller.(poller)
  end
end

poller.(poller)
poll_cmds = Connector.stats(c2).commands - poll0

{:ok, cons6} =
  Consumer.start_link(
    queue: q6,
    conn: c2,
    beat_ms: 5_000,
    handler: fn %{id: id} ->
      send(test, {:served, id, System.monotonic_time(:millisecond)})
      :ok
    end
  )

Process.sleep(250)
idle0 = Connector.stats(c2).commands
Process.sleep(400)
idle_delta = Connector.stats(c2).commands - idle0

j6 = BrandedId.generate!("JOB")
t0 = System.monotonic_time(:millisecond)
{:ok, :enqueued} = Lanes.enqueue(c, q6, g6grp, j6, "wake-me")

dt =
  receive do
    {:served, ^j6, t1} -> t1 - t0
  after
    2_000 -> :timeout
  end

Process.unlink(cons6)
Process.exit(cons6, :shutdown)
Process.sleep(50)

g6 =
  G.line(
    "G6 park",
    idle_delta == 0 and is_integer(dt) and dt < 200 and poll_cmds >= 30,
    "parked on the wake key the consumer spends 0 commands in a 400 ms idle window where a 10 ms poller spent #{poll_cmds}; the wake answers an enqueue in #{dt} ms against a 5000 ms beat -- park, don't poll"
  )

purge.(q6, [j6], [g6grp])

# G7 -- the loop owns the rhythm: reap and promote ride the beat
q7 = "beat34"
g7grp = BrandedId.generate!("PRT")
j7a = BrandedId.generate!("JOB")
{:ok, :enqueued} = Lanes.enqueue(c, q7, g7grp, j7a, "orphan")
{:ok, {^j7a, _, 1, ^g7grp}} = Lanes.claim(c, q7, 60)

{:ok, cons7} =
  Consumer.start_link(
    queue: q7,
    connector: [port: 6390],
    beat_ms: 120,
    retry_delay_ms: 80,
    max_attempts: 3,
    handler: fn %{id: id, payload: pay, attempts: att} ->
      send(test, {:beat_served, id, att})
      if pay == "flaky" and att == 1, do: {:error, "flaky"}, else: :ok
    end
  )

orphan_att =
  receive do
    {:beat_served, ^j7a, att} -> att
  after
    3_000 -> :timeout
  end

j7b = BrandedId.generate!("JOB")
{:ok, :enqueued} = Lanes.enqueue(c, q7, g7grp, j7b, "flaky")

flaky_first =
  receive do
    {:beat_served, ^j7b, att} -> att
  after
    3_000 -> :timeout
  end

flaky_second =
  receive do
    {:beat_served, ^j7b, att} -> att
  after
    3_000 -> :timeout
  end

Process.sleep(150)
{:ok, gact7} = Connector.command(c, ["HGET", Keyspace.queue_key(q7, "gactive"), g7grp])
{:ok, ring7} = Connector.command(c, ["LLEN", Keyspace.queue_key(q7, "ring")])
{:ok, act7} = Connector.command(c, ["ZCARD", Keyspace.queue_key(q7, "active")])

Process.unlink(cons7)
Process.exit(cons7, :shutdown)
Process.sleep(50)

g7 =
  G.line(
    "G7 rhythm",
    orphan_att == 2 and flaky_first == 1 and flaky_second == 2 and gact7 == nil and
      ring7 == 0 and act7 == 0,
    "the loop owns the rhythm: a 60 ms lease left orphaned is reaped on the beat and served with token 2; a flaky job retries through the schedule and lands with token 2 -- the lane's count clears, the ring empties"
  )

purge.(q7, [j7a, j7b], [g7grp])

# G8 -- the reap window closes: a late holder leaves no ghost, on either machine
q8 = "window34"
g8grp = BrandedId.generate!("PRT")
j8 = BrandedId.generate!("JOB")
{:ok, :enqueued} = Lanes.enqueue(c, q8, g8grp, j8, "w")
{:ok, {^j8, _, 1, ^g8grp}} = Lanes.claim(c, q8, 50)
Process.sleep(80)
{:ok, 1} = Jobs.reap(c, q8)
late = Jobs.complete(c, q8, j8, 1)
{:ok, row8} = Connector.command(c, ["EXISTS", Keyspace.job_key(q8, j8)])
{:ok, lane8} = Connector.command(c, ["ZCARD", Keyspace.queue_key(q8, "g:" <> g8grp <> ":pending")])
{:ok, ring8} = Connector.command(c, ["LLEN", Keyspace.queue_key(q8, "ring")])
{:ok, gact8} = Connector.command(c, ["HGET", Keyspace.queue_key(q8, "gactive"), g8grp])

qf8 = "window34f"
j8f = BrandedId.generate!("JOB")
{:ok, :enqueued} = Jobs.enqueue(c, qf8, j8f, "w")
{:ok, {^j8f, _, 1}} = Jobs.claim(c, qf8, 50)
Process.sleep(80)
{:ok, 1} = Jobs.reap(c, qf8)
late_f = Jobs.complete(c, qf8, j8f, 1)
{:ok, pend8f} = Connector.command(c, ["ZCARD", Keyspace.queue_key(qf8, "pending")])
{:ok, row8f} = Connector.command(c, ["EXISTS", Keyspace.job_key(qf8, j8f)])

g8 =
  G.line(
    "G8 window",
    late == :ok and row8 == 0 and lane8 == 0 and ring8 == 0 and gact8 == nil and
      late_f == :ok and pend8f == 0 and row8f == 0,
    "the reap window closes on both machines: a holder completing token 1 after the reaper retires the job everywhere -- no ghost in the lane, none in pending, the ring empties and the count clears"
  )

purge.(q8, [j8], [g8grp])
purge.(qf8, [j8f], [])

if Enum.all?([g1, g2, g3, g4, g5, g6, g7, g8]) do
  IO.puts("PASS 8/8")
else
  IO.puts("FAIL")
  System.halt(1)
end
