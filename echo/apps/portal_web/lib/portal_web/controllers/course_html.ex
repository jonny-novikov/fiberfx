defmodule PortalWeb.CourseHTML do
  @moduledoc """
  Renders the course pages (F6.1-R5, F6.1-D5).

  Embeds `course_html/index.html.heex` and `course_html/error.html.heex`. Both
  templates render purely from `assigns`; no engine, repo, or below-the-boundary
  symbol appears in either (F6.1-INV1).
  """
  use PortalWeb, :html

  embed_templates "course_html/*"
end
