defmodule Portal do
  @moduledoc """
  The Portal engine — F5 "Pragmatic Programming" value ladder.

  F5.1–F5.3 build a framework-free core behind the `Portal.Engine` boundary
  (`Portal.Engine.dispatch/1`, `Portal.Engine.query/2`). By F5.8 this module
  becomes the public **facade** (`enroll/2`, `courses_of/1`, …) over a closed
  `%Portal.Error{}` set; the name is reserved here so callers never bind to the
  boundary internals.
  """
end
