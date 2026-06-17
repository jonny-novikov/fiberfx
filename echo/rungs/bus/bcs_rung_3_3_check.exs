# bcs_rung_3_3_check.exs -- gates L1..L6: the state machine in Lua.
for f <- ~w(base62 native snowflake branded_id) do
  Code.require_file(Path.expand("../../apps/echo_data/lib/echo_data/#{f}.ex", __DIR__))
end

for f <- ~w(resp script keyspace connector jobs) do
  Code.require_file(Enum.find([Path.expand("../../apps/echo_wire/lib/echo_mq/#{f}.ex", __DIR__), Path.expand("../../apps/echo_mq/lib/echo_mq/#{f}.ex", __DIR__)], &File.exists?/1))
end

:ok = EchoData.Snowflake.start(7)
alias EchoData.BrandedId
alias EchoMQ.{Connector, Jobs, Keyspace}

defmodule L do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end
end

{:ok, c} = Connector.start_link(port: 6390)
q = "life33"
pay = :erlang.term_to_binary(%{order: BrandedId.generate!("ORD")})
state = fn id -> elem(Connector.command(c, ["HGET", Keyspace.job_key(q, id), "state"]), 1) end

# L1 -- the surface grew by exactly the machine
l1 = L.line("L1 surface",
  Enum.all?(
    [browse: 3, claim: 3, complete: 4, enqueue: 4, pending_size: 2, promote: 3, reap: 2, retry: 7],
    &(&1 in EchoMQ.Jobs.__info__(:functions))
  ),
  "the machine's surface: claim, complete, retry, promote, reap join enqueue, browse, pending_size -- five new verbs, every transition one script")

# L2 -- the happy path with lease and token
j1 = BrandedId.generate!("JOB")
{:ok, :enqueued} = Jobs.enqueue(c, q, j1, pay)
{:ok, {^j1, ^pay, 1}} = Jobs.claim(c, q, 5_000)
{:ok, score} = Connector.command(c, ["ZSCORE", Keyspace.queue_key(q, "active"), j1])
active_state = state.(j1)
:ok = Jobs.complete(c, q, j1, 1)
{:ok, exists} = Connector.command(c, ["EXISTS", Keyspace.job_key(q, j1)])
l2 = L.line("L2 happy",
  active_state == "active" and (is_binary(score) or is_float(score)) and exists == 0,
  "claim hands out the oldest job with a server-clock lease and fencing token 1; complete with the right token retires the row -- nothing remains")

# L3 -- the zombie is fenced
j2 = BrandedId.generate!("JOB")
{:ok, :enqueued} = Jobs.enqueue(c, q, j2, pay)
{:ok, {^j2, _, 1}} = Jobs.claim(c, q, 5_000)
stale = Jobs.complete(c, q, j2, 99)
l3 = L.line("L3 fence",
  stale == {:error, :stale} and state.(j2) == "active",
  "a stale token is refused on the wire: EMQSTALE; the lease holder's work survives the zombie's complete")

# L4 -- retry parks, promote returns, the token climbs
{:ok, :scheduled} = Jobs.retry(c, q, j2, 1, 50, 3, "transient")
scheduled_state = state.(j2)
{:ok, depth_while_parked} = Jobs.pending_size(c, q)
Process.sleep(80)
{:ok, moved} = Jobs.promote(c, q, 10)
{:ok, {^j2, _, 2}} = Jobs.claim(c, q, 5_000)
l4 = L.line("L4 schedule",
  scheduled_state == "scheduled" and depth_while_parked == 0 and moved == 1,
  "retry parks the job in the schedule, promote moves the due back to pending, and the next claim hands token 2 -- one job, two lives, one counter")

# L5 -- the third strike is the morgue
{:ok, :dead} = Jobs.retry(c, q, j2, 2, 50, 2, "still failing")
{:ok, [morgue_head]} = Connector.command(c, ["ZRANGE", Keyspace.queue_key(q, "dead"), "-", "+", "BYLEX", "LIMIT", "0", "1"])
{:ok, last_error} = Connector.command(c, ["HGET", Keyspace.job_key(q, j2), "last_error"])
l5 = L.line("L5 dead",
  state.(j2) == "dead" and morgue_head == j2 and last_error == "still failing",
  "attempts 2 against max 2 is the morgue: state dead, last_error kept, and the dead set browses in mint order like everything else")

# L6 -- crash recovery on the server's clock
j3 = BrandedId.generate!("JOB")
{:ok, :enqueued} = Jobs.enqueue(c, q, j3, pay)
{:ok, {^j3, _, 1}} = Jobs.claim(c, q, 40)
Process.sleep(80)
{:ok, reaped} = Jobs.reap(c, q)
{:ok, {^j3, _, 2}} = Jobs.claim(c, q, 5_000)
l6 = L.line("L6 reap",
  reaped == 1,
  "a 40 ms lease expires unanswered; reap returns the orphan to pending and the next claim holds token 2 -- crash recovery is one zset scan on the server's clock")

# cleanup
keys = ["pending", "active", "schedule", "dead"] |> Enum.map(&Keyspace.queue_key(q, &1))
{:ok, _} = Connector.pipeline(c, [["DEL" | keys ++ Enum.map([j1, j2, j3], &Keyspace.job_key(q, &1))]])

if Enum.all?([l1, l2, l3, l4, l5, l6]) do
  IO.puts("PASS 6/6")
else
  IO.puts("FAIL")
  System.halt(1)
end
