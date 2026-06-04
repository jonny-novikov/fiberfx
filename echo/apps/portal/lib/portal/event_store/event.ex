defmodule Portal.EventStore.Event do
  @moduledoc """
  Ecto schema for the `:events` table backing `Portal.EventStore.Postgres` (F6.3).

  An event row is an internal append-only log entry, NOT a domain entity surfaced
  over the facade — so its `:id` is a raw `:bigint` Snowflake (Portal-minted,
  `autogenerate: false`), NOT a branded `Portal.Catalog.CourseID`. `:seq` orders
  events WITHIN a `:stream`; `:data` is a jsonb (`:map`) column. Append-only:
  `inserted_at` only, never updated.
  """
  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: false}

  schema "events" do
    field(:stream, :string)
    field(:seq, :integer)
    field(:type, :string)
    field(:data, :map)

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
