# bcs_rung_3_1_check.exs -- gates F1..F5: the fence and the keyspace.
for f <- ~w(base62 native snowflake branded_id) do
  Code.require_file(Path.expand("../../apps/echo_data/lib/echo_data/#{f}.ex", __DIR__))
end

for f <- ~w(resp script keyspace connector) do
  Code.require_file(Enum.find([Path.expand("../../apps/echo_wire/lib/echo_mq/#{f}.ex", __DIR__), Path.expand("../../apps/echo_mq/lib/echo_mq/#{f}.ex", __DIR__)], &File.exists?/1))
end

:ok = EchoData.Snowflake.start(7)
alias EchoData.{BrandedId, Snowflake}
alias EchoMQ.{Connector, Keyspace}

defmodule F do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end
end

# F1 -- the part's map, every shape asserted
vid = BrandedId.encode!("ORD", 320_636_799_581_945_856)
f1 = F.line("F1 map",
  Keyspace.queue_key("orders", "pending") == "emq:{orders}:pending" and
    Keyspace.job_key("orders", vid) == "emq:{orders}:job:" <> vid and
    Keyspace.version_key() == "{emq}:version" and
    Keyspace.reserve("locks") == "{emq}:locks" and
    Keyspace.prefix_bytes("orders", "job:") == 17,
  "the part's map: emq:{orders}:pending | emq:{orders}:job:#{vid} | {emq}:version | {emq}:locks -- 17 bytes before the payload")

# F2 -- the job position is gated before any wire is touched
raised = fn fun ->
  try do
    fun.()
    false
  rescue
    ArgumentError -> true
  end
end

f2 = F.line("F2 gate",
  raised.(fn -> Keyspace.job_key("orders", "12345678901234") end) and
    raised.(fn -> Keyspace.job_key("orders", "not-a-valid-id") end),
  "the job position is gated: a fourteen-byte decimal and a fourteen-byte slug both raise before any wire is touched; kind policy waits for the enqueue script")

# F3 -- the fence holds on a live wire
{:ok, c} = Connector.start_link(port: 6390)
{:ok, v} = Connector.command(c, ["GET", Keyspace.version_key()])
f3 = F.line("F3 fence",
  Connector.wire_version() == "echomq:2.0.0" and v == "echomq:2.0.0",
  "the fence holds on a live wire: GET {emq}:version answers echomq:2.0.0 through the fenced connector itself")

# F4 -- binary discipline through the queue's own keys
ids = for _ <- 1..500, do: Snowflake.next_branded("ORD")
payload = fn i -> <<"a\r\nb", 0, i::32>> end
sets = ids |> Enum.with_index() |> Enum.map(fn {id, i} -> ["SET", Keyspace.job_key("f31", id), payload.(i)] end)
{:ok, set_replies} = Connector.pipeline(c, sets)
{:ok, vals} = Connector.pipeline(c, Enum.map(ids, fn id -> ["GET", Keyspace.job_key("f31", id)] end))
matches =
  vals |> Enum.with_index() |> Enum.count(fn {val, i} -> val == payload.(i) end)
{:ok, _} = Connector.pipeline(c, [["DEL" | Enum.map(ids, &Keyspace.job_key("f31", &1))]])
f4 = F.line("F4 binary",
  Enum.all?(set_replies, &(&1 == "OK")) and matches == 500,
  "binary payloads with embedded CRLF and NUL survive 500/500 round trips through job keys in two pipelines")

# F5 -- the co-location law
family = [
  Keyspace.queue_key("orders", "pending"),
  Keyspace.queue_key("orders", "active"),
  Keyspace.queue_key("orders", "meta"),
  Keyspace.job_key("orders", vid)
]
slots = family |> Enum.map(&Keyspace.slot/1) |> Enum.uniq()
s = hd(slots)
other = Keyspace.slot(Keyspace.queue_key("fills", "pending"))
f5 = F.line("F5 slot",
  length(slots) == 1 and other != s and Keyspace.slot("123456789") == 12_739,
  "co-location law: pending, active, meta, and the job row of {orders} all answer slot #{s}; {fills} answers #{other} -- multi-key scripts stay legal on the clustered day (vector 12739 holds)")

if Enum.all?([f1, f2, f3, f4, f5]) do
  IO.puts("PASS 5/5")
else
  IO.puts("FAIL")
  System.halt(1)
end
