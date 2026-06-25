defmodule Codemojex.Repo.Migrations.AddPlayerTgUserId do
  use Ecto.Migration

  # cm.4: bind a verified Telegram USER to a player (the auth floor). Additive onto
  # the single initial create (20260618000000) — one nullable column + a partial
  # unique index. Nullable so name-created PLRs (no Telegram user) coexist;
  # unique-when-present so exactly one PLR per TG user. `change/0` is auto-reversible:
  # `mix ecto.rollback` drops the index then the column.
  #
  # The `where:` predicate here is the SOLE source of truth for the resolve-or-create
  # `conflict_target` fragment in Codemojex.Wallet.resolve_by_tg/2 — they MUST stay
  # byte-matched ("(tg_user_id) WHERE tg_user_id IS NOT NULL").
  def change do
    alter table(:players) do
      add :tg_user_id, :bigint
    end

    create unique_index(:players, [:tg_user_id],
             where: "tg_user_id IS NOT NULL",
             name: :players_tg_user_id_index
           )
  end
end
