defmodule Portal.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  # F6.3-D2 — the append-only :events log backing Portal.EventStore.Postgres. The id
  # is a raw :bigint Snowflake (autogenerate: false) the Portal mints per row — an
  # internal log entry, NOT a branded domain entity surfaced over the facade, so no
  # custom-type column. :seq orders events WITHIN a :stream; :data is jsonb (an
  # Ecto :map). Only inserted_at — log rows are append-only, never updated.
  def change do
    create table(:events, primary_key: false) do
      add(:id, :bigint, primary_key: true)
      add(:stream, :string, null: false)
      add(:seq, :integer, null: false)
      add(:type, :string, null: false)
      add(:data, :map, null: false, default: %{})

      timestamps(type: :utc_datetime, updated_at: false)
    end

    # read_stream/1 orders by :seq within a :stream; the composite index serves both
    # that ordered read and the per-stream max(seq) probe append/2 runs.
    create(index(:events, [:stream, :seq]))
  end
end
