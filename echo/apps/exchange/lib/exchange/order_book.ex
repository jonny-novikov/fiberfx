defmodule Exchange.OrderBook do
  @moduledoc """
  The pure price-time ladder (rung TRD.2.1, `docs/exchange/trd.2.1.specs.md`).

  One book holds two sides, each an ordered price ladder: a `:gb_trees` keyed by
  `t:money/0` price, every level a FIFO of resting orders in branded mint order.
  Price priority is the tree's key order (Erlang term order over `{units, nano}`
  integer pairs — never a float comparison, INV-6); time priority within a level
  is the FIFO order, which is mint order because the resting `id` is the
  Gateway's branded `ORD` stamp and that id byte-sorts in mint order (the
  Appendix-F order theorem, INV-5). The ladder therefore needs no clock and no
  comparator beyond the id byte order.

  Fully pure (INV-3): no process, no store, no clock, no mint, no IO — `new/0`
  builds the empty book and `best/2` reads the top of a side. The matching rules
  and the single sanctioned `FIL` mint live in `Exchange.Decider`, never here.
  `evolve/2` mutation of the ladder (insert a resting order, consume a filled
  one) is the Decider's fold; this module supplies the structure and the read.

  The per-account `EchoData.BrandedTree` index a stateful book needs for cancel
  and pagination is TRD.2.2, not this rung; this slice carries only `new/0` and
  `best/2`.
  """

  # ── The ladder types (the concrete representation is this module's call; the
  #    contract is the public arities + the resting/money shapes, trd.2.1.specs.md
  #    §115-139). ────────────────────────────────────────────────────────────────

  @typedoc "Quotation money — `{units, nano}` integers, never a float (INV-6)."
  @type money :: {units :: integer(), nano :: integer()}

  @typedoc "Order side. A buy rests on the bids; a sell rests on the asks."
  @type side :: :buy | :sell

  @typedoc """
  A resting order. Carries at least `{id, account, side, price, quantity}`; the
  `account` is REQUIRED — the Decider detects a same-account cross against this
  maker (self-trade, D-2/G6), and the maker's account is knowable only if the
  ladder holds it. `id` is the maker's branded `ORD` id (its byte order is the
  level's time priority).
  """
  @type resting :: {
          id :: binary(),
          account :: binary(),
          side :: side(),
          price :: money(),
          quantity :: pos_integer()
        }

  @typedoc """
  The book: one price ladder per side. Each ladder is a `:gb_trees` keyed by
  `t:money/0` price; the value at a price is the level's FIFO — a list of
  `t:resting/0` in mint order, head = earliest mint.
  """
  @type book_state :: %__MODULE__{
          buy: :gb_trees.tree(money(), [resting()]),
          sell: :gb_trees.tree(money(), [resting()])
        }

  @enforce_keys [:buy, :sell]
  defstruct [:buy, :sell]

  @doc """
  The empty book — an empty ladder on each side.

  Postcondition — `best/2` reads `:empty` on both sides of the result.
  """
  @spec new() :: book_state()
  def new do
    %__MODULE__{buy: :gb_trees.empty(), sell: :gb_trees.empty()}
  end

  @doc """
  Reads the top of a side: the best price and that price level's FIFO (in mint
  order, earliest first), or `:empty` when the side holds no resting order.

  The best of the **buy** side is the HIGHEST price (the best bid an aggressor
  sell lifts); the best of the **sell** side is the LOWEST price (the best ask an
  aggressor buy lifts). Both are an O(log n) read of the ladder's extreme key via
  `:gb_trees.largest/1` / `:gb_trees.smallest/1`.

  A pure read (INV-3): no mint, no effect.
  """
  # INV-5: price priority is the tree key order; the level FIFO is mint order. The
  # buy ladder's best is its largest key (highest bid); the sell ladder's best is
  # its smallest key (lowest ask).
  @spec best(book_state(), side()) :: {money(), [resting()]} | :empty
  def best(%__MODULE__{buy: buy}, :buy), do: extreme(buy, :largest)
  def best(%__MODULE__{sell: sell}, :sell), do: extreme(sell, :smallest)

  # The extreme of a ladder, or :empty. `:gb_trees.largest/1`/`:gb_trees.smallest/1`
  # raise on an empty tree, so the size guard answers :empty first. The tree
  # orders by Erlang term order over the {units, nano} integer pair — correct
  # price order without any float conversion (trd.2.1.specs.md §193-195).
  @spec extreme(:gb_trees.tree(money(), [resting()]), :largest | :smallest) ::
          {money(), [resting()]} | :empty
  defp extreme(tree, which) do
    if :gb_trees.is_empty(tree) do
      :empty
    else
      apply(:gb_trees, which, [tree])
    end
  end
end
