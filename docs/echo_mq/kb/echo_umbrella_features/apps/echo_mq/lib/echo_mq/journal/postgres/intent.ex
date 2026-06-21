defmodule EchoMQ.Journal.Postgres.Intent do
  @moduledoc "The outbox intent row — the same shape as the SQLite journal's `intents`."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "emq_intents" do
    field :job_id, :string
    field :name_id, :string
    field :version, :integer
    field :enqueued, :boolean, default: false
    field :recorded_at, :utc_datetime_usec, autogenerate: {DateTime, :utc_now, []}
  end

  def changeset(intent, attrs) do
    intent
    |> cast(attrs, [:job_id, :name_id, :version, :enqueued, :recorded_at])
    |> validate_required([:job_id, :name_id, :version])
    |> unique_constraint(:job_id)
  end
end
