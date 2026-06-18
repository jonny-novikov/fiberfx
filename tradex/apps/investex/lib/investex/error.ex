defmodule Investex.Error do
  @moduledoc """
  The typed `{:error, reason}` value the per-service functions return (rung
  TRD.9.1, `docs/exchange/trd.9.1.specs.md` §Surface).

  A venue RPC fails in one of a small, closed set of ways: the channel is gone,
  the call returned a gRPC status, or the retry decision gave up. `Investex.Error`
  names that vocabulary as a struct (the `Exchange.Gateway`/`Portal.Error` house
  style — a struct + `new/1`, not a bare atom), so a caller pattern-matches a
  typed reason and never an exception. The per-service functions in
  `Investex.Users` / `Investex.Sandbox` return `{:ok, response} | {:error,
  t()}` — `t()` is this struct (INV-5: the per-service modules are stateless and
  total over a client handle; no exception escapes the call boundary).

  The `:status` field carries the gRPC status atom on an `:rpc_error` (e.g.
  `:unavailable`, `:resource_exhausted`) so the retry shell and a caller can
  branch on it; it is `nil` for the channel-level reasons. The `:message` is a
  human string; the secret never appears in it (INV-9).
  """

  @typedoc """
  The closed reason vocabulary:

    * `:no_channel`   — the client handle has no live `GRPC.Channel` (not dialed
      / already stopped).
    * `:rpc_error`    — the venue returned a gRPC status (`:status` carries it).
    * `:retry_exhausted` — the retry decision gave up before a success.
  """
  @type reason :: :no_channel | :rpc_error | :retry_exhausted

  @typedoc "A typed venue-call failure. `status` is the gRPC status atom on an `:rpc_error`, else nil."
  @type t :: %__MODULE__{
          reason: reason(),
          status: atom() | nil,
          message: String.t()
        }

  @enforce_keys [:reason, :message]
  defstruct [:reason, :status, :message]

  @doc """
  Builds an `t:t/0` from a bare reason or an opts keyword/map (the `gateway.ex` /
  `Portal.Error.new/1` house style). A bare reason gets a default message; opts
  may carry `:status` and a custom `:message`.

      iex> Investex.Error.new(:no_channel).reason
      :no_channel

      iex> e = Investex.Error.new(reason: :rpc_error, status: :unavailable, message: "endpoint down")
      iex> {e.reason, e.status}
      {:rpc_error, :unavailable}
  """
  @spec new(reason() | keyword() | map()) :: t()
  def new(reason) when reason in [:no_channel, :rpc_error, :retry_exhausted] do
    %__MODULE__{reason: reason, status: nil, message: default_message(reason)}
  end

  def new(opts) when is_list(opts), do: opts |> Map.new() |> new()

  def new(%{reason: reason} = opts) when is_map(opts) do
    %__MODULE__{
      reason: reason,
      status: Map.get(opts, :status),
      message: Map.get(opts, :message, default_message(reason))
    }
  end

  @doc """
  Maps a gRPC error value (a `%GRPC.RPCError{}` or a bare status atom) to a
  `:rpc_error` `t:t/0`, lifting the status. The message is the RPC error's own
  message where present — it is the venue's status text, never the bearer token
  (INV-9).

      iex> Investex.Error.from_rpc(%GRPC.RPCError{status: 14, message: "unavailable"}).reason
      :rpc_error
  """
  @spec from_rpc(GRPC.RPCError.t() | atom()) :: t()
  def from_rpc(%GRPC.RPCError{message: message} = err) do
    %__MODULE__{
      reason: :rpc_error,
      status: status_atom(err),
      message: message || default_message(:rpc_error)
    }
  end

  def from_rpc(status) when is_atom(status) do
    %__MODULE__{reason: :rpc_error, status: status, message: default_message(:rpc_error)}
  end

  # GRPC.RPCError carries the numeric gRPC status code; map it to the atom the
  # retry decision (Investex.Retry) speaks, via the grpc lib's status table.
  defp status_atom(%GRPC.RPCError{status: status}) when is_integer(status) do
    GRPC.Status.code_name(status) |> normalize_status()
  end

  defp status_atom(%GRPC.RPCError{status: status}) when is_atom(status), do: normalize_status(status)

  # GRPC.Status.code_name/1 returns a CamelCase string ("Unavailable"); the
  # retry decision keys on snake_case atoms (:unavailable). Normalize once here.
  defp normalize_status(name) when is_binary(name), do: name |> Macro.underscore() |> String.to_atom()
  defp normalize_status(name) when is_atom(name), do: name

  defp default_message(:no_channel), do: "no live gRPC channel on the client handle"
  defp default_message(:rpc_error), do: "the venue returned a gRPC error status"
  defp default_message(:retry_exhausted), do: "the retry policy gave up before a successful call"
end
