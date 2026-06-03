defmodule Portal.Learning do
  @moduledoc """
  The Learning bounded context — enrollments and progress.

  `enroll/2` is a contract (F5.4): it parses its references at the door, confirms
  the course exists and the learner is not already enrolled, and only then mints
  an `ENR` id and stores `%Enrollment{progress: 0}`. Expected failures are
  `{:error, %Portal.Error{}}` with a code from a closed set; impossible states
  (progress outside `0..100`) crash rather than return a tuple. Owns its entities;
  references other contexts only by branded id.

  Post-F5.6 the live write path runs through the `Portal.Engine` command shell,
  which gates on the pure core's `authorize/2` (against the folded log), records a
  `%LearnerEnrolled{}` event, and projects the Store `%Enrollment{}` the unchanged
  web reads (the shell mints + stores the row inline, without re-running this
  contract — a single admissibility gate, no torn write). `courses_of/1` is the
  read projection behind the engine's `:courses_of` query. The contract here is
  therefore the direct-call surface (kept for `Portal.LearningTest`) and the shape
  the shell's projection mirrors — not dead code.
  """
  alias Portal.Error
  alias Portal.Learning.Enrollment

  @doc """
  Enroll a user in a course.

  Parses the references and checks the preconditions before any effect: each id is
  a well-formed branded id of the right namespace, the course exists, and the
  learner is not already enrolled. A rejected enroll mints nothing and writes
  nothing — only the success branch mints an `ENR` id and stores the enrollment.
  Returns `{:ok, %Enrollment{progress: 0}}` or `{:error, %Portal.Error{}}` with
  code `:course_not_found` (malformed/unknown reference) or `:already_enrolled`.
  """
  @spec enroll(String.t(), String.t()) :: {:ok, Enrollment.t()} | {:error, Error.t()}
  def enroll(user_id, course_id) do
    with :ok <- check_ref(user_id, "USR"),
         :ok <- check_ref(course_id, "CRS"),
         {:ok, _course} <- course_exists(course_id),
         :ok <- not_already_enrolled(user_id, course_id) do
      enrollment = %Enrollment{
        id: Portal.ID.new("ENR"),
        user_id: user_id,
        course_id: course_id,
        progress: 0
      }

      :ok = Portal.Store.put(enrollment)
      {:ok, enrollment}
    end
  end

  # A well-formed branded id of the expected namespace. `valid?/1` enforces the full
  # 14-char format (a bare "USR1" passes `namespace/1` but fails here); `namespace/1`
  # confirms the right kind. A malformed/wrong-namespace ref folds into :course_not_found.
  defp check_ref(id, namespace) do
    if Portal.ID.valid?(id) and Portal.ID.namespace(id) == namespace,
      do: :ok,
      else: {:error, Error.new(:course_not_found)}
  end

  defp course_exists(course_id) do
    case Portal.Catalog.course(course_id) do
      {:ok, course} -> {:ok, course}
      :error -> {:error, Error.new(:course_not_found)}
    end
  end

  defp not_already_enrolled(user_id, course_id) do
    if Enum.any?(courses_of(user_id), &(&1.course_id == course_id)),
      do: {:error, Error.new(:already_enrolled)},
      else: :ok
  end

  @doc "List a user's enrollments."
  @spec courses_of(String.t()) :: [Enrollment.t()]
  def courses_of(user_id) do
    "ENR"
    |> Portal.Store.all()
    |> Enum.filter(&(&1.user_id == user_id))
  end
end
