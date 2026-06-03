defmodule PortalWeb.ErrorHTML do
  @moduledoc """
  Renders endpoint-level HTTP error pages (the `render_errors` target in the
  `:portal_web` endpoint config).

  Distinct from the controller's `:error` template (the expected-domain-failure
  `422` of the closed `%Portal.Error{}` set, F6.1-INV4): this module handles
  framework-level statuses Phoenix raises outside a controller action — an unmatched
  route (`404`) or an unhandled crash (`500`). The body is the status phrase
  (e.g. "Not Found"), keeping F6.1 dependency-light; richer error pages are a later
  rung.
  """
  use PortalWeb, :html

  # Map a "<status>.html" template name to its reason phrase. Phoenix.Controller's
  # status_message_from_template/1 turns "404.html" → "Not Found", "500.html" →
  # "Internal Server Error".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
