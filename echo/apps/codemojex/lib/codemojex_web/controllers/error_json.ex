defmodule CodemojexWeb.ErrorJSON do
  @moduledoc "Renders unhandled errors (e.g. 404/500) as JSON."
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
