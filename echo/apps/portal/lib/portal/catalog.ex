defmodule Portal.Catalog do
  @moduledoc """
  The Catalog bounded context — courses, lessons, and pages.

  Owns and is the only module that builds or persists its entities; references
  other contexts only by branded id (never by struct).
  """
  alias Portal.Catalog.{Course, Lesson}

  @doc "Fetch a course by branded id."
  @spec course(String.t()) :: {:ok, Course.t()} | :error
  def course(course_id), do: Portal.Store.get("CRS", course_id)

  @doc "Fetch a lesson by branded id."
  @spec lesson(String.t()) :: {:ok, Lesson.t()} | :error
  def lesson(lesson_id), do: Portal.Store.get("LSN", lesson_id)
end
