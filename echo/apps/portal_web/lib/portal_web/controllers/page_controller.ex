defmodule PortalWeb.PageController do
  @moduledoc """
  The thin public landing controller (F6.2-R1, F6.2-D1).

  `home/2` renders a static landing page from no assigns — it calls no `Portal`
  facade function and names nothing below the boundary (F6.2-INV1). The landing is
  the redirect target `PortalWeb.RequireUser` sends an unauthenticated request to
  (F6.2-D4); F6.8 later swaps that target for the real login path.
  """
  use PortalWeb, :controller

  @doc """
  Render the static landing page — always a `200`, no domain call.
  """
  def home(conn, _params) do
    render(conn, :home)
  end
end
