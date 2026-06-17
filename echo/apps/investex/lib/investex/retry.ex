defmodule Investex.Retry do
  @moduledoc """
  The **pure** retry decision (rung TRD.9.1, `docs/exchange/trd.9.1.specs.md`
  §Surface; INV-6, L-2).

  The Go SDK's retry policy lives inside an impure gRPC interceptor
  (`client.go:19-70`): it retries `Unavailable`/`Internal` on a linear 500 ms
  backoff up to `max_retries`, and `ResourceExhausted` on a longer wait (unless
  disabled). The *decision* that policy encodes is a deterministic function of a
  status, an attempt count, and the response headers — so it is carved out here
  as a pure function, exactly as the matching core (TRD.2.1) carved the decider
  out of the stateful shell. The interceptor that **applies** the decision
  (sleeping, re-dialing) is the impure shell; it may stay thin this slice and
  harden in later rungs.

  `decide/3` holds no clock, no sleep, no `Process.*`, no network, no IO — it is
  a value-in / value-out function of its three arguments (the grep that proves
  the forbidden set empty is gate G4).

  ## The branches

    * `:unavailable` / `:internal` under the cap ⇒ `{:retry, 500}` — the Go
      `WAIT_BETWEEN` linear backoff (`client.go:21,42-44`).
    * `:resource_exhausted` under the cap ⇒ `{:retry, wait_ms}` — a longer wait
      honoring the `x-ratelimit-reset` header (seconds until the per-minute
      counter resets, grpc.md:92), read from `headers`. This is a **refinement**
      over the Go interceptor, which sleeps an attempt-indexed interval
      header-blind (`client.go:48-54`): the header carries the right value and a
      pure function can read it offline (L-2). With no/blank header, a 500 ms
      floor is used.
    * past `max_retries`, or `:resource_exhausted` with the resource-exhausted
      retry disabled ⇒ `:give_up`.
    * any other status ⇒ `:give_up` (the policy retries only the three codes
      above).
  """

  alias Investex.Config

  # The Go linear backoff between attempts (WAIT_BETWEEN, client.go:21). Also the
  # floor for a ResourceExhausted wait when the header is absent/unparseable.
  @wait_between_ms 500

  @typedoc "The gRPC status the call returned (the snake_case atom Investex.Error normalizes to)."
  @type status :: atom()

  @typedoc "The retry decision: wait `wait_ms` then retry, or give up."
  @type decision :: {:retry, wait_ms :: non_neg_integer()} | :give_up

  @doc """
  The pure retry decision: `(status, attempt, headers) -> {:retry, wait_ms} |
  :give_up`. `attempt` is the zero-based count of attempts already made; the cap
  is `max_retries` (a `%Investex.Config{}` or a bare integer).

  The default cap is read from a `%Investex.Config{}` — but to keep `decide/3`
  pure and config-shape-agnostic the cap and the resource-exhausted-disabled
  flag are passed via `headers` overrides only for testing; in normal use the
  caller threads its `Config` through `decide/4` (below). `decide/3` uses the
  spec-default cap (3) and RE-enabled.

      iex> Investex.Retry.decide(:unavailable, 0, %{})
      {:retry, 500}

      iex> Investex.Retry.decide(:internal, 2, %{})
      {:retry, 500}

      iex> Investex.Retry.decide(:unavailable, 3, %{})
      :give_up

      iex> Investex.Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => "7"})
      {:retry, 7000}

      iex> Investex.Retry.decide(:not_found, 0, %{})
      :give_up
  """
  @spec decide(status(), non_neg_integer(), map()) :: decision()
  def decide(status, attempt, headers) do
    decide(status, attempt, headers, Config.new([]))
  end

  @doc """
  The cap-and-flag-bearing form: the retry decision against an explicit
  `%Investex.Config{}` (its `max_retries` is the cap, its
  `disable_resource_exhausted_retry` gates the `:resource_exhausted` branch,
  `disable_all_retry` ⇒ `max_retries` 0 already folded by `Config.new/1`). Still
  pure — `Config` is a plain value.

      iex> cfg = Investex.Config.new(max_retries: 1)
      iex> Investex.Retry.decide(:unavailable, 1, %{}, cfg)
      :give_up

      iex> cfg = Investex.Config.new(disable_resource_exhausted_retry: true)
      iex> Investex.Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => "5"}, cfg)
      :give_up
  """
  @spec decide(status(), non_neg_integer(), map(), Config.t()) :: decision()
  def decide(status, attempt, headers, %Config{} = config) do
    cond do
      attempt >= config.max_retries ->
        :give_up

      status in [:unavailable, :internal] ->
        {:retry, @wait_between_ms}

      status == :resource_exhausted and not config.disable_resource_exhausted_retry ->
        {:retry, resource_exhausted_wait(headers)}

      true ->
        :give_up
    end
  end

  # The ResourceExhausted wait: honor x-ratelimit-reset (seconds-to-reset,
  # grpc.md:92) → milliseconds, floored at WAIT_BETWEEN so a 0/absent/garbage
  # header never collapses the backoff to zero. Pure integer arithmetic — no
  # clock is read; the header value IS the wait the venue advertises (L-2).
  defp resource_exhausted_wait(headers) when is_map(headers) do
    case Map.get(headers, "x-ratelimit-reset") do
      value when is_binary(value) ->
        case Integer.parse(value) do
          {seconds, ""} when seconds > 0 -> max(seconds * 1000, @wait_between_ms)
          _ -> @wait_between_ms
        end

      seconds when is_integer(seconds) and seconds > 0 ->
        max(seconds * 1000, @wait_between_ms)

      _ ->
        @wait_between_ms
    end
  end
end
