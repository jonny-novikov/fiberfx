defmodule EchoMQ.Locks.Core do
  @moduledoc """
  The lock plane's pure decision core: the lease and the extend interval as
  plain functions of the start options, with no process, no clock, and no I/O.
  The cadence is a value the consumer can compute and table; the GenServer
  shell (`EchoMQ.Locks`) reads these once at `init` and beats on them. The
  `EchoMQ.Pump.Core` precedent (the cadence arithmetic is a value tested
  without a clock). emq.2.3-D5.

  (The module is `EchoMQ.Locks.Core`, not `EchoMQ.LockManager.Core`: the v1
  reference `apps/echomq` already defines `EchoMQ.LockManager`, and both apps
  load on one code path -- a same-named module would shadow non-
  deterministically. The capability is the v1 lock plane's; the name is
  collision-free. emq.2.3 realization-over-literal, ledger L-1.)
  """

  @default_lease_ms 30_000
  @default_ratio 0.5
  @default_marker_multiple 2

  @doc """
  The lease in milliseconds the plane extends each tracked job to: the
  `:lease_ms` option, or the default. A non-positive lease is refused -- a
  plane that extends to a dead deadline is a configuration error, not a silent
  no-op.

      iex> EchoMQ.Locks.Core.lease_ms([])
      30000
      iex> EchoMQ.Locks.Core.lease_ms(lease_ms: 10_000)
      10000
  """
  @spec lease_ms(keyword()) :: pos_integer()
  def lease_ms(opts) do
    case Keyword.get(opts, :lease_ms, @default_lease_ms) do
      ms when is_integer(ms) and ms > 0 -> ms
      bad -> raise ArgumentError, "lease_ms must be a positive integer, got: #{inspect(bad)}"
    end
  end

  @doc """
  The `:lock` presence marker's PX TTL in milliseconds: a small multiple of the
  lease (`:marker_multiple`, default #{@default_marker_multiple}×), so a marker
  set on `track_job` and refreshed on each beat OUTLIVES the lease for a live
  worker but SELF-EXPIRES shortly after the lease does for a crashed one --
  restoring the self-healing the v1 lock-string's `PX` provided (the v2
  lease/marker split, L-3). A non-positive multiple is refused.

      iex> EchoMQ.Locks.Core.marker_ttl_ms([])
      60000
      iex> EchoMQ.Locks.Core.marker_ttl_ms(lease_ms: 10_000)
      20000
      iex> EchoMQ.Locks.Core.marker_ttl_ms(lease_ms: 10_000, marker_multiple: 3)
      30000
  """
  @spec marker_ttl_ms(keyword()) :: pos_integer()
  def marker_ttl_ms(opts) do
    lease = lease_ms(opts)

    case Keyword.get(opts, :marker_multiple, @default_marker_multiple) do
      m when is_number(m) and m > 0 -> max(1, round(lease * m))
      bad -> raise ArgumentError, "marker_multiple must be a positive number, got: #{inspect(bad)}"
    end
  end

  @doc """
  The extend interval in milliseconds: the beat at which the plane re-extends
  every tracked job, BEFORE the lease elapses. Either the explicit
  `:extend_ms` option, or a fraction (`:extend_ratio`, default #{@default_ratio})
  of the lease -- so a 30s lease re-extends every 15s by default, giving the
  extension room to land before the reaper's scan. The interval is clamped to
  at least 1ms and strictly below the lease (an interval >= the lease would
  let the deadline pass un-extended).

      iex> EchoMQ.Locks.Core.extend_ms([])
      15000
      iex> EchoMQ.Locks.Core.extend_ms(lease_ms: 10_000)
      5000
      iex> EchoMQ.Locks.Core.extend_ms(lease_ms: 10_000, extend_ratio: 0.25)
      2500
      iex> EchoMQ.Locks.Core.extend_ms(extend_ms: 1_000)
      1000
  """
  @spec extend_ms(keyword()) :: pos_integer()
  def extend_ms(opts) do
    lease = lease_ms(opts)

    raw =
      case Keyword.get(opts, :extend_ms) do
        nil -> round(lease * extend_ratio(opts))
        ms when is_integer(ms) and ms > 0 -> ms
        bad -> raise ArgumentError, "extend_ms must be a positive integer, got: #{inspect(bad)}"
      end

    raw |> max(1) |> min(lease - 1)
  end

  defp extend_ratio(opts) do
    case Keyword.get(opts, :extend_ratio, @default_ratio) do
      r when is_number(r) and r > 0 and r < 1 -> r
      bad -> raise ArgumentError, "extend_ratio must be a number in (0, 1), got: #{inspect(bad)}"
    end
  end
end
