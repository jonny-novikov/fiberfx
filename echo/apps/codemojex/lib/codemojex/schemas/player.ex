defmodule Codemojex.Schemas.Player do
  @moduledoc "A player's balances. Keys/clips/diamonds are non-negative by DB constraint."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @balances [:keys, :clips, :diamonds, :bonus_diamonds, :locked_diamonds]

  schema "players" do
    field :name, :string
    field :tg_chat_id, :integer
    # cm.4: the verified Telegram USER id (distinct from the chat id). Nullable —
    # name-created PLRs (dev, the story suites, the deferred admin path) carry no
    # Telegram user; a real binding is present only when the player handshakes.
    # `:integer` over the `bigint` column, mirroring `tg_chat_id`.
    field :tg_user_id, :integer
    field :keys, :integer, default: 0
    field :clips, :integer, default: 0
    field :diamonds, :integer, default: 0
    field :bonus_diamonds, :integer, default: 0
    field :locked_diamonds, :integer, default: 0
    timestamps(type: :utc_datetime_usec)
  end

  def create_changeset(player, attrs) do
    player
    |> cast(attrs, [:id, :name, :tg_chat_id, :tg_user_id | @balances])
    |> validate_required([:id, :name])
    # The DB-error → changeset-error bridge: a unique-violation (23505) on the
    # partial index surfaces as a changeset error, not a raised ConstraintError.
    # Names the SAME index as the migration (cm.4 §1.3). `:tg_user_id` is cast but
    # NOT validate_required — a name-created PLR inserts with no tg_user_id.
    |> unique_constraint(:tg_user_id, name: :players_tg_user_id_index)
    |> guard()
  end

  def balance_changeset(player, attrs) do
    player
    |> cast(attrs, @balances)
    |> guard()
  end

  defp guard(cs) do
    @balances
    |> Enum.reduce(cs, &validate_number(&2, &1, greater_than_or_equal_to: 0))
    |> check_constraint(:keys, name: :players_non_negative, message: "balance cannot go negative")
  end
end
