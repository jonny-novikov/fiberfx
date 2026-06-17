# bcs_rung_4_1_check.exs -- gates E1..E6: cache-aside at ETS speed.
#   cd /Users/jonny/dev/jonnify/echo && mix run --no-start rungs/cache/bcs_rung_4_1_check.exs   (Valkey live on 6390)
for f <- ~w(base62 native snowflake branded_id) do
  Code.require_file(Path.expand("../../apps/echo_data/lib/echo_data/#{f}.ex", __DIR__))
end

for f <- ~w(resp script keyspace connector) do
  Code.require_file(Enum.find([Path.expand("../../apps/echo_wire/lib/echo_mq/#{f}.ex", __DIR__), Path.expand("../../apps/echo_mq/lib/echo_mq/#{f}.ex", __DIR__)], &File.exists?/1))
end

for f <- ~w(keyspace echo_cache coherence ring table) do
  Code.require_file(Path.expand("../../apps/echo_cache/lib/echo_cache/#{f}.ex", __DIR__))
end

:ok = EchoData.Snowflake.start(9)
alias EchoData.BrandedId
alias EchoCache.Table
alias EchoMQ.Connector

defmodule E do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end

  def rate(n, us), do: trunc(n * 1_000_000 / max(us, 1))
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

quote_calls = :counters.new(1, [])

quote_loader = fn _id ->
  :counters.add(quote_calls, 1, 1)
  Process.sleep(50)
  {:ok, "px=101.50;sz=300"}
end

ref_calls = :counters.new(1, [])

ref_loader = fn _id ->
  :counters.add(ref_calls, 1, 1)
  {:ok, "tick=0.01;lot=100"}
end

{:ok, _} =
  Table.start_link(
    name: :quotes,
    kind: "AST",
    ttl_ms: 300,
    jitter: 0.2,
    sweep_ms: 100,
    loader: quote_loader,
    connector: [port: 6390]
  )

{:ok, _} =
  Table.start_link(
    name: :refdata,
    kind: "AST",
    ttl_ms: 60_000,
    jitter: 0.0,
    max_size: 100,
    sweep_ms: 60_000,
    loader: ref_loader,
    connector: [port: 6390]
  )

# E1 -- declared, not discovered; the kind law at the door
declared = EchoCache.tables() |> Enum.map(fn {n, s} -> {n, s.kind, s.ttl_ms, s.coherence} end)
bad = Table.fetch(:quotes, "ORD0KHTOWnGLuC")
{:ok, leak} = Connector.command(probe, ["KEYS", "ecc:{quotes}:*"])

e1 =
  E.line(
    "E1 declared",
    Enum.sort(declared) == [{:quotes, "AST", 300, :none}, {:refdata, "AST", 60_000, :none}] and
      EchoCache.spec(:undeclared) == :error and
      bad == {:error, :kind} and :counters.get(quote_calls, 1) == 0 and leak == [],
    "two caches enumerable with their full declarations -- kind, ttl, coherence -- an undeclared name answers :error, and a wrong-kind id is refused at the door: zero loader runs, zero keys on the wire"
  )

# E2 -- the three sources of one answer
ast = BrandedId.generate!("AST")
{:ok, v1, s1} = Table.fetch(:quotes, ast)
{:ok, _v2, s2} = Table.fetch(:quotes, ast)
{:ok, pttl} = Connector.command(probe, ["PTTL", EchoCache.Keyspace.key("quotes", ast)])
:ets.delete(:quotes, ast)
{:ok, _v3, s3} = Table.fetch(:quotes, ast)

e2 =
  E.line(
    "E2 sources",
    {s1, s2, s3} == {:fill, :hit, :l2} and v1 == "px=101.50;sz=300" and
      :counters.get(quote_calls, 1) == 1 and pttl > 0 and pttl <= 300,
    "one name, three sources in order: a cold read fills (loader ran once), a warm read hits L1 without touching the owner, and an L1 drop falls back to L2 -- the loader still ran once; the L2 row carries the declared TTL (PTTL #{pttl} ms of 300)"
  )

# E3 -- one fill per herd
IO.puts("derive (herd): 200 concurrent cold readers without single-flight run 200 loads; the law demands the misses coalesce onto one flight -- expect loader runs 1 and 199 coalesced waiters")
herd_id = BrandedId.generate!("AST")
before_calls = :counters.get(quote_calls, 1)

results =
  1..200
  |> Enum.map(fn _ -> Task.async(fn -> Table.fetch(:quotes, herd_id) end) end)
  |> Task.await_many(10_000)

herd_calls = :counters.get(quote_calls, 1) - before_calls
values = results |> Enum.map(fn {:ok, v, _} -> v end) |> Enum.uniq()
coalesced = Table.stats(:quotes).coalesced

e3 =
  E.line(
    "E3 herd",
    herd_calls == 1 and length(results) == 200 and values == ["px=101.50;sz=300"] and
      coalesced >= 199,
    "the thundering herd survived with one fill: 200 concurrent cold readers, loader runs 1, coalesced waiters #{coalesced}, every reader holding the one answer"
  )

# E4 -- the title's gate: hits at ETS speed
IO.puts("derive (speed): a hit is a caller-side lookup on a public read-concurrency set plus the kind gate and a counter bump -- expect 250,000 to 1,500,000 hit reads per second on this core; an L2 GET pays a loopback round trip, and Appendix A committed 29,456 sequential round trips per second, near 34 us each -- expect the L1 hit at least 10 times cheaper than the wire")
warm = BrandedId.generate!("AST")
{:ok, _, :fill} = Table.fetch(:refdata, warm)

n = 200_000

{hit_us, :ok} =
  :timer.tc(fn ->
    Enum.each(1..n, fn _ -> {:ok, _, :hit} = Table.fetch(:refdata, warm) end)
  end)

hit_rate = E.rate(n, hit_us)
hit_ns = trunc(hit_us * 1_000 / n)

l2k = EchoCache.Keyspace.key("refdata", warm)

{l2_us, :ok} =
  :timer.tc(fn ->
    Enum.each(1..1_000, fn _ -> {:ok, _} = Connector.command(probe, ["GET", l2k]) end)
  end)

l2_each_us = div(l2_us, 1_000)

e4 =
  E.line(
    "E4 speed",
    hit_rate > 250_000 and l2_each_us > div(hit_ns, 1000) * 10,
    "measured: #{hit_rate} hit reads per second (#{hit_ns} ns each) against #{l2_each_us} us per L2 GET on the same wire -- the L1 hit is #{div(l2_each_us * 1000, max(hit_ns, 1))} times cheaper than the round trip it replaces, inside the derived band"
  )

# E5 -- jittered expiry and the sweeper
IO.puts("derive (jitter): ttl 300 ms at jitter 0.2 spreads expiry uniformly across plus-minus 60 ms -- 400 rows filled in one fast pass should spread at least 70 ms beyond their fill walltime, approaching 120; a jitter 0.0 cohort's spread can never exceed its own fill walltime -- jitter adds nothing; the sweeper on a 100 ms tick then reclaims the whole cohort without a single read")
jit_calls = :counters.new(1, [])

{:ok, _} =
  Table.start_link(
    name: :jit,
    kind: "AST",
    ttl_ms: 300,
    jitter: 0.2,
    sweep_ms: 100,
    loader: fn _ ->
      :counters.add(jit_calls, 1, 1)
      {:ok, "j"}
    end,
    connector: [port: 6390]
  )

cohort = for _ <- 1..400, do: BrandedId.generate!("AST")

{jit_fill_us, :ok} =
  :timer.tc(fn -> Enum.each(cohort, fn id -> {:ok, _, :fill} = Table.fetch(:jit, id) end) end)

jit_walltime = div(jit_fill_us, 1_000)
expiries = :ets.tab2list(:jit) |> Enum.map(fn {_, _, e, _} -> e end)
spread = Enum.max(expiries) - Enum.min(expiries)

flat = for _ <- 1..50, do: BrandedId.generate!("AST")

{flat_fill_us, :ok} =
  :timer.tc(fn -> Enum.each(flat, fn id -> {:ok, _, :fill} = Table.fetch(:refdata, id) end) end)

flat_walltime = div(flat_fill_us, 1_000)

flat_exp =
  :ets.tab2list(:refdata)
  |> Enum.filter(fn {id, _, _, _} -> id in flat end)
  |> Enum.map(fn {_, _, e, _} -> e end)

flat_spread = Enum.max(flat_exp) - Enum.min(flat_exp)

before_sweeps = Table.stats(:jit).sweeps
Process.sleep(700)
jit_size = :ets.info(:jit, :size)
st5 = Table.stats(:jit)

e5 =
  E.line(
    "E5 jitter",
    spread >= jit_walltime + 70 and spread <= jit_walltime + 130 and
      flat_spread <= flat_walltime + 5 and spread > flat_spread * 3 and
      jit_size == 0 and st5.swept >= 400 and st5.sweeps > before_sweeps,
    "400 rows filled in #{jit_walltime} ms expire #{spread} ms apart at jitter 0.2 -- no synchronized re-herd -- while the jitter 0.0 cohort spreads #{flat_spread} ms across a #{flat_walltime} ms fill: jitter added nothing there; the sweeper then reclaimed the whole cohort on its tick (swept #{st5.swept}, table size #{jit_size}) with not one read paying the cleanup"
  )

# E6 -- the bound: full degrades to pass-through, never failure
IO.puts("derive (bound): refdata declares max_size 100 with a 60 s ttl, so nothing expires to reclaim -- 49 more fills fit beside the 51 live rows, then every further fill must serve its caller and skip the insert")
live = :ets.info(:refdata, :size)
extra = for _ <- 1..150, do: BrandedId.generate!("AST")
extra_results = Enum.map(extra, fn id -> Table.fetch(:refdata, id) end)
all_served = Enum.all?(extra_results, fn {:ok, v, :fill} -> v == "tick=0.01;lot=100" end)
st6 = Table.stats(:refdata)

put_id = BrandedId.generate!("AST")
:ok = Table.put(:quotes, put_id, "px=99.00;sz=50")
{:ok, <<_put_version::binary-14, l2v::binary>>} =
  Connector.command(probe, ["GET", EchoCache.Keyspace.key("quotes", put_id)])

{:ok, putv, :hit} = Table.fetch(:quotes, put_id)

e6 =
  E.line(
    "E6 bound",
    live == 51 and st6.size == 100 and st6.full_skips == live + 150 - 100 and all_served and
      l2v == "px=99.00;sz=50" and putv == l2v,
    "the declaration holds: size capped at #{st6.size} of 100, #{st6.full_skips} fills served their callers and skipped the insert -- a full cache is a stat, never an error -- and the writer path lands one value in both layers"
  )

# cleanup -- fixtures owned
for t <- ["quotes", "refdata", "jit"] do
  {:ok, keys} = Connector.command(probe, ["KEYS", "ecc:{" <> t <> "}:*"])
  if keys != [], do: {:ok, _} = Connector.command(probe, ["DEL" | keys])
end

:ok = Table.stop(:quotes)
:ok = Table.stop(:refdata)
:ok = Table.stop(:jit)
empty_after = EchoCache.tables()

if Enum.all?([e1, e2, e3, e4, e5, e6]) and empty_after == [] do
  IO.puts("PASS 6/6")
else
  IO.puts("FAIL")
  System.halt(1)
end
