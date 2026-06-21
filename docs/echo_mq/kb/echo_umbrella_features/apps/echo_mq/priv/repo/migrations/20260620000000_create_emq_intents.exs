defmodule EchoMQ.Repo.Migrations.CreateEmqIntents do
  @moduledoc """
  The Postgres outbox table. Run from the host app:
      defmodule MyApp.Repo.Migrations.CreateEmqIntents do
        use Ecto.Migration
        def up, do: EchoMQ.Journal.Postgres.Migration.up()
        def down, do: EchoMQ.Journal.Postgres.Migration.down()
      end
  """
  use Ecto.Migration
  def up, do: EchoMQ.Journal.Postgres.Migration.up()
  def down, do: EchoMQ.Journal.Postgres.Migration.down()
end

defmodule EchoMQ.Journal.Postgres.Migration do
  use Ecto.Migration

  def up do
    create table(:emq_intents) do
      add :job_id, :string, null: false
      add :name_id, :string, null: false
      add :version, :bigint, null: false
      add :enqueued, :boolean, null: false, default: false
      add :recorded_at, :utc_datetime_usec, null: false
    end

    create unique_index(:emq_intents, [:job_id])
    # the replay scan: pending intents in seq order
    create index(:emq_intents, [:id], where: "enqueued = false", name: :emq_intents_pending_idx)
  end

  def down, do: drop(table(:emq_intents))
end
