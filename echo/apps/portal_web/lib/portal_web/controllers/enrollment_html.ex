defmodule PortalWeb.EnrollmentHTML do
  @moduledoc """
  Renders the enrollment pages (F6.5-D0).

  Embeds `enrollment_html/index.html.heex` (a learner's enrolled courses, MOVED from
  `CourseHTML` in the F6.5 reconcile) and `enrollment_html/error.html.heex` (the
  closed `%Portal.Error{}` render at `422`, relocated from `course_html/`). Both
  render purely from `assigns`; no engine, repo, or below-the-boundary symbol appears
  (F6.5-INV1). `EnrollmentController` renders through this module by inference
  (Phoenix infers `<Controller>HTML`).
  """
  use PortalWeb, :html

  embed_templates("enrollment_html/*")
end
