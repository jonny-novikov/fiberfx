defmodule EchoWire.Result do
  @moduledoc """
  The two-tier error classifier — the rueidis `NonValkeyError()` vs `Error()`
  distinction (`go/valkey-go/message.go:149`/`:154`) brought into idiomatic
  Elixir as a **pure** reader over `EchoWire.Pipe.exec/1`'s already-decoded
  return.

  The split **already exists in the data** (`ewr.1.1`, the closed error set):

  - a **transport** failure is `exec`'s `{:error, term}` whole-call branch —
    `{:error, :disconnected}` / `{:error, :overloaded}` /
    `{:error, {:version_fence, _}}` / `{:error, :empty_pipeline}` / any other
    `{:error, term}`;
  - a **server** rejection is the in-band value `{:error_reply, binary()}`
    (`resp.ex:47`) carried inside a successful `{:ok, [reply]}` — e.g. a
    `WRONGTYPE`.

  `EchoWire.Result` does not invent the split; it **names** it through four
  pure accessors over `exec`'s return. It calls no socket, no connector, no
  pool — it reads a value `exec` produced.

      conn |> Pipe.new() |> Pipe.set(k, "v") |> Pipe.lpush(k, "x") |> Pipe.exec()
      # => {:ok, ["OK", {:error_reply, "WRONGTYPE ..."}]}
      |> EchoWire.Result.classify()
      # => {:server_error, ["OK", {:error_reply, "WRONGTYPE ..."}],
      #     [{1, {:error_reply, "WRONGTYPE ..."}}]}

  ## The four accessors (the frozen contract)

  - `classify/1` — the total transport-vs-server partition (its internal
    representation, the tagged tri-state below, is this module's design-make;
    the contract is checked through the accessors).
  - `non_valkey_error/1` — the transport tier only (`NonValkeyError()`):
    `{:error, term}` for a transport failure, else `nil` (a server-error-
    carrying success answers `nil` — a server error is **not** a transport
    error).
  - `error/1` — transport-or-server (`Error()`): the transport `{:error, term}`
    if present, else the first `{:error_reply, _}`, else `nil` (transport
    precedes server).
  - `server_errors/1` — the per-reply lens: a reply list →
    `[{index, {:error_reply, msg}}]`, the server-error slots and their 0-based
    positions in ascending order, `[]` when every reply is clean.

  ## What it does NOT classify

  `{:error, {:server, _}}` is `eval/5`-exclusive (`connector.ex:76-77`) and
  **unreachable** through `EchoWire.Pipe` (which never flushes through `eval`).
  This module introduces no new error term and synthesizes no `{:server, _}`.
  """

  @typedoc "A server-error reply slot (`resp.ex:47`)."
  @type server_error :: {:error_reply, binary()}

  @typedoc "An indexed server-error slot: its 0-based position in the reply list and the value."
  @type indexed_error :: {non_neg_integer(), server_error()}

  @typedoc """
  The classification of an `exec` return (the internal representation —
  this module's design-make; the contract binds through the accessors):

    * `{:ok, replies}` — clean: the flush succeeded and no reply is a server
      error; carries the reply list.
    * `{:transport_error, term}` — the whole call failed; carries the
      transport term (`exec`'s `{:error, term}`).
    * `{:server_error, oks, server_errors}` — the flush succeeded but ≥1 reply
      is a server rejection; carries the **full** reply list (`oks`) and the
      indexed server-error slots.
  """
  @type classification ::
          {:ok, [EchoMQ.RESP.reply()]}
          | {:transport_error, term()}
          | {:server_error, [EchoMQ.RESP.reply()], [indexed_error()]}

  @typedoc "An `EchoWire.Pipe.exec/1` return."
  @type exec_return :: {:ok, [EchoMQ.RESP.reply()]} | {:error, term()}

  # -- server_errors/1 (the per-reply lens — the building block) -----------

  @doc """
  Map a reply list (the `replies` of an `{:ok, replies}`) to its server-error
  slots: `[{index, {:error_reply, msg}}]`, 0-based positions in ascending
  order, `[]` when every reply is clean. Pure, total over a list — the
  rueidis `(*ValkeyMessage).Error()` test (`message.go:740-751`) applied per
  reply.
  """
  @spec server_errors([EchoMQ.RESP.reply()]) :: [indexed_error()]
  def server_errors(replies) when is_list(replies) do
    replies
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {{:error_reply, _} = err, index} -> [{index, err}]
      {_reply, _index} -> []
    end)
  end

  # -- classify/1 (the total transport-vs-server partition) ----------------

  @doc """
  Partition an `exec` return into exactly one of three outcomes — clean /
  transport-error / server-error — total over `exec`'s return type and pure.
  It does not call `exec`, the connector, or any socket.
  """
  @spec classify(exec_return()) :: classification()
  def classify({:error, term}), do: {:transport_error, term}

  def classify({:ok, replies}) when is_list(replies) do
    case server_errors(replies) do
      [] -> {:ok, replies}
      errors -> {:server_error, replies, errors}
    end
  end

  # -- non_valkey_error/1 (the transport tier — NonValkeyError()) ----------

  @doc """
  The transport tier (`NonValkeyError()`, message.go:149-151): `{:error, term}`
  when `exec` returned a transport failure, else `nil` — **including** `nil`
  for a successful flush that carries server errors (a server error is not a
  transport error).
  """
  @spec non_valkey_error(exec_return()) :: {:error, term()} | nil
  def non_valkey_error({:error, _term} = err), do: err
  def non_valkey_error({:ok, replies}) when is_list(replies), do: nil

  # -- error/1 (transport-or-server — Error()) -----------------------------

  @doc """
  Transport-or-server (`Error()`, message.go:154-161): the transport
  `{:error, term}` if present (a transport failure means there is no reply list
  to inspect — transport precedes server); else the **first** (lowest-index)
  server `{:error_reply, msg}` if any; else `nil`.
  """
  @spec error(exec_return()) :: {:error, term()} | server_error() | nil
  def error({:error, _term} = err), do: err

  def error({:ok, replies}) when is_list(replies) do
    case server_errors(replies) do
      [] -> nil
      [{_index, err} | _] -> err
    end
  end
end
