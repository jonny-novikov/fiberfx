defmodule CodemojexWeb.ErrorHTML do
  @moduledoc """
  Renders HTML errors for the browser / LiveView tier. The JSON API renders its
  errors through `CodemojexWeb.ErrorJSON`; this is the HTML counterpart, so a
  browser-tier error (a 404 on a live route, a 500) resolves to a plain status
  message instead of raising "no :html format" out of the endpoint's render_errors.
  """
  use CodemojexWeb, :html

  # "404.html" -> "Not Found", "500.html" -> "Internal Server Error", and so on.
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
