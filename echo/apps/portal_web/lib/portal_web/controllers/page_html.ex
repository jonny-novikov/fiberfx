defmodule PortalWeb.PageHTML do
  @moduledoc """
  Renders the static landing page (F6.2-D1).

  Embeds `page_html/home.html.heex`, which renders purely from no assigns; no
  engine, repo, or below-the-boundary symbol appears (F6.2-INV1). Mirrors
  `PortalWeb.CourseHTML`'s structure.
  """
  use PortalWeb, :html

  embed_templates "page_html/*"
end
