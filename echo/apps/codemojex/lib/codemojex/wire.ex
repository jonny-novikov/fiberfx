defmodule Codemojex.Wire do
  @moduledoc """
  Codemojex's seam onto the owned wire. Every Valkey command the game runs is
  built with the EchoWire fluent client (`EchoWire.Cmd`) and flushed through
  this one adapter — so the game speaks curated, typed verbs (`Cmd.hset/3`,
  `Cmd.zadd/1`, `Cmd.hsetnx/3`, …) and never hand-writes a raw command list
  against `EchoMQ.Connector`.

  `EchoWire.Cmd.run/2` flushes a built `%EchoWire.Command{}` through the
  connector's `pipeline/3` and answers `{:ok, [reply]}` — a one-element list,
  one reply per command. The game runs a single command per call and reads a
  single reply, so `run/2` here unwraps the singleton list back to
  `{:ok, reply}`. That unwrap is exactly what `EchoMQ.Connector.command/2` does
  (`connector.ex:49` — `pipeline(conn, [parts]) |> {:ok, [reply]} -> {:ok, reply}`),
  so a `Cmd`-built command flushed through here is byte-for-byte equivalent to
  the old raw `Connector.command/2`, now driven by the fluent builder.

  The connector stays the sole owner of the wire (the v2 master invariant is
  untouched): this seam only changes *how a command is constructed*, never how
  it is transported.
  """
  alias EchoWire.{Cmd, Command}

  @doc """
  Flush one EchoWire command over `conn` and return its single reply.

  Accepts an un-built `%EchoWire.Cmd{}` builder (the common case — built here
  via the `Cmd.build/1` closing token) or an already-built `%EchoWire.Command{}`
  (e.g. from `EchoWire.Command.raw/1` for an un-curated verb).
  """
  @spec run(Cmd.t() | Command.t(), GenServer.server()) ::
          {:ok, term()} | {:error, term()}
  def run(%Cmd{} = builder, conn), do: builder |> Cmd.build() |> run(conn)

  def run(%Command{} = cmd, conn) do
    case Cmd.run(cmd, conn) do
      {:ok, [reply]} -> {:ok, reply}
      {:error, _} = err -> err
    end
  end
end
