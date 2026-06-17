defmodule EchoWire do
  @moduledoc """
  The wire layer's front door: RESP framing, the single-owner socket
  connector, and the script registry behind the version fence, delegated
  from one module so the layer can stand as its own library.

  The name. The series' own vocabulary already calls this layer the wire --
  every committed record prices "the wire", sweeps "the wire", parks on
  "the wire" -- so the extracted application is `echo_wire`, chosen over
  `echo_conn` (too generic), `echo_resp` (names the framing, not the layer),
  and `echo_link` (collides with Process.link vocabulary). Module names
  `EchoMQ.Connector`, `EchoMQ.RESP`, and `EchoMQ.Script` are frozen by the
  committed records that cite them; this facade is the forward-facing name
  and the historical names stay canonical underneath.
  """

  alias EchoMQ.{Connector, Script}

  defdelegate start_link(opts), to: Connector
  defdelegate command(conn, parts, timeout \\ 5_000), to: Connector
  defdelegate pipeline(conn, cmds, timeout \\ 5_000), to: Connector
  defdelegate noreply_pipeline(conn, cmds, timeout \\ 5_000), to: Connector
  defdelegate transaction_pipeline(conn, cmds, timeout \\ 5_000), to: Connector
  defdelegate eval(conn, script, keys, argv, timeout \\ 5_000), to: Connector
  defdelegate push_command(conn, parts, timeout \\ 5_000), to: Connector
  defdelegate subscribe(conn, channel), to: Connector
  defdelegate unsubscribe(conn, channel), to: Connector
  defdelegate stats(conn), to: Connector

  @doc "Declare a fenced script; see EchoMQ.Script.new/2."
  defdelegate script(name, source), to: Script, as: :new
end
