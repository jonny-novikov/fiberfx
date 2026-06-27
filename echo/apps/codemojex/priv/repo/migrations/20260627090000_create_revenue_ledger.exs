defmodule Codemojex.Repo.Migrations.CreateRevenueLedger do
  use Ecto.Migration

  # cm.6 — the platform revenue ledger (cm-6 D-1). A dedicated signed table mirroring
  # `transactions`, designed multi-source (`account`) / multi-currency (`currency`).
  # NO non-negative CHECK — the deliberate difference from `players`: the house
  # legitimately swings negative on the `deposit_seed` debit (D-1/D-4). Additive onto
  # the THREE shipped migrations (all byte-frozen) — cm.6 creates, never edits.
  #
  # up/down are EXPLICIT (a plain create infers its own down, but the explicit pair
  # matches the cm.5 idiom and makes the `drop` legible). `up` is NON-DESTRUCTIVE (a
  # pure create — the destructive gate is a no-op on it); `down` is the dev-reset
  # inverse (drops the new table), never a live rollback over accrued revenue.
  def up do
    create table(:revenue_ledger, primary_key: false) do
      add :id, :string, primary_key: true     # the branded RVL id (D-6)
      add :account, :string, null: false      # "platform" this rung; the BNK/cm.7 source seam (D-5)
      add :currency, :string, null: false     # "keys" this rung; "stars"/"cents" forward (D-2/D-5)
      add :delta, :bigint, null: false         # SIGNED — no non-negative CHECK (the whole point vs players, D-1)
      add :reason, :string, null: false
      add :ref, :string                         # the GAM id, nullable (mirrors transactions.ref)
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:revenue_ledger, [:account])   # house_balance() aggregate (§7)
    create index(:revenue_ledger, [:ref])        # revenue_breakdown(game) by ref (§7)
  end

  def down do
    drop table(:revenue_ledger)
  end
end
