defmodule PortalWeb.LessonHTML do
  @moduledoc """
  Renders the lesson page (F6.2-D1), supporting `LessonController.show/2`'s `200`
  branch.

  Embeds `lesson_html/show.html.heex`, which renders `@lesson.title` purely from
  assigns; no engine, repo, or below-the-boundary symbol appears (F6.2-INV1). Kept
  minimal — a later F6 rung fleshes the lesson page.
  """
  use PortalWeb, :html

  embed_templates "lesson_html/*"
end
