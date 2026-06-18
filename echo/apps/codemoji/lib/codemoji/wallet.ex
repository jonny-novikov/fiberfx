defmodule Codemoji.Wallet do
  @moduledoc """
  The balances, mutated atomically. A player's keys, clips, and diamonds live in
  the `USR` component; this single writer serializes every mutation through its
  mailbox, checks the non-negative invariant before any deduction, and records a
  transaction for each change (`Codemoji.Ledger`). Paid rooms only ever touch
  keys, free rooms only clips — the two paths never cross. The mailbox is the lock,
  so concurrent guesses and a payout on one player cannot interleave a balance.

  (One writer is the simple, correct floor; it shards by player id when scale asks.)
  """
  use GenServer
  alias Codemoji.{Store, Ledger, Economy}

  @empty %{keys: 0, clips: 0, diamonds: 0, bonus_diamonds: 0, locked_diamonds: 0}

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok), do: {:ok, %{}}

  @doc "Create a player (`USR`) with an opening balance (`:keys`, `:clips`, `:diamonds`)."
  def create(name, opts \\ []) do
    uid = EchoData.BrandedId.generate!("USR")

    bal =
      Map.merge(@empty, %{
        keys: Keyword.get(opts, :keys, 0),
        clips: Keyword.get(opts, :clips, 0),
        diamonds: Keyword.get(opts, :diamonds, 0)
      })

    :ok = Store.put_player(uid, Map.put(bal, :name, name))
    {:ok, uid}
  end

  @doc "Charge a guess against the right currency for the round; refuse if short. `ref` is the round id."
  def charge_guess(player, round_map, ref),
    do: GenServer.call(__MODULE__, {:charge_guess, player, round_map, ref})

  @doc "Buy keys (paid externally via Telegram Stars); `ref` is the payment id."
  def purchase_keys(player, keys, ref),
    do: GenServer.call(__MODULE__, {:credit, player, :keys, keys, :purchase, ref})

  @doc "Deposit a diamond prize for a round win."
  def deposit_prize(player, diamonds, ref),
    do: GenServer.call(__MODULE__, {:credit, player, :diamonds, diamonds, :prize, ref})

  @doc "Grant a currency (bonus/admin)."
  def grant(player, currency, amount, reason \\ :grant),
    do: GenServer.call(__MODULE__, {:credit, player, currency, amount, reason, nil})

  @doc "Convert diamonds to keys at 10:1 (two cross-referenced transactions)."
  def convert_to_keys(player, diamonds), do: GenServer.call(__MODULE__, {:convert, player, diamonds})

  @doc "The player's balance, with the spendable figures (clips and locked diamonds set apart)."
  def balance(player) do
    case Store.player(player) do
      nil ->
        nil

      p ->
        Map.merge(p, %{
          available_keys: Map.get(p, :keys, 0),
          available_diamonds: Map.get(p, :diamonds, 0) - Map.get(p, :locked_diamonds, 0)
        })
    end
  end

  # --- callbacks (serialized; the mailbox is the lock) -------------------

  @impl true
  def handle_call({:charge_guess, player, r, ref}, _from, s) do
    {currency, cost} =
      if Map.get(r, :free, false),
        do: {:clips, Map.get(r, :clip_cost, 1)},
        else: {:keys, Map.get(r, :guess_fee, 1)}

    {:reply, debit(player, currency, cost, :guess, ref), s}
  end

  def handle_call({:credit, player, currency, amount, reason, ref}, _from, s),
    do: {:reply, credit(player, currency, amount, reason, ref), s}

  def handle_call({:convert, player, diamonds}, _from, s) do
    case Store.player(player) do
      nil ->
        {:reply, {:error, :no_player}, s}

      p ->
        avail = Map.get(p, :diamonds, 0) - Map.get(p, :locked_diamonds, 0)

        cond do
          diamonds <= 0 or rem(diamonds, Economy.diamonds_per_key()) != 0 ->
            {:reply, {:error, :bad_amount}, s}

          avail < diamonds ->
            {:reply, {:error, :insufficient}, s}

          true ->
            keys = Economy.keys_from_diamonds(diamonds)
            updated = %{p | diamonds: p.diamonds - diamonds, keys: Map.get(p, :keys, 0) + keys}
            :ok = Store.put_player(player, updated)
            # two records, cross-referenced: the diamond debit, then the key credit
            dref = Ledger.record(player, :diamonds, -diamonds, :convert, nil)
            _ = Ledger.record(player, :keys, keys, :convert, dref)
            {:reply, {:ok, %{keys: updated.keys, diamonds: updated.diamonds}}, s}
        end
    end
  end

  # non-negative invariant + a transaction, inside the serialized call
  defp debit(player, currency, amount, reason, ref) do
    case Store.player(player) do
      nil ->
        {:error, :no_player}

      p ->
        have = Map.get(p, currency, 0)

        if have < amount do
          {:error, :insufficient}
        else
          :ok = Store.put_player(player, Map.put(p, currency, have - amount))
          Ledger.record(player, currency, -amount, reason, ref)
          {:ok, have - amount}
        end
    end
  end

  defp credit(player, currency, amount, reason, ref) when amount >= 0 do
    case Store.player(player) do
      nil ->
        {:error, :no_player}

      p ->
        have = Map.get(p, currency, 0)
        :ok = Store.put_player(player, Map.put(p, currency, have + amount))
        Ledger.record(player, currency, amount, reason, ref)
        {:ok, have + amount}
    end
  end

  defp credit(_player, _currency, _amount, _reason, _ref), do: {:error, :bad_amount}
end
