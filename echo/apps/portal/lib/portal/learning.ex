defmodule Portal.Learning do
  @moduledoc """
  The Learning bounded context — enrollments and progress.

  `enroll/2` mints an `ENR` id, builds a fresh enrollment (progress 0), and
  persists it. No input validation yet — that arrives in F5.4. Owns its entities;
  references other contexts only by branded id.
  """
  alias Portal.Learning.Enrollment

  @doc "Enroll a user in a course; mints an ENR id and persists the enrollment."
  @spec enroll(String.t(), String.t()) :: {:ok, Enrollment.t()} | {:error, atom()}
  def enroll(user_id, course_id) do
    enrollment = %Enrollment{
      id: Portal.ID.new("ENR"),
      user_id: user_id,
      course_id: course_id,
      progress: 0
    }

    :ok = Portal.Store.put(enrollment)
    {:ok, enrollment}
  end

  @doc "List a user's enrollments."
  @spec courses_of(String.t()) :: [Enrollment.t()]
  def courses_of(user_id) do
    "ENR"
    |> Portal.Store.all()
    |> Enum.filter(&(&1.user_id == user_id))
  end
end
