defmodule Codemoji.Ledger do
  @moduledoc """
  The transaction record. Every balance mutation writes one `TXN` component
  (`%{player, currency, delta, reason, ref, at_ms}`) and pushes its id onto the
  player's history list in Valkey, so a player's statement is an ordered read and
  no balance changes without a paired record. A conversion writes two — a diamond
  debit and a key credit — whose `ref`s cross-reference each other.
  """
  alias EchoMQ.Connector
  alias Codemoji.{Bus, Store}

  @doc "Record one mutation; returns the `TXN` id."
  def record(player, currency, delta, reason, ref \\ nil) do
    tid = EchoData.BrandedId.generate!("TXN")

    txn = %{
      player: player,
      currency: currency,
      delta: delta,
      reason: reason,
      ref: ref,
      at_ms: System.system_time(:millisecond)
    }

    :ok = Store.put_txn(tid, txn)
    Connector.command(Bus.conn(), ["LPUSH", hist_key(player), tid])
    tid
  end

  @doc "The player's recent transactions, newest first."
  def history(player, n \\ 50) do
    case Connector.command(Bus.conn(), ["LRANGE", hist_key(player), "0", to_string(n - 1)]) do
      {:ok, ids} when is_list(ids) -> ids |> Enum.map(&Store.txn/1) |> Enum.reject(&is_nil/1)
      _ -> []
    end
  end

  defp hist_key(player), do: "cm:txn:" <> player
end
