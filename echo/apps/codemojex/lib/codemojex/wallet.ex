defmodule Codemojex.Wallet do
  @moduledoc """
  The balances, on Postgres, mutated inside database transactions. A mutation
  locks the player row (`SELECT … FOR UPDATE`), checks the non-negative invariant,
  writes the new balance, and inserts the paired ledger row — all or nothing. The
  row lock serializes only same-player mutations, so the field is never funnelled
  through one process: the database now does the work the single-writer GenServer
  used to, and scales with it, while the CHECK constraint is the backstop if
  application logic ever slips. Paid rooms only ever touch keys, free rooms only
  clips — the two paths never cross.
  """
  import Ecto.Query
  alias Codemojex.Repo
  alias Codemojex.Schemas.{Player, Transaction}
  alias Codemojex.Economy

  @empty %{keys: 0, clips: 0, diamonds: 0, bonus_diamonds: 0, locked_diamonds: 0}

  @doc "Create a player (`PLR`) with an opening balance (`:keys`, `:clips`, `:diamonds`)."
  def create(name, opts \\ []) do
    uid = EchoData.BrandedId.generate!("PLR")

    attrs =
      Map.merge(@empty, %{
        id: uid,
        name: name,
        tg_chat_id: Keyword.get(opts, :tg_chat_id),
        keys: Keyword.get(opts, :keys, 0),
        clips: Keyword.get(opts, :clips, 0),
        diamonds: Keyword.get(opts, :diamonds, 0)
      })

    case %Player{} |> Player.create_changeset(attrs) |> Repo.insert() do
      {:ok, _} -> {:ok, uid}
      {:error, _} = e -> e
    end
  end

  @doc "Charge a guess against the right currency for the game; refuse if short. `ref` is the game id."
  def charge_guess(player, game_map, ref) do
    {currency, cost} =
      if Map.get(game_map, :free, false),
        do: {:clips, Map.get(game_map, :clip_cost, 1)},
        else: {:keys, Map.get(game_map, :guess_fee, 1)}

    debit(player, currency, cost, "guess", ref)
  end

  @doc "Buy keys (paid externally via Telegram Stars); `ref` is the payment id."
  def purchase_keys(player, keys, ref), do: credit(player, :keys, keys, "purchase", ref)

  @doc "Deposit a diamond prize for a game win."
  def deposit_prize(player, diamonds, ref), do: credit(player, :diamonds, diamonds, "prize", ref)

  @doc "Grant a currency (bonus/admin)."
  def grant(player, currency, amount, reason \\ "grant"),
    do: credit(player, currency, amount, to_string(reason), nil)

  @doc "Convert diamonds to keys at 10:1 — one debit, one credit, one balance update, one transaction."
  def convert_to_keys(player, diamonds) do
    Repo.transaction(fn ->
      case lock(player) do
        nil ->
          Repo.rollback(:no_player)

        p ->
          cond do
            diamonds <= 0 or rem(diamonds, Economy.diamonds_per_key()) != 0 ->
              Repo.rollback(:bad_amount)

            p.diamonds - p.locked_diamonds < diamonds ->
              Repo.rollback(:insufficient)

            true ->
              keys = Economy.keys_from_diamonds(diamonds)
              update!(p, %{diamonds: p.diamonds - diamonds, keys: p.keys + keys})
              dref = txn!(player, :diamonds, -diamonds, "convert", nil)
              _ = txn!(player, :keys, keys, "convert", dref)
              %{keys: p.keys + keys, diamonds: p.diamonds - diamonds}
          end
      end
    end)
  end

  @doc "The player's balance, with the spendable figures (clips and locked diamonds set apart)."
  def balance(player) do
    case Repo.get(Player, player) do
      nil ->
        nil

      p ->
        p
        |> Map.from_struct()
        |> Map.drop([:__meta__])
        |> Map.merge(%{available_keys: p.keys, available_diamonds: p.diamonds - p.locked_diamonds})
    end
  end

  # --- internals (each runs in one DB transaction) ----------------------
  defp debit(player, currency, amount, reason, ref) do
    Repo.transaction(fn ->
      case lock(player) do
        nil ->
          Repo.rollback(:no_player)

        p ->
          have = Map.get(p, currency)

          if have < amount do
            Repo.rollback(:insufficient)
          else
            update!(p, %{currency => have - amount})
            txn!(player, currency, -amount, reason, ref)
            have - amount
          end
      end
    end)
  end

  defp credit(player, currency, amount, reason, ref) when amount >= 0 do
    Repo.transaction(fn ->
      case lock(player) do
        nil ->
          Repo.rollback(:no_player)

        p ->
          have = Map.get(p, currency)
          update!(p, %{currency => have + amount})
          txn!(player, currency, amount, reason, ref)
          have + amount
      end
    end)
  end

  defp credit(_player, _currency, _amount, _reason, _ref), do: {:error, :bad_amount}

  defp lock(id), do: Repo.one(from p in Player, where: p.id == ^id, lock: "FOR UPDATE")

  defp update!(p, changes) do
    {:ok, _} = p |> Player.balance_changeset(changes) |> Repo.update()
  end

  defp txn!(player, currency, delta, reason, ref) do
    tid = EchoData.BrandedId.generate!("TXN")

    {:ok, _} =
      %Transaction{}
      |> Transaction.changeset(%{
        id: tid,
        player: player,
        currency: to_string(currency),
        delta: delta,
        reason: reason,
        ref: ref
      })
      |> Repo.insert()

    tid
  end
end
