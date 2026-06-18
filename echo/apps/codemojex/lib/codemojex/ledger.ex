defmodule Codemojex.Ledger do
  @moduledoc """
  The transaction ledger, read from Postgres. Every balance change is a durable,
  append-only row, written by `Codemojex.Wallet` inside the same database
  transaction as the balance update — so a statement is an ordered query and no
  balance ever moved without a paired record.
  """
  import Ecto.Query
  alias Codemojex.Repo
  alias Codemojex.Schemas.Transaction

  @doc "The player's transactions, newest first."
  def history(player, n \\ 50) do
    Repo.all(
      from t in Transaction,
        where: t.player == ^player,
        order_by: [desc: t.inserted_at],
        limit: ^n
    )
    |> Enum.map(&(&1 |> Map.from_struct() |> Map.drop([:__meta__])))
  end
end
