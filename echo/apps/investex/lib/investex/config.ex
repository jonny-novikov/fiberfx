defmodule Investex.Config do
  @moduledoc """
  The venue-client configuration — auth, endpoint, and the retry knobs (rung
  TRD.9.1.1, `docs/exchange/trd.9.1.1.specs.md` §Surface; mirrors the Go
  `investgo.Config`, `investgo/config.go`).

  `new/1` builds the struct from a keyword/map, applying the defaults the Go SDK
  applies in `setDefaultConfig` (`client.go:116-128`): endpoint
  `sandbox-invest-public-api.tbank.ru:443` (the T-Bank rebrand — the live
  sandbox host; the Go default `client.go:120-121` still reads the stale
  `…tinkoff.ru` and is only redirected by an `INVEST_API_URL` override, so this
  default matches the Go SDK's *actual runtime* host), `app_name`
  `jonnify.investex` (the own-repo `<nick>.<repo>` rename of the Go default
  `invest-api-go-sdk`), `max_retries` 3, both disable flags false, `account_id`
  nil. As in the Go SDK, `disable_all_retry: true` forces `max_retries` to 0
  (client.go:123-124).

  `resolve/1` lifts the environment into the struct (INV-9, INV-10):

    * `:token` from `INVEST_TOKEN` (INV-9) — the token is **never** a struct
      literal and never a default; it exists only after `resolve/1` reads it at
      call time, and its VALUE appears in nothing this module writes or holds.
    * `:endpoint` from `INVEST_API_URL` + `INVEST_API_PORT` (INV-10), composed as
      `host:port`, **only when the endpoint was not given explicitly to `new/1`**.
      The precedence is therefore **explicit `:endpoint` opt > env > default**.

  The endpoint resolution lives in `resolve/1` (not `new/1`) by design: `new/1`
  stays a pure function of its opts, so `new([]).endpoint` is the deterministic
  default and the doctest below holds with no environment present (a bare Tier-1
  `mix test` sets no `INVEST_API_URL`). The env is read in exactly one place —
  `resolve/1`, where config meets the environment — alongside the token lift.
  """

  # The default live sandbox endpoint (the T-Bank rebrand of …tinkoff.ru:443).
  @endpoint_default "sandbox-invest-public-api.tbank.ru:443"
  # The port used when only INVEST_API_URL is set (INV-10); the venue is :443.
  @endpoint_port_default "443"
  @app_name_default "jonnify.investex"
  @max_retries_default 3

  @typedoc """
  The client configuration (`investgo.Config`, config.go:11-31). `token` is
  filled by `resolve/1` from `INVEST_TOKEN` — never a struct default (INV-9).
  """
  @type t :: %__MODULE__{
          endpoint: String.t(),
          token: String.t() | nil,
          app_name: String.t(),
          account_id: String.t() | nil,
          disable_resource_exhausted_retry: boolean(),
          disable_all_retry: boolean(),
          max_retries: non_neg_integer()
        }

  @enforce_keys [:endpoint, :app_name, :max_retries]
  defstruct endpoint: @endpoint_default,
            token: nil,
            app_name: @app_name_default,
            account_id: nil,
            disable_resource_exhausted_retry: false,
            disable_all_retry: false,
            max_retries: @max_retries_default

  @doc """
  Builds an `t:t/0` from a keyword/map, applying the Go-SDK defaults
  (`setDefaultConfig`, client.go:116-128). `disable_all_retry: true` forces
  `max_retries` to 0. `token` is never set here — `resolve/1` lifts it from the
  env (INV-9).

      iex> c = Investex.Config.new([])
      iex> {c.endpoint, c.app_name, c.max_retries, c.token}
      {"sandbox-invest-public-api.tbank.ru:443", "jonnify.investex", 3, nil}

      iex> Investex.Config.new(disable_all_retry: true).max_retries
      0

      iex> Investex.Config.new(max_retries: 5).max_retries
      5
  """
  @spec new(keyword() | map()) :: t()
  def new(opts \\ []) do
    opts = Map.new(opts)

    struct(__MODULE__, %{
      endpoint: Map.get(opts, :endpoint, @endpoint_default),
      app_name: Map.get(opts, :app_name, @app_name_default),
      account_id: Map.get(opts, :account_id),
      disable_resource_exhausted_retry: Map.get(opts, :disable_resource_exhausted_retry, false),
      disable_all_retry: Map.get(opts, :disable_all_retry, false),
      max_retries: cap(opts)
    })
  end

  @doc """
  Lifts the environment into the struct (INV-9, INV-10).

  `:token` ← `INVEST_TOKEN` (INV-9). Raises if the variable is unset
  (`System.fetch_env!/1`) — the token is a hard precondition for any live call,
  and a clear raise beats a silent `nil` that surfaces as an opaque auth failure
  on the wire. The raised message names the variable, NOT a value. The token
  VALUE is never written by this function.

  `:endpoint` ← `INVEST_API_URL` + `INVEST_API_PORT` (INV-10), composed as
  `host:port`, **only when `new/1` was not given an explicit `:endpoint`** — so
  the precedence is **explicit `:endpoint` opt > env > default**. "Not explicit"
  is detected by the struct's endpoint still equalling `@endpoint_default`: a
  caller that explicitly passed a *different* endpoint keeps it (explicit wins
  over env). If only `INVEST_API_URL` is set, the port defaults to
  `#{@endpoint_port_default}` (the venue's TLS port); if neither env var is set,
  the default `@endpoint_default` stands.

  A caller that wants the soft form (skip when keyless — the sandbox-tier
  `setup`) reads `System.get_env("INVEST_TOKEN")` itself and skips on `nil`,
  rather than rescuing this raise.
  """
  @spec resolve(t()) :: t()
  def resolve(%__MODULE__{} = config) do
    %{config | token: System.fetch_env!("INVEST_TOKEN"), endpoint: resolve_endpoint(config)}
  end

  # The endpoint precedence (INV-10): explicit `:endpoint` opt > env > default.
  #
  # An explicit endpoint (the struct no longer holds @endpoint_default) is kept
  # verbatim — explicit beats env. Otherwise, if INVEST_API_URL is set, compose
  # host:port (INVEST_API_PORT, else the :443 default); if it is unset, the
  # @endpoint_default stands. The env is read HERE only, so `new/1` is pure and
  # `new([])` is deterministic.
  #
  # Edge (documented): a caller that explicitly passes the literal default string
  # is indistinguishable from no opt, so env would override it. This is the only
  # value for which "explicit" is not honored over env; passing the default and
  # receiving the default is observably correct, and the spec's contract exercises
  # an explicit endpoint distinct from the default ("host:443").
  defp resolve_endpoint(%__MODULE__{endpoint: endpoint}) when endpoint != @endpoint_default do
    endpoint
  end

  defp resolve_endpoint(%__MODULE__{}) do
    case System.get_env("INVEST_API_URL") do
      nil -> @endpoint_default
      "" -> @endpoint_default
      host -> "#{host}:#{System.get_env("INVEST_API_PORT") || @endpoint_port_default}"
    end
  end

  # disable_all_retry wins: it forces max_retries to 0 (client.go:123-124),
  # regardless of any max_retries opt. Otherwise the opt, else the default 3.
  defp cap(opts) do
    if Map.get(opts, :disable_all_retry, false) do
      0
    else
      Map.get(opts, :max_retries, @max_retries_default)
    end
  end
end
