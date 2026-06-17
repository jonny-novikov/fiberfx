# bcs_rung_3_2_check.exs -- gates J1..J5: jobs are entities.
for f <- ~w(base62 native snowflake branded_id) do
  Code.require_file(Path.expand("../../apps/echo_data/lib/echo_data/#{f}.ex", __DIR__))
end

for f <- ~w(resp script keyspace connector jobs) do
  Code.require_file(Enum.find([Path.expand("../../apps/echo_wire/lib/echo_mq/#{f}.ex", __DIR__), Path.expand("../../apps/echo_mq/lib/echo_mq/#{f}.ex", __DIR__)], &File.exists?/1))
end

:ok = EchoData.Snowflake.start(7)
alias EchoData.{BrandedId, Snowflake}
alias EchoMQ.{Connector, Jobs, Keyspace}

defmodule J do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end
end

{:ok, c} = Connector.start_link(port: 6390)
q = "jobs32"
IO.puts("boot: the registry grows by one -- JOB, work as a kind with identity and lifecycle")

# J1 -- the surface
j1 = J.line("J1 surface",
  (fn fns ->
     Enum.all?([browse: 3, enqueue: 4, pending_size: 2], &(&1 in fns)) and
       not Enum.any?(fns, fn {n, _} ->
         s = Atom.to_string(n)
         String.contains?(s, "script") or String.contains?(s, "key")
       end)
   end).(EchoMQ.Jobs.__info__(:functions)),
  "the bus module's surface: enqueue, browse, pending_size -- scripts and key shapes are nobody's business")

# J2 -- enqueue is one script and idempotent by id
ord = BrandedId.generate!("ORD")
jid = BrandedId.generate!("JOB")
payload = :erlang.term_to_binary(%{order: ord, qty: 5})
first = Jobs.enqueue(c, q, jid, payload)
second = Jobs.enqueue(c, q, jid, payload)
{:ok, attempts} = Connector.command(c, ["HGET", Keyspace.job_key(q, jid), "attempts"])
{:ok, depth1} = Jobs.pending_size(c, q)
j2 = J.line("J2 idempotent",
  first == {:ok, :enqueued} and second == {:ok, :duplicate} and attempts == "0" and depth1 == 1,
  "enqueue is one script and idempotent by id: first call enqueued, second answered duplicate, the row untouched and pending holds 1")

# J3 -- kind policy lives in the script
j3 = J.line("J3 kind",
  Jobs.enqueue(c, q, ord, payload) == {:error, :kind},
  "kind policy lives in the script: an ORD id in the job position answers EMQKIND on the wire -- the key let it pass, the law did not")

# J4 -- the order theorem's dividend
jids = for _ <- 1..300, do: Snowflake.next_branded("JOB")
Enum.each(jids, fn id -> {:ok, :enqueued} = Jobs.enqueue(c, q, id, payload) end)
{:ok, newest} = Jobs.browse(c, q, 5)
{:ok, [head]} = Connector.command(c, ["ZRANGE", Keyspace.queue_key(q, "pending"), "-", "+", "BYLEX", "LIMIT", "0", "1"])
{:ok, depth} = Jobs.pending_size(c, q)
j4 = J.line("J4 dividend",
  newest == (jids |> Enum.take(-5) |> Enum.reverse()) and head == jid and depth == 301,
  "the order theorem's dividend: newest-first browse over the ids themselves returns the last five minted in reverse mint order; the very first job sits at the head; 301 pending, no second index anywhere")

# J5 -- the cargo law
{:ok, raw} = Connector.command(c, ["HGET", Keyspace.job_key(q, hd(jids)), "payload"])
%{order: cargo_ord, qty: 5} = :erlang.binary_to_term(raw, [:safe])
{:ok, "ORD", _snow} = BrandedId.parse(cargo_ord)
j5 = J.line("J5 cargo",
  cargo_ord == ord,
  "the cargo law holds: the payload carries #{cargo_ord} and a quantity, never a row -- decoded and re-parsed on the far side of the wire")

# cleanup
all = [jid | jids]
{:ok, _} = Connector.pipeline(c, [["DEL", Keyspace.queue_key(q, "pending") | Enum.map(all, &Keyspace.job_key(q, &1))]])

if Enum.all?([j1, j2, j3, j4, j5]) do
  IO.puts("PASS 5/5")
else
  IO.puts("FAIL")
  System.halt(1)
end
