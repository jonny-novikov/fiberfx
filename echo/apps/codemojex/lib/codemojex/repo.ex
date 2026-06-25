defmodule Codemojex.Repo do
  @moduledoc """
  The relational system of record. Crucial data — balances, the transaction
  ledger, games (with their secret), guesses, rooms, and emoji sets — lives here,
  durable and ACID. BCS still supplies the identity (branded ids are the primary
  keys), EchoStore still caches the hot immutable reads over this, and EchoMQ still
  runs the queues and the real-time competitive state; Postgres is the floor of
  truth those layers stand on.
  """
  use Ecto.Repo, otp_app: :codemojex, adapter: Ecto.Adapters.Postgres
end
