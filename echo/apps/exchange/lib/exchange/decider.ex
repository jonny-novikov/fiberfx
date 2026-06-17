defmodule Exchange.Decider do
  @moduledoc """
  The matching rule as a pure function over events (rung TRD.2.1,
  `docs/exchange/trd.2.1.specs.md`).

  `decide/2` takes the typed `{:place, …}` command (limit and market) and an
  `Exchange.OrderBook` state and returns the facts the command produces — a list
  of `:fill` events (one per maker consumed, each at the maker's price), an
  optional `:rested` (a limit remainder), or a single `:rejected` (a self-cross,
  or a market remainder with no liquidity). `evolve/2` folds ONE event back into
  the book, and the book's state is exactly the fold of `evolve` over the events
  `decide` has emitted, in mint order (INV-4) — there is no state reachable except
  through the fold.

  Pure modulo a single sanctioned effect (INV-3): the branded `FIL` id minted
  inside `decide` at the instant a `:fill` is constructed, via
  `EchoData.Snowflake.next_branded/1` (the same id-effect the Gateway is granted
  at TRD.1.1). `evolve` mints nothing. The forbidden-effect set is empty in this
  module — no server behaviour, no in-memory table, no monotonic or wall clock,
  no process-dictionary state — the `FIL` mint is the sole effect (AS-2; the
  source, comments stripped, holds none of those tokens). All matching rules live
  only here; the single-writer server that will drive this Decider is TRD.2.2.

  Price-time priority is not coded: it falls out of the ladder. An aggressor
  crosses the opposite side in price-time order (best price first; within a
  price, earliest mint order first), reading the top with
  `Exchange.OrderBook.best/2`. No clock breaks a tie — the maker's existing mint
  order does (INV-5).

  ## The `:rested` account (realization over the `@type` literal, D-1)

  The book's resting tuple carries `account` (the surface, §124) because
  self-trade detection reads it (§158, rule D-2). The book is the EXTERNAL fold
  of `evolve` over emitted events (INV-4), so `evolve/2` of a `:rested` must
  populate that account — yet the spec's `@type event` literal (§101) omits it,
  which the external fold cannot recover from the `order` id. The `:rested` event
  here therefore carries `account` (only `:fill` is key-frozen, AS-7 §220); the
  `:fill` and `:rejected` shapes are unchanged (the frozen Go-seam contract).
  """

  alias Exchange.OrderBook

  # ── The event vocabulary (the Decider's output — trd.2.1.specs.md §93-106) ───

  @typedoc "Quotation money — `{units, nano}` integers, never a float (INV-6)."
  @type money :: {integer(), integer()}

  @typedoc "Order side. A buy lifts the asks; a sell hits the bids."
  @type side :: :buy | :sell

  @typedoc """
  The typed place command this rung consumes (TRD.1.1, as-built —
  `gateway.ex:47-57`). A limit place arrives with `price: {units, nano}`; a
  market place with `price: :market`. `id` is the aggressor's branded `ORD` id
  and the time component of price-time priority; `account` is the self-trade key.
  This rung matches `:place` only (`:cancel`/`:replace` are TRD.1.2/TRD.2.2).
  """
  @type command ::
          {:place,
           %{
             id: binary(),
             instrument: binary(),
             account: binary(),
             direction: side(),
             type: :limit | :market,
             quantity: pos_integer(),
             price: money() | :market
           }}

  @typedoc """
  A fact `decide/2` emits.

    * `:fill` carries BOTH order ids — `taker` (the aggressor's `ORD` id) and
      `maker` (the resting order's id) — at the maker's resting `price`; `id` is
      the `FIL` id minted at the fill (the frozen Go-seam key set, AS-7).
    * `:rested` is the unfilled remainder of a LIMIT order at its limit price;
      `order` is its id and `account` its placing account (carried for the fold's
      self-trade detection, D-1 — a widening of the `@type` literal §101).
    * `:rejected` carries one member of the closed `t:reject_reason/0` set.
  """
  @type event ::
          {:fill,
           %{
             taker: binary(),
             maker: binary(),
             instrument: binary(),
             price: money(),
             quantity: pos_integer(),
             id: binary()
           }}
          | {:rested,
             %{
               order: binary(),
               account: binary(),
               instrument: binary(),
               side: side(),
               price: money(),
               quantity: pos_integer()
             }}
          | {:rejected, %{order: binary(), reason: reject_reason()}}

  @typedoc "The closed reject-reason set — no other reason atom this rung (D-3)."
  @type reject_reason :: :self_trade | :no_liquidity

  # ── decide/2 — the matching rule, pure modulo the FIL mint ───────────────────

  @doc """
  Matches a `{:place, …}` command against the book, returning the events it
  produces (`decide(command, book) :: [event()]`). Pure modulo the `FIL` mint
  inside each `:fill` (INV-3); never mutates the book — the caller folds the
  events with `evolve/2`.

  An aggressor crosses the opposite side in price-time order, emitting one
  `:fill` per maker consumed at the MAKER's price (D-6). A LIMIT remainder rests
  at its limit price (D-4); a MARKET remainder rejects `:no_liquidity` (D-4). A
  cross that would consume a SAME-account maker rejects the whole aggressor
  `:self_trade`, book unchanged (D-2, all-or-nothing). The reason set is closed
  (D-3); no float appears in any event (INV-6).

  Precondition — `command` is a `{:place, map}` with the TRD.1.1 fields.
  Postcondition — a non-empty `[event()]`: zero-or-more `:fill`s then at most one
  `:rested`, OR exactly one `:rejected`. Total over `:place` — never crashes,
  never returns a partial or un-tagged result.
  """
  @spec decide(command(), OrderBook.book_state()) :: [event()]
  def decide({:place, order}, %OrderBook{} = book) do
    # The opposite side an aggressor consumes: a buy lifts the asks (:sell), a
    # sell hits the bids (:buy). D-6 / G1: cross the opposite side in price-time.
    opposite = opposite_side(order.direction)

    # D-2 / G6: a same-account cross is all-or-nothing — walk first WITHOUT
    # committing; if any maker the aggressor would reach shares its account,
    # reject the whole aggressor and leave the book unchanged. Otherwise the walk
    # returns the fills + the unfilled remainder.
    case walk(order, book, opposite, []) do
      :self_trade ->
        # D-2: reject the aggressor in full; NO :fill, NO :rested.
        [{:rejected, %{order: order.id, reason: :self_trade}}]

      {fills, 0} ->
        # Fully filled — no remainder to rest or reject (D-6).
        fills

      {fills, remaining} when remaining > 0 ->
        # D-4: a limit remainder rests; a market remainder rejects :no_liquidity.
        fills ++ remainder_event(order, remaining)
    end
  end

  # The recursive price-time walk. Reads the best of the opposite side; if the
  # aggressor crosses it, consumes the FIFO at that price maker by maker (earliest
  # mint first, INV-5), accumulating one :fill per maker at the MAKER's price
  # (D-6). Stops when the aggressor is exhausted, the price no longer crosses, or
  # the side is empty. Returns {fills_in_order, remaining_quantity}, or :self_trade
  # the instant the next maker to consume shares the aggressor's account (D-2).
  @spec walk(map(), OrderBook.book_state(), side(), [event()]) ::
          {[event()], non_neg_integer()} | :self_trade
  defp walk(%{quantity: 0}, _book, _opposite, acc) do
    {Enum.reverse(acc), 0}
  end

  defp walk(order, book, opposite, acc) do
    case OrderBook.best(book, opposite) do
      :empty ->
        {Enum.reverse(acc), order.quantity}

      {maker_price, [maker | _]} ->
        if crosses?(order, maker_price) do
          consume(order, book, opposite, maker_price, maker, acc)
        else
          # The best opposite price no longer crosses — the limit price is
          # exhausted (a market order always crosses, so it only reaches here
          # when the side is empty, handled above).
          {Enum.reverse(acc), order.quantity}
        end
    end
  end

  # Consume one maker (the FIFO head at the crossing price). D-2: a same-account
  # maker aborts the whole walk before any commit. Otherwise emit one :fill at the
  # maker's price for min(maker, taker), mint its FIL, evolve the maker out of the
  # book, and recurse on the decremented aggressor.
  @spec consume(map(), OrderBook.book_state(), side(), money(), OrderBook.resting(), [event()]) ::
          {[event()], non_neg_integer()} | :self_trade
  defp consume(order, book, opposite, maker_price, maker, acc) do
    {maker_id, maker_account, _maker_side, _maker_price, maker_qty} = maker

    if maker_account == order.account do
      # D-2 / G6: self-cross — abandon the whole accumulation, book unchanged.
      :self_trade
    else
      qty = min(maker_qty, order.quantity)

      # D-5 / G1: mint the FIL inside the fill construction — the sole effect.
      # Snowflake.next_branded/1 (echo/apps/echo_data/lib/echo_data/snowflake.ex:104).
      # D-6: price is the MAKER's resting price.
      fill =
        {:fill,
         %{
           taker: order.id,
           maker: maker_id,
           instrument: order.instrument,
           price: maker_price,
           quantity: qty,
           id: EchoData.Snowflake.next_branded("FIL")
         }}

      book = evolve(book, fill)
      walk(%{order | quantity: order.quantity - qty}, book, opposite, [fill | acc])
    end
  end

  # D-4: the unfilled remainder. A LIMIT order rests at its limit price (becoming
  # a maker); a MARKET order cannot rest (it is unpriced — no ladder key) so its
  # remainder rejects :no_liquidity. The :rested carries the placing account (D-1)
  # so the fold can detect a later self-cross against it.
  @spec remainder_event(map(), pos_integer()) :: [event()]
  defp remainder_event(%{type: :limit, price: {_u, _n} = price} = order, remaining) do
    [
      {:rested,
       %{
         order: order.id,
         account: order.account,
         instrument: order.instrument,
         side: order.direction,
         price: price,
         quantity: remaining
       }}
    ]
  end

  defp remainder_event(%{type: :market} = order, _remaining) do
    [{:rejected, %{order: order.id, reason: :no_liquidity}}]
  end

  # ── evolve/2 — fold one event into the book (INV-4) ──────────────────────────

  @doc """
  Folds ONE event into the book (`evolve(book, event) :: book`). A `:rested`
  inserts the order onto its side's ladder at its price (appended to the level
  FIFO in mint order); a `:fill` consumes the matched quantity from the maker at
  the head of the crossed price level (removing the maker when its remainder hits
  zero); a `:rejected` leaves the book unchanged (the aggressor never entered).

  The book's state is exactly the fold of `evolve` over the events `decide`
  emitted, in mint order (INV-4); there is no state reachable except through the
  fold. Pure — mints nothing, reads no clock (INV-3).
  """
  @spec evolve(OrderBook.book_state(), event()) :: OrderBook.book_state()
  def evolve(%OrderBook{} = book, {:rested, r}) do
    # INV-4: a limit remainder becomes a resting maker on its side at its price,
    # appended to the level FIFO so mint order (INV-5) is preserved. The account
    # rides the event (D-1) so the resting tuple carries it for self-trade
    # detection (§158).
    entry = {r.order, r.account, r.side, r.price, r.quantity}
    ladder_put(book, r.side, r.price, entry)
  end

  def evolve(%OrderBook{} = book, {:fill, f}) do
    # INV-4: a fill consumes `quantity` from the maker at the head of the crossed
    # price level. The fill names the maker id but not its side; the maker is the
    # FIFO head at `f.price` on exactly one side (the price-time walk, and the
    # fold in mint order, consume heads in order), so the maker side is the side
    # whose head at `f.price` is `f.maker`.
    side = maker_side(book, f)
    ladder_consume(book, side, f.price, f.quantity)
  end

  def evolve(%OrderBook{} = book, {:rejected, _}) do
    # D-2 / D-4: a rejection records no book change — the aggressor never rested.
    book
  end

  # ── private: side + price-cross algebra ──────────────────────────────────────

  @spec opposite_side(side()) :: side()
  defp opposite_side(:buy), do: :sell
  defp opposite_side(:sell), do: :buy

  # Whether the aggressor crosses a maker at `maker_price`. A MARKET order is
  # unpriced and crosses any available price. A LIMIT BUY crosses when it will pay
  # at least the ask (`limit >= maker`); a LIMIT SELL crosses when it will accept
  # at most the bid (`limit <= maker`). Comparison is over the {units, nano}
  # integer pair (Erlang term order), never a float (INV-6).
  @spec crosses?(map(), money()) :: boolean()
  defp crosses?(%{type: :market}, _maker_price), do: true

  defp crosses?(%{type: :limit, direction: :buy, price: limit}, maker_price),
    do: limit >= maker_price

  defp crosses?(%{type: :limit, direction: :sell, price: limit}, maker_price),
    do: limit <= maker_price

  # The side a fill's maker rests on: the side whose FIFO head at `f.price` is
  # `f.maker`. Exactly one side carries that maker at fold time (the maker is the
  # head being consumed this step).
  @spec maker_side(OrderBook.book_state(), map()) :: side()
  defp maker_side(book, f) do
    if head_id_at(book, :sell, f.price) == f.maker, do: :sell, else: :buy
  end

  defp head_id_at(book, side, price) do
    case level_at(side_tree(book, side), price) do
      [{id, _a, _s, _p, _q} | _] -> id
      [] -> nil
    end
  end

  # ── private: ladder mutation (used only by evolve/2) ─────────────────────────

  # Insert a resting entry onto a side's ladder, appended to its price level FIFO
  # (mint order preserved). `:gb_trees` holds one value per key; the value is the
  # level list.
  @spec ladder_put(OrderBook.book_state(), side(), money(), OrderBook.resting()) ::
          OrderBook.book_state()
  defp ladder_put(book, side, price, entry) do
    tree = side_tree(book, side)
    level = level_at(tree, price)
    tree = enter(tree, price, level ++ [entry])
    put_side(book, side, tree)
  end

  # Consume `qty` from the head maker of a price level. Drop the maker when its
  # remainder is zero; drop the whole level when its FIFO empties.
  @spec ladder_consume(OrderBook.book_state(), side(), money(), pos_integer()) ::
          OrderBook.book_state()
  defp ladder_consume(book, side, price, qty) do
    tree = side_tree(book, side)

    case level_at(tree, price) do
      [{id, acct, mside, mprice, mqty} | rest] ->
        remaining = mqty - qty

        new_level =
          if remaining > 0, do: [{id, acct, mside, mprice, remaining} | rest], else: rest

        tree = if new_level == [], do: drop(tree, price), else: enter(tree, price, new_level)
        put_side(book, side, tree)

      [] ->
        book
    end
  end

  # ── private: gb_trees plumbing (insert-or-update one key) ─────────────────────

  defp side_tree(%OrderBook{buy: buy}, :buy), do: buy
  defp side_tree(%OrderBook{sell: sell}, :sell), do: sell

  defp put_side(book, :buy, tree), do: %{book | buy: tree}
  defp put_side(book, :sell, tree), do: %{book | sell: tree}

  defp level_at(tree, price) do
    case :gb_trees.lookup(price, tree) do
      {:value, level} -> level
      :none -> []
    end
  end

  # Insert a new key or update an existing one (`:gb_trees.insert/3` raises on a
  # duplicate key; `enter/3` is insert-or-update).
  defp enter(tree, price, level), do: :gb_trees.enter(price, level, tree)

  defp drop(tree, price), do: :gb_trees.delete(price, tree)
end
