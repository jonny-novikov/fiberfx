defmodule Portal.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Start order is data → compute → web: Portal.Store (state) and Portal.Engine
    # are ready before Bandit (the front door) accepts traffic. :one_for_one — a
    # crashed child restarts on its own without taking the system down
    # (F5.1-INV3). PortalWeb.Endpoint replaces Bandit at F6.
    children = [
      Portal.Store,
      Portal.Engine,
      {Bandit, plug: Portal.Web.Router, port: port()}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)
  end

  defp port, do: String.to_integer(System.get_env("PORT", "4000"))
end
