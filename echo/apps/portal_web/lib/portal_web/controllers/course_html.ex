defmodule PortalWeb.CourseHTML do
  @moduledoc """
  Renders the catalog pages (F6.5-D1/D8/D9).

  Embeds the catalog templates `course_html/index.html.heex` (the list),
  `course_html/show.html.heex` (one course), and `course_html/new.html.heex` (the
  create form). All three render purely from `assigns`; no engine, repo, or
  below-the-boundary symbol appears (F6.5-INV1). The enrolled-list and `:error`
  templates moved to `PortalWeb.EnrollmentHTML` in the F6.5 reconcile.
  """
  use PortalWeb, :html

  embed_templates("course_html/*")
end
