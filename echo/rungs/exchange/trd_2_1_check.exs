# trd_2_1_check.exs -- gates G1, G2, G5, G6 + AS-2 + AS-7: the pure matching core.
#   cd /Users/jonny/dev/jonnify/echo && mix run --no-start rungs/exchange/trd_2_1_check.exs
#
# Exchange.OrderBook + Exchange.Decider are pure (modulo the FIL mint, INV-3) and
# touch no Valkey, so this is a --no-start runner: it Code.require_file's the id
# canon raw (base62 -> native -> snowflake -> branded_id), then order_book.ex and
# decider.ex, calls EchoData.Snowflake.start(N) once (the FIL/ORD minting
# prerequisite), and runs one printed line per gate. Nonzero exit on any failure.
# The generator is a self-contained seeded :rand (no StreamData dep, so
# --no-start-safe and deterministic). Spec: docs/exchange/trd.2.1.specs.md
# ("Acceptance gates"); the trd_1_1_check.exs pattern.

for f <- ~w(base62 native snowflake branded_id) do
  Code.require_file(Path.expand("../../apps/echo_data/lib/echo_data/#{f}.ex", __DIR__))
end

Code.require_file(Path.expand("../../apps/exchange/lib/exchange/order_book.ex", __DIR__))
Code.require_file(Path.expand("../../apps/exchange/lib/exchange/decider.ex", __DIR__))

:ok = EchoData.Snowflake.start(12)
alias EchoData.BrandedId
alias Exchange.{OrderBook, Decider}

defmodule G do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end

  # Structural float-scan over any event/book term (INV-6 / G5): no number
  # anywhere -- the price pair, the map values, a resting tuple, the gb_trees
  # levels -- may be a float.
  def no_float?(f) when is_float(f), do: false

  def no_float?(%OrderBook{buy: buy, sell: sell}) do
    no_float?(:gb_trees.to_list(buy)) and no_float?(:gb_trees.to_list(sell))
  end

  def no_float?(%{} = m), do: Enum.all?(m, fn {k, v} -> no_float?(k) and no_float?(v) end)
  def no_float?({a, b}), do: no_float?(a) and no_float?(b)
  def no_float?(t) when is_tuple(t), do: t |> Tuple.to_list() |> no_float?()
  def no_float?(list) when is_list(list), do: Enum.all?(list, &no_float?/1)
  def no_float?(_), do: true

  # Mint an ORD id the way the Gateway does -- in call order, so successive ids
  # byte-sort ascending (mint order == time priority, INV-5).
  def ord, do: EchoData.Snowflake.next_branded("ORD")

  # Fold decide's emitted events into the book (INV-4).
  def fold(events, book), do: Enum.reduce(events, book, fn e, b -> Decider.evolve(b, e) end)

  # Rest a fresh maker onto a book (a :rested event the way decide emits one),
  # minting its ORD id so arrival order == mint order. Returns {book, id}.
  def rest_maker(book, side, price, quantity, account) do
    id = ord()

    book =
      Decider.evolve(book, {
        :rested,
        %{
          order: id,
          account: account,
          instrument: "BBG004730N88",
          side: side,
          price: price,
          quantity: quantity
        }
      })

    {book, id}
  end

  # A {:place, …} command with the TRD.1.1 fields; the id is freshly minted.
  def place(overrides) do
    base = %{
      id: ord(),
      instrument: "BBG004730N88",
      account: "acct-A",
      direction: :buy,
      type: :limit,
      quantity: 10,
      price: {100, 0}
    }

    {:place, Map.merge(base, overrides)}
  end
end

IO.puts(
  "header: Exchange.OrderBook + Exchange.Decider (pure, no Valkey) | Elixir #{System.version()} OTP #{:erlang.system_info(:otp_release)} | schedulers #{System.schedulers_online()}"
)

# ── G1 -- two crossing orders fill at the maker's price (INV-4, INV-5, INV-6) ──
# A resting sell of 10 @ {100,0}; a crossing buy of 15 @ {101,0} -> a :fill at the
# MAKER's price {100,0} for 10, with a branded FIL id; the limit remainder (5)
# rests at {101,0}. After the fold: the sell is consumed, the buy remainder rests.
{g1_book, g1_sell} = G.rest_maker(OrderBook.new(), :sell, {100, 0}, 10, "acct-S")
{:place, g1_buy} = G.place(%{account: "acct-B", direction: :buy, quantity: 15, price: {101, 0}})
g1_events = Decider.decide({:place, g1_buy}, g1_book)
g1_next = G.fold(g1_events, g1_book)

g1 =
  case g1_events do
    [{:fill, f}, {:rested, r}] ->
      G.line(
        "G1 maker-price-fill",
        f.price == {100, 0} and f.quantity == 10 and f.taker == g1_buy.id and f.maker == g1_sell and
          byte_size(f.id) == 14 and BrandedId.valid?(f.id) and BrandedId.namespace(f.id) == "FIL" and
          r.order == g1_buy.id and r.side == :buy and r.price == {101, 0} and r.quantity == 5 and
          OrderBook.best(g1_next, :sell) == :empty and
          match?({{101, 0}, [{_, "acct-B", :buy, {101, 0}, 5}]}, OrderBook.best(g1_next, :buy)),
        "a crossing buy fills the resting sell at the MAKER's price {100,0} for 10 with a branded FIL id (14 bytes, valid?, ns FIL); the limit remainder (5) rests @ {101,0}; after the fold the sell is consumed and the buy remainder rests"
      )

    other ->
      G.line("G1 maker-price-fill", false, "expected [fill, rested], got #{inspect(other)}")
  end

# ── G2 -- price-time priority holds (INV-5) ───────────────────────────────────
# (a) two sells @ the SAME price -> the EARLIER mint fills first. (b) sells @
# {101,0} (minted first) then {100,0} (minted second) -> the BEST price (lowest
# ask {100,0}) fills first despite the later mint.
{g2a1, g2a_m1} = G.rest_maker(OrderBook.new(), :sell, {100, 0}, 5, "acct-S1")
{g2a2, _g2a_m2} = G.rest_maker(g2a1, :sell, {100, 0}, 5, "acct-S2")
{:place, g2a_buy} = G.place(%{account: "acct-B", direction: :buy, quantity: 5, price: {100, 0}})
[{:fill, g2af}] = Decider.decide({:place, g2a_buy}, g2a2)

{g2b1, _g2b_high} = G.rest_maker(OrderBook.new(), :sell, {101, 0}, 5, "acct-S1")
{g2b2, g2b_low} = G.rest_maker(g2b1, :sell, {100, 0}, 5, "acct-S2")
{:place, g2b_buy} = G.place(%{account: "acct-B", direction: :buy, quantity: 3, price: {101, 0}})
[{:fill, g2bf}] = Decider.decide({:place, g2b_buy}, g2b2)

g2 =
  G.line(
    "G2 price-time",
    g2af.maker == g2a_m1 and g2bf.maker == g2b_low and g2bf.price == {100, 0},
    "among makers at one price the earlier mint fills first (the ORD-id byte order is time priority); among prices the best fills first (a buy lifts the lowest ask {100,0} despite its later mint)"
  )

# ── G5 -- no float in any event or folded book (INV-6) ────────────────────────
# A matched run over fractional {units, nano} prices: no event field and no
# book-state value is a float (G.no_float? over the events AND the folded book).
{g5_book, _g5_sid} = G.rest_maker(OrderBook.new(), :sell, {100, 250_000_000}, 10, "acct-S")

{:place, g5_buy} =
  G.place(%{account: "acct-B", direction: :buy, quantity: 15, price: {101, 750_000_000}})

g5_events = Decider.decide({:place, g5_buy}, g5_book)
g5_folded = G.fold(g5_events, g5_book)

g5 =
  G.line(
    "G5 no-float",
    G.no_float?(g5_events) and G.no_float?(g5_folded),
    "no event field and no book-state value is a float across a matched run over fractional {units, nano} prices (structural scan over the events and the folded book; prices compared as the integer pair, never converted)"
  )

# ── G6 -- self-trade prevented (INV-6, D-2) ───────────────────────────────────
# A resting sell from acct-Z; a crossing buy from acct-Z -> exactly one :rejected
# :self_trade naming the taker, NO :fill, NO :rested, the book byte-unchanged. The
# all-or-nothing case: a non-self maker AHEAD of the self-cross is NOT filled.
{g6_book, _g6_sid} = G.rest_maker(OrderBook.new(), :sell, {100, 0}, 10, "acct-Z")
{:place, g6_buy} = G.place(%{account: "acct-Z", direction: :buy, quantity: 10, price: {101, 0}})
g6_events = Decider.decide({:place, g6_buy}, g6_book)

{g6b1, _g6_other} = G.rest_maker(OrderBook.new(), :sell, {100, 0}, 5, "acct-OTHER")
{g6b2, _g6_z} = G.rest_maker(g6b1, :sell, {101, 0}, 5, "acct-Z")
{:place, g6_buy2} = G.place(%{account: "acct-Z", direction: :buy, quantity: 10, price: {101, 0}})
g6_events2 = Decider.decide({:place, g6_buy2}, g6b2)

g6 =
  G.line(
    "G6 self-trade",
    g6_events == [{:rejected, %{order: g6_buy.id, reason: :self_trade}}] and
      G.fold(g6_events, g6_book) == g6_book and
      g6_events2 == [{:rejected, %{order: g6_buy2.id, reason: :self_trade}}] and
      G.fold(g6_events2, g6b2) == g6b2,
    "two same-account crossing orders do not self-fill -- the aggressor is rejected :self_trade (NO :fill, NO :rested) and the book is byte-unchanged (the fold leaves the input); all-or-nothing even with a non-self maker ahead of the self-cross"
  )

# ── AS-7 -- fill-key freeze (the Go-seam) ─────────────────────────────────────
# Over a self-contained seeded random sweep of crossing runs: every :fill carries
# a branded FIL id (ns "FIL", valid?, 14 bytes) and {units, nano} INTEGER money;
# no :fill is emitted without an id. The market-remainder fills also count.
:rand.seed(:exsss, {211, 222, 233})
pick = fn lo, hi -> lo + :rand.uniform(hi - lo + 1) - 1 end

as7 =
  Enum.reduce_while(1..2_000, {0, nil}, fn _, {ok, _} ->
    maker_price = pick.(90, 100)
    maker_qty = pick.(1, 50)
    taker_qty = pick.(1, 50)
    type = Enum.random([:limit, :market])
    {book, _sid} = G.rest_maker(OrderBook.new(), :sell, {maker_price, 0}, maker_qty, "acct-S")

    price = if type == :market, do: :market, else: {pick.(95, 110), 0}

    {:place, buy} =
      G.place(%{account: "acct-B", direction: :buy, type: type, quantity: taker_qty, price: price})

    fills = for {:fill, f} <- Decider.decide({:place, buy}, book), do: f

    bad =
      Enum.find(fills, fn f ->
        not (byte_size(f.id) == 14 and BrandedId.valid?(f.id) and
               BrandedId.namespace(f.id) == "FIL" and
               match?({u, n} when is_integer(u) and is_integer(n), f.price) and
               is_integer(f.quantity) and f.quantity > 0)
      end)

    if is_nil(bad), do: {:cont, {ok + 1, nil}}, else: {:halt, {ok, {:bad_fill, bad}}}
  end)

as7_ok =
  G.line(
    "AS-7 fill-key-freeze",
    elem(as7, 0) == 2_000,
    "across 2000 seeded crossing runs (limit + market) every :fill carries a branded FIL id (ns FIL, valid?, 14 bytes) and {units, nano} INTEGER money; no :fill is emitted without an id (the frozen Go-seam key set)"
  )

# ── AS-2 -- the forbidden-effect set is empty in decider.ex (pure-grep) ───────
# The grep is over CODE, not prose: strip line comments first (the
# trd_1_1_check.exs:250 strip_comments idiom). A `@moduledoc """..."""` is a
# STRING, not a `#` comment, so a forbidden token in the doc would SURVIVE
# stripping and fail here (L-1) -- the doc is worded to avoid the bare tokens.
# The FIL mint (next_branded) is the sole sanctioned effect.
strip_comments = fn src ->
  src |> String.split("\n") |> Enum.map_join("\n", &Regex.replace(~r/#.*/, &1, ""))
end

decider_code =
  Path.expand("../../apps/exchange/lib/exchange/decider.ex", __DIR__)
  |> File.read!()
  |> strip_comments.()

forbidden = ["GenServer", ":ets", "System.monotonic_time", "System.os_time", "Process."]
present = Enum.filter(forbidden, &String.contains?(decider_code, &1))

as2 =
  G.line(
    "AS-2 pure-grep",
    present == [] and String.contains?(decider_code, "next_branded"),
    "decider.ex (comments stripped) contains none of [GenServer, :ets, System.monotonic_time, System.os_time, Process.]; the FIL mint (next_branded) is the sole sanctioned effect -- pure modulo the mint (INV-3, D-5)"
  )

gates = [g1, g2, g5, g6, as7_ok, as2]

if Enum.all?(gates) do
  IO.puts("PASS #{Enum.count(gates)}/#{Enum.count(gates)}")
else
  IO.puts("FAIL")
  System.halt(1)
end
