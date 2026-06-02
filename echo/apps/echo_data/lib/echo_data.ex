defmodule EchoData do
  @moduledoc """
  Branded-id primitives for the Portal engine.

  Two pure, process-light building blocks:

    * `EchoData.Snowflake` — 64-bit, time-ordered ids (timestamp · worker · sequence).
    * `EchoData.Base62`    — compact `0-9A-Za-z` transport encoding of a snowflake.

  `Portal.ID` (in the `:portal` app) wraps these to mint and decode the
  3-letter-namespaced branded ids the domain uses, e.g. `"ENR0KHTOWnGLuC"`.
  """
end
