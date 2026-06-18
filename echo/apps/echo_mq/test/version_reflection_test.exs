defmodule EchoMQ.VersionReflectionTest do
  @moduledoc """
  EWR.1.4 — the version-reflection rule (the mandatory protocol-version rule).

  `echo_wire`'s library version REFLECTS the echomq protocol version: the wire and
  the bus carry ONE number, climbing in lockstep (the climbing fence, emq.4.2-D3),
  shipped as one unit → full compatibility, no wire↔bus skew. This guard fails the
  suite if a future rung climbs one of the three numbers and forgets the others.

  Placed in `echo_mq/test/` (not `echo_wire/test/`) because it must read all three
  numbers and `echo_wire` is the dep-free base — a per-app `echo_wire` run cannot
  see `echo_mq`'s version. Same cross-app placement the connector fence test uses.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Connector

  test "echo_wire vsn == the connector @wire_version SemVer == echo_mq vsn (post ewr.1.4)" do
    wire_vsn = to_string(Application.spec(:echo_wire, :vsn))
    mq_vsn = to_string(Application.spec(:echo_mq, :vsn))
    "echomq:" <> protocol_vsn = Connector.wire_version()

    assert wire_vsn == protocol_vsn,
           "echo_wire #{wire_vsn} must reflect the echomq protocol version #{protocol_vsn}"

    assert mq_vsn == protocol_vsn,
           "echo_mq #{mq_vsn} must reflect the echomq protocol version #{protocol_vsn}"
  end
end
