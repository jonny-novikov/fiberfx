defmodule Investex.Caller do
  @moduledoc """
  The single unary-call seam shared by the per-service modules (rung TRD.9.1,
  `docs/exchange/trd.9.1.specs.md` §Surface; INV-5).

  `Investex.Users` and `Investex.Sandbox` are stateless over a client handle:
  each function delegates here, which reads the channel and the frozen per-RPC
  metadata from the supervised `Investex.Client`, invokes the generated
  `…Service.Stub` function with that metadata attached, and maps the gRPC result
  to the typed `{:ok, response} | {:error, Investex.Error.t()}` shape. Attaching
  the `authorization` + `x-app-name` metadata in one place (client.go:37-39,
  72-78) keeps the auth header off every individual call site.

  No exception escapes: a missing channel folds to `Investex.Error.new(:no_channel)`
  and a `%GRPC.RPCError{}` folds through `Investex.Error.from_rpc/1`.
  """

  alias Investex.{Client, Error}

  @typedoc "A generated Stub unary function: `(channel, request, opts) -> {:ok, resp} | {:error, RPCError}`."
  @type stub_fun :: (GRPC.Channel.t(), struct(), keyword() -> {:ok, struct()} | {:error, term()})

  @doc """
  Runs one unary RPC: read the channel + metadata from `client`, call `stub_fun`
  with `request` and the metadata attached, and return the typed result. The
  metadata (Bearer + x-app-name) is attached here, the one call seam.
  """
  @spec unary(Client.t(), stub_fun(), struct()) ::
          {:ok, struct()} | {:error, Error.t()}
  def unary(client, stub_fun, request) when is_function(stub_fun, 3) do
    channel = Client.channel(client)
    metadata = Client.request_metadata(client)
    call(channel, stub_fun, request, metadata)
  end

  defp call(nil, _stub_fun, _request, _metadata), do: {:error, Error.new(:no_channel)}

  defp call(%GRPC.Channel{} = channel, stub_fun, request, metadata) do
    case stub_fun.(channel, request, metadata: metadata) do
      {:ok, response} ->
        {:ok, response}

      {:error, %GRPC.RPCError{} = err} ->
        {:error, Error.from_rpc(err)}

      {:error, _reason} ->
        # A non-RPCError transport failure (a connection-level term). It is NOT
        # interpolated into the message: the request metadata carries the bearer
        # token, and a transport term must never be `inspect`-ed into a
        # user-facing string lest a future error shape echo a header (INV-9, the
        # Director's Stage-3 secret-hygiene note). A fixed, reason-free message.
        {:error, Error.new(reason: :rpc_error, message: "a transport-level gRPC error occurred")}
    end
  end
end
