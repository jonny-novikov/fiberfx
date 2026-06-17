defmodule Exchange.Gateway do
  @moduledoc """
  The Exchange Gateway — the parse-don't-validate door (rung TRD.1.1,
  `docs/exchange/trd.1.1.specs.md`).

  One stateless module turns untrusted `map()` input into either a typed
  `t:command/0` or one member of the closed six-atom `t:error/0` set, minting a
  branded `CMD`/`ORD` id through the canon at the instant of acceptance. No
  exception escapes; no partially-built command is ever returned; there is no
  third outcome (INV-1). Price is `{units, nano}` integers from the first byte
  parsed — no float appears in any Gateway type or output (INV-2).

  The `t:order_type/0` and `t:command/0` types are authored **wide** — they name
  `:bestprice` and the `{:replace, …}` constructor so the type is the full
  vocabulary the platform speaks — but the parsers in THIS slice produce only the
  in-scope subset `:limit | :market` and the `:place`/`:cancel` kinds. A
  `:bestprice` order_type resolves to `{:error, :bad_order_type}` and a replace
  request to `{:error, :malformed}` until rung TRD.1.2 wires the parser. This
  keeps the type stable across the 1.1→1.2 boundary while the parser surface
  grows.

  Stateless boundary (INV-5): no process, no ETS, no store handle, no
  application-env config, no new external dependency. A pure function plus a
  minting effect — the same input (modulo the minted id) parses identically every
  time.
  """

  # ── The command vocabulary (closed; the type is wide, the 1.1 parsers are the
  #    subset). trd.1.1.specs.md §77-96. ────────────────────────────────────────

  @typedoc "Order side. ORDER_DIRECTION_BUY | _SELL."
  @type direction :: :buy | :sell

  @typedoc """
  Order type. ORDER_TYPE_LIMIT | _MARKET | _BESTPRICE. The type names all three;
  the TRD.1.1 parsers produce `:limit | :market` only (`:bestprice` is TRD.1.2).
  """
  @type order_type :: :limit | :market | :bestprice

  @typedoc "Quotation money — never a float. `units` whole, `nano` billionths."
  @type money :: {units :: integer(), nano :: integer()}

  @typedoc """
  A parsed command. The `{:replace, …}` constructor exists in the type but has no
  TRD.1.1 parser (it resolves to `{:error, :malformed}` until TRD.1.2).
  """
  @type command ::
          {:place,
           %{
             id: binary(),
             instrument: binary(),
             account: binary(),
             direction: direction(),
             type: order_type(),
             quantity: pos_integer(),
             price: money() | :market
           }}
          | {:cancel, %{id: binary(), instrument: binary(), order_ref: binary()}}
          | {:replace,
             %{
               id: binary(),
               instrument: binary(),
               order_ref: binary(),
               quantity: pos_integer(),
               price: money()
             }}

  @typedoc "The closed expected-failure set — the ONLY failure channel (INV-1)."
  @type error ::
          :unknown_instrument
          | :bad_direction
          | :bad_order_type
          | :nonpositive_quantity
          | :bad_price
          | :malformed

  # ── Public command parsers (trd.1.1.specs.md §103-117) ──────────────────────

  @doc """
  Parses an untrusted place order (limit **and** market) into
  `{:ok, {:place, command_map}}` or one closed `t:error/0`, minting `CMD`/`ORD`
  ids on success only (INV-3). A market order carries `price: :market` regardless
  of any price field present (G4); a limit order requires a parsed `t:money/0`.

  Precondition — `raw` is a map (any other input → `{:error, :malformed}`, never
  a crash). Postcondition — exactly one of `{:ok, command()}` or
  `{:error, error()}`. Invariant — the minting effect lives inside the `{:ok, …}`
  branch only; a rejection mints nothing.
  """
  @spec parse_place(raw :: map()) :: {:ok, command()} | {:error, error()}
  def parse_place(raw) when is_map(raw) do
    with {:ok, instrument} <- parse_instrument(Map.get(raw, :instrument)),
         {:ok, account} <- parse_account(Map.get(raw, :account)),
         {:ok, direction} <- parse_direction(Map.get(raw, :direction)),
         {:ok, type} <- parse_order_type(Map.get(raw, :type)),
         {:ok, quantity} <- parse_quantity(Map.get(raw, :quantity)),
         {:ok, price} <- parse_place_price(type, Map.get(raw, :price)) do
      # INV-3: mint at acceptance, inside the success branch only. CMD for the
      # command identity, ORD for the order. Snowflake.next_branded/1
      # (echo/apps/echo_data/lib/echo_data/snowflake.ex:104).
      {:ok,
       {:place,
        %{
          id: EchoData.Snowflake.next_branded("ORD"),
          instrument: instrument,
          account: account,
          direction: direction,
          type: type,
          quantity: quantity,
          price: price
        }}}
    end
  end

  def parse_place(_), do: {:error, :malformed}

  @doc """
  Parses an untrusted cancel into `{:ok, {:cancel, command_map}}` or one closed
  `t:error/0`. Carries the opaque `order_ref` and `instrument` verbatim (INV-4),
  minting a `CMD` id on success only (INV-3). Same precondition / postcondition /
  invariant as `parse_place/1`.
  """
  @spec parse_cancel(raw :: map()) :: {:ok, command()} | {:error, error()}
  def parse_cancel(raw) when is_map(raw) do
    with {:ok, instrument} <- parse_instrument(Map.get(raw, :instrument)),
         {:ok, order_ref} <- parse_order_ref(Map.get(raw, :order_ref)) do
      {:ok,
       {:cancel,
        %{
          id: EchoData.Snowflake.next_branded("CMD"),
          instrument: instrument,
          order_ref: order_ref
        }}}
    end
  end

  def parse_cancel(_), do: {:error, :malformed}

  # ── Field parsers (trd.1.1.specs.md §110-116) — each total into its slice of
  #    the closed error set. ─────────────────────────────────────────────────────

  @doc """
  Parses a Quotation into `{:ok, {units, nano}}` (both integers) or
  `{:error, :bad_price}`. Accepts an integer-pair `{units, nano}` or a
  `"units.nano"`-style decimal string; any other input — including any
  float-bearing value — is `{:error, :bad_price}` (INV-2). No rounding, scaling,
  or normalization at the door.
  """
  @spec parse_money(term()) :: {:ok, money()} | {:error, :bad_price}
  def parse_money({units, nano}) when is_integer(units) and is_integer(nano) do
    {:ok, {units, nano}}
  end

  def parse_money(raw) when is_binary(raw) do
    # The string grammar: "units" or "units.nano" — each side an integer string.
    # A nano fraction is right-padded to 9 digits (billionths). Anything that does
    # not parse to two integers — a float-shaped extra dot, a sign-only token,
    # non-digit bytes — is :bad_price.
    case String.split(raw, ".", parts: 2) do
      [units_s] ->
        with {:ok, units} <- parse_integer_string(units_s), do: {:ok, {units, 0}}

      [units_s, nano_s] ->
        with {:ok, units} <- parse_integer_string(units_s),
             {:ok, nano} <- parse_nano_string(nano_s, units_s) do
          {:ok, {units, nano}}
        end
    end
  end

  def parse_money(_), do: {:error, :bad_price}

  @doc "Maps `:buy`/`:sell` (atom or the venue string forms) to the atom, else `{:error, :bad_direction}`."
  @spec parse_direction(term()) :: {:ok, direction()} | {:error, :bad_direction}
  def parse_direction(:buy), do: {:ok, :buy}
  def parse_direction(:sell), do: {:ok, :sell}
  def parse_direction("ORDER_DIRECTION_BUY"), do: {:ok, :buy}
  def parse_direction("ORDER_DIRECTION_SELL"), do: {:ok, :sell}
  def parse_direction("buy"), do: {:ok, :buy}
  def parse_direction("sell"), do: {:ok, :sell}
  def parse_direction(_), do: {:error, :bad_direction}

  @doc """
  Maps `:limit`/`:market` (atom or the venue `ORDER_TYPE_*` string forms) to the
  atom. `:bestprice` / any unknown → `{:error, :bad_order_type}` in this slice
  (the parser for `:bestprice` is TRD.1.2; the type names it now).
  """
  @spec parse_order_type(term()) :: {:ok, order_type()} | {:error, :bad_order_type}
  def parse_order_type(:limit), do: {:ok, :limit}
  def parse_order_type(:market), do: {:ok, :market}
  def parse_order_type("ORDER_TYPE_LIMIT"), do: {:ok, :limit}
  def parse_order_type("ORDER_TYPE_MARKET"), do: {:ok, :market}
  def parse_order_type("limit"), do: {:ok, :limit}
  def parse_order_type("market"), do: {:ok, :market}
  def parse_order_type(_), do: {:error, :bad_order_type}

  @doc "Parses strictly-positive lots into `{:ok, pos_integer()}`, else `{:error, :nonpositive_quantity}`."
  @spec parse_quantity(term()) :: {:ok, pos_integer()} | {:error, :nonpositive_quantity}
  def parse_quantity(q) when is_integer(q) and q > 0, do: {:ok, q}
  def parse_quantity(_), do: {:error, :nonpositive_quantity}

  @doc "Presence-and-shape of the opaque instrument id (INV-4 — carried verbatim, never branded)."
  @spec parse_instrument(term()) :: {:ok, binary()} | {:error, :unknown_instrument}
  def parse_instrument(s) when is_binary(s) and byte_size(s) > 0, do: {:ok, s}
  def parse_instrument(_), do: {:error, :unknown_instrument}

  @doc """
  Presence-and-shape of the opaque account id (INV-4). Its failure folds into
  `:malformed` — the closed set has no dedicated account atom (a presence failure
  is a malformed command, not a distinct error class).
  """
  @spec parse_account(term()) :: {:ok, binary()} | {:error, :malformed}
  def parse_account(s) when is_binary(s) and byte_size(s) > 0, do: {:ok, s}
  def parse_account(_), do: {:error, :malformed}

  # ── Private helpers ─────────────────────────────────────────────────────────

  # A market order ignores any price field and carries `price: :market` (G4); a
  # limit order requires a parsed money(). `:bestprice` never reaches here (its
  # parse_order_type/1 head rejects it as :bad_order_type in this slice).
  @spec parse_place_price(order_type(), term()) :: {:ok, money() | :market} | {:error, :bad_price}
  defp parse_place_price(:market, _price), do: {:ok, :market}
  defp parse_place_price(:limit, price), do: parse_money(price)

  # The opaque order reference of a cancel/replace — present, non-empty, carried
  # verbatim (INV-4). A missing/blank/non-string ref is an unclassifiable cancel
  # → :malformed (the closed set has no order_ref atom).
  @spec parse_order_ref(term()) :: {:ok, binary()} | {:error, :malformed}
  defp parse_order_ref(s) when is_binary(s) and byte_size(s) > 0, do: {:ok, s}
  defp parse_order_ref(_), do: {:error, :malformed}

  # A signed integer string with at least one digit and no other bytes.
  # Integer.parse/1 alone would accept a "12abc" prefix, so the remainder must be
  # empty. This rejects float-shaped "12.5" callers route through parse_money/1.
  @spec parse_integer_string(binary()) :: {:ok, integer()} | {:error, :bad_price}
  defp parse_integer_string(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, ""} -> {:ok, n}
      _ -> {:error, :bad_price}
    end
  end

  # The nano fraction: digits only (no sign — the units side carries the sign),
  # right-padded to 9 billionths, capped at 9 significant digits. "5" → 500_000_000.
  # An empty or non-digit fraction is :bad_price. The nano inherits the units sign
  # so a negative price below 1 unit is representable.
  @spec parse_nano_string(binary(), binary()) :: {:ok, integer()} | {:error, :bad_price}
  defp parse_nano_string(nano_s, units_s)
       when is_binary(nano_s) and byte_size(nano_s) > 0 and byte_size(nano_s) <= 9 do
    if String.match?(nano_s, ~r/\A[0-9]+\z/) do
      magnitude = String.to_integer(String.pad_trailing(nano_s, 9, "0"))
      {:ok, signed_nano(magnitude, units_s)}
    else
      {:error, :bad_price}
    end
  end

  defp parse_nano_string(_, _), do: {:error, :bad_price}

  # The nano takes the units sign. A leading "-" on the units string (including
  # "-0") makes a sub-unit price negative.
  defp signed_nano(magnitude, units_s) do
    if String.starts_with?(units_s, "-"), do: -magnitude, else: magnitude
  end
end
