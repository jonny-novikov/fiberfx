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
  alias Codemojex.Schemas.{Player, Transaction, Game}
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

  @doc """
  Resolve a verified Telegram user id to the single `PLR` bound to it — the
  existing row if one exists, else a freshly minted+inserted one (cm.4 §2).

  Idempotent: two calls (or N concurrent first-touches) for the same `tg_user_id`
  yield the SAME `PLR` and leave EXACTLY ONE row. The partial unique index is the
  sole enforcer; the loser of a race writes nothing (`on_conflict: :nothing`) and
  the re-fetch returns the winner (Pattern A — `on_conflict: :nothing` + re-fetch).

  `opts` carries `:name` (the display name for a first-touch create — the verifier
  passes the Telegram `first_name`/`username`, else a default) and optionally
  `:tg_chat_id`.
  """
  def resolve_by_tg(tg_user_id, opts \\ []) when is_integer(tg_user_id) do
    case Repo.get_by(Player, tg_user_id: tg_user_id) do
      %Player{id: id} ->
        {:ok, id}

      nil ->
        uid = EchoData.BrandedId.generate!("PLR")

        attrs =
          Map.merge(@empty, %{
            id: uid,
            name: name_of(opts),
            tg_user_id: tg_user_id,
            tg_chat_id: Keyword.get(opts, :tg_chat_id)
          })

        {:ok, %Player{}} =
          %Player{}
          |> Player.create_changeset(attrs)
          |> Repo.insert(
            on_conflict: :nothing,
            # The conflict arbiter must match the PARTIAL index's predicate
            # byte-for-byte (cm.4 §2.3) — a bare `:tg_user_id` would not match it.
            # Stays in lockstep with the migration `where:`.
            conflict_target: {:unsafe_fragment, "(tg_user_id) WHERE tg_user_id IS NOT NULL"}
          )

        # The unique index is the SOLE source of truth — re-fetch the winner by
        # tg_user_id. A real insert wrote uid's row; a conflict (:nothing) wrote
        # nothing and the loser's minted uid is discarded — either way the one row
        # the index guards is THE answer, returned to every concurrent caller. (The
        # in-memory struct cannot be trusted: on_conflict: :nothing returns a
        # :loaded-state struct even when the write was suppressed, so a state check
        # would hand a loser back its own discarded id.)
        {:ok, Repo.get_by!(Player, tg_user_id: tg_user_id).id}
    end
  end

  defp name_of(opts) do
    case Keyword.get(opts, :name) do
      name when is_binary(name) and name != "" -> name
      _ -> "player"
    end
  end

  @doc """
  Charge a guess against the right currency for the game; refuse if short. `ref` is
  the game id.

  For a **golden (paid) game** the charge is two-sided (cm.5 R-GUESSPOOL): the keys
  debit AND an atomic SQL `+` adding `guess_fee × 10` 💎 to the game's prize_pool, in
  ONE transaction — every guess funds the pool. A free game, or a non-golden paid
  game, charges only (the pool is funded only for a Golden Room).
  """
  def charge_guess(player, game_map, ref) do
    cond do
      Map.get(game_map, :free, false) ->
        debit(player, :clips, Map.get(game_map, :clip_cost, 1), "guess", ref)

      Map.get(game_map, :golden, false) ->
        charge_guess_golden(player, Map.get(game_map, :guess_fee, 1), ref)

      true ->
        debit(player, :keys, Map.get(game_map, :guess_fee, 1), "guess", ref)
    end
  end

  # The golden two-sided guess charge: debit the keys fee AND fund the pool with
  # fee×10 💎 (the atomic SQL `+`, never an app-side RMW — additive, no dedup), in
  # one transaction. `ref` is the game id (the pool lives on the games row).
  defp charge_guess_golden(player, fee, ref) do
    Repo.transaction(fn ->
      case lock(player) do
        nil ->
          Repo.rollback(:no_player)

        p ->
          if p.keys < fee do
            Repo.rollback(:insufficient)
          else
            update!(p, %{keys: p.keys - fee})
            txn!(player, :keys, -fee, "guess", ref)
            inc_pool!(ref, fee * Economy.diamonds_per_key())
            p.keys - fee
          end
      end
    end)
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

  @doc """
  The Golden Room entry-fee buy-in — the two-sided, exactly-once op (cm.5 R4, the
  money headline). ONE `Repo.transaction` (the `convert_to_keys` idiom; **NO
  Ecto.Multi**):

    1. lock the **games** row FOR UPDATE — this serializes per-game buy-ins so the
       member ordinal + the gather count are exact, AND serializes the
       `:gathering → :open` start trigger (it subsumes the cross-store start race;
       the Valkey `:started` NX is belt-and-suspenders);
    2. lock the **player** row FOR UPDATE;
    3. `ordinal = count(buy_in TXNs for this game) + 1` — exact under the games lock;
    4. insert the `buy_in` TXN with **Pattern A** (`on_conflict: :nothing`,
       `conflict_target` byte-matched to the partial index `where:` predicate). A
       suppressed insert (already a member) ⇒ roll back `:already_member`, mutating
       nothing (the double-charge gate, INV-EXACTLY-ONCE-BUYIN);
    5. else debit `entry_fee_keys` (the players_non_negative CHECK is the short-balance
       backstop) and add the **tiered** pool portion (`Economy.entry_fee_split/5`,
       computed HERE under the lock) via the atomic SQL `+` (skipped when 0).

  Exactly-once lives in the **ledger** (the partial unique index), co-located with the
  debit + the pool `+`, crash-safe by construction — the Valkey `:paid` hint can crash
  either way without a double-charge or a money leak (L-10). Writes Postgres only.

  Returns `{:ok, :member}` (wrote), `{:ok, :already_member}` (suppressed, no mutation),
  or `{:error, reason}` (insufficient keys, no player/game).
  """
  def buy_in(player, game) do
    Repo.transaction(fn ->
      g = lock_game(game)
      p = lock(player)

      cond do
        is_nil(g) ->
          Repo.rollback(:no_game)

        is_nil(p) ->
          Repo.rollback(:no_player)

        true ->
          before = buy_in_count(game)
          ordinal = before + 1
          fee = g.entry_fee_keys || 0

          case insert_buy_in(player, game, before) do
            :suppressed ->
              :already_member

            :wrote ->
              if p.keys < fee, do: Repo.rollback(:insufficient)
              if fee > 0, do: update!(p, %{keys: p.keys - fee})

              pool =
                Economy.entry_fee_split(
                  ordinal,
                  g.start_threshold || 0,
                  g.first_movers || 0,
                  g.entry_fee_revenue_percentage || 0,
                  fee
                )

              if pool > 0, do: inc_pool!(game, pool)
              :member
          end
      end
    end)
  end

  @doc """
  Distribute a settled Golden Room's pool in ONE `Repo.transaction` (cm.5 R-HOLD): a
  💎 prize credit per top-K player (`top_k_payouts` = `[{player, diamonds}]`) and a
  clip grant per consolation member (`consolation_grants` = `[{player, clips}]`). The
  nested `deposit_prize`/`grant` transactions JOIN this parent (Ecto savepoints), so
  the whole finish commits atomically (the double-entry the holding record requires);
  a zero amount is skipped. Each credit/grant records its own TXN with `ref = game`.
  """
  def distribute_pool(game, top_k_payouts, consolation_grants) do
    Repo.transaction(fn ->
      Enum.each(top_k_payouts, fn {p, diamonds} ->
        if diamonds > 0 do
          {:ok, _} = deposit_prize(p, diamonds, game)
        end
      end)

      Enum.each(consolation_grants, fn {p, clips} ->
        if clips > 0 do
          {:ok, _} = credit(p, :clips, clips, "consolation", game)
        end
      end)

      :ok
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

  # Lock the games row FOR UPDATE — the per-game serialization point for buy_in (the
  # member ordinal, the gather count, and the start trigger). nil if the game is gone.
  defp lock_game(id), do: Repo.one(from g in Game, where: g.id == ^id, lock: "FOR UPDATE")

  # The ledger-authoritative paid-member count for a game: the number of buy_in TXNs
  # with ref = game. Exact under the games-row lock buy_in holds.
  defp buy_in_count(game) do
    Repo.one(
      from t in Transaction, where: t.ref == ^game and t.reason == "buy_in", select: count(t.id)
    )
  end

  # Insert the buy_in TXN with Pattern A: on_conflict :nothing on the partial unique
  # index (player, ref) WHERE reason='buy_in'. The conflict_target fragment MUST match
  # the migration `where:` predicate byte-for-byte — a bare [:player, :ref] would not
  # match the partial index. Returns :wrote (a row was inserted) or :suppressed (a
  # conflict — already a member).
  #
  # The truth is the LEDGER, not the returned struct: on_conflict: :nothing returns a
  # :loaded struct carrying the MINTED id even when the write was suppressed (the
  # resolve_by_tg note, wallet.ex:80-85), so an id check would treat every conflict as
  # a write. Instead the caller passes the buy_in count BEFORE the insert and we
  # re-count after — the count rose iff a row was actually written.
  defp insert_buy_in(player, game, before) do
    tid = EchoData.BrandedId.generate!("TXN")

    {:ok, _row} =
      %Transaction{}
      |> Transaction.changeset(%{
        id: tid,
        player: player,
        currency: "keys",
        delta: 0,
        reason: "buy_in",
        ref: game
      })
      |> Repo.insert(
        on_conflict: :nothing,
        conflict_target: {:unsafe_fragment, "(player, ref) WHERE reason = 'buy_in'"}
      )

    if buy_in_count(game) > before, do: :wrote, else: :suppressed
  end

  # The atomic SQL `+` on a game's prize_pool (💎) — never an app-side read-modify-
  # write (the lost-update guard). The buy-in's games-row lock already serializes, so
  # this is the canonical idiom + belt-and-suspenders; the guess path calls it lockless.
  defp inc_pool!(game, diamonds) do
    {1, _} = Repo.update_all(from(g in Game, where: g.id == ^game), inc: [prize_pool: diamonds])
    :ok
  end

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
