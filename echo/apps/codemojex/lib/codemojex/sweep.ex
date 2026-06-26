defmodule Codemojex.Sweep do
  @moduledoc """
  The periodic game sweep (cm.5 R9). One supervised `GenServer` that, every tick,
  drives the time-based transitions idempotently — each guarded by the same Valkey
  `SET … NX` close locks the manual paths use, so a tick is safe to repeat and two
  nodes' sweeps never double-fire:

    * an `:open` game past its `ends_ms` timer is **closed** (`Rooms.close_if_expired/1`,
      previously wired to nothing — the timer close had no driver);
    * a `:gathering` Golden Room past its `room_deadline` is **voided** (no refund,
      `Rooms.void_if_stale/1`);
    * a `:gathering` Golden Room still before its `room_deadline` gets a
      **bot-engagement nudge** to each member's chat (`Notifier.gather_nudge/3`).

  The due set comes from `Store.due_games/0` (the `:open` + `:gathering` games). The
  tick interval is configurable (`:sweep_ms`, default 60s); a non-positive interval
  disables the loop (the suites drive the closes explicitly, so the periodic tick
  stays out of their way — they call `Rooms.close_if_expired/1` / `void_if_stale/1`).
  """
  use GenServer
  require Logger

  alias Codemojex.{Store, Rooms, Notifier}

  @default_ms 60_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval_ms, Application.get_env(:codemojex, :sweep_ms, @default_ms))
    if interval > 0, do: schedule(interval)
    {:ok, %{interval: interval}}
  end

  @impl true
  def handle_info(:tick, %{interval: interval} = state) do
    sweep()
    if interval > 0, do: schedule(interval)
    {:noreply, state}
  end

  @doc """
  Run one sweep pass over the due games (also the unit-test entry point — call it
  directly to drive a tick deterministically). Returns `:ok`.
  """
  def sweep do
    for game <- Store.due_games() do
      case game.status do
        :open -> safe(fn -> Rooms.close_if_expired(game.id) end)
        :gathering -> sweep_gathering(game)
        _ -> :ok
      end
    end

    :ok
  end

  # A gathering Golden Room: void if its deadline has passed, else nudge its members.
  defp sweep_gathering(game) do
    case Rooms.void_if_stale(game.id) do
      {:ok, :voided} -> :ok
      {:ok, :already_closed} -> :ok
      _ -> nudge_members(game)
    end
  end

  # Bot-engagement: one nudge per member chat for a gathering Golden Room before its
  # deadline (cm.5 R9). Best-effort — a missing chat or a notify failure is skipped.
  defp nudge_members(%{room_deadline: %DateTime{} = deadline, id: game}) do
    for player <- Store.members(game) do
      case Store.chat_of(player) do
        nil -> :ok
        chat -> safe(fn -> Notifier.gather_nudge(chat, game, deadline) end)
      end
    end

    :ok
  end

  defp nudge_members(_game), do: :ok

  defp schedule(interval), do: Process.send_after(self(), :tick, interval)

  # A sweep step must never crash the loop: a single bad game (a Valkey blip, a race)
  # is logged and skipped so the rest of the pass still runs.
  defp safe(fun) do
    fun.()
  rescue
    e -> Logger.warning("sweep step failed: #{inspect(e)}")
  catch
    :exit, reason -> Logger.warning("sweep step exited: #{inspect(reason)}")
  end
end
