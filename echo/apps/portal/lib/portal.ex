defmodule Portal do
  @moduledoc """
  The Portal facade (F6.4-D4/INV2) — the single web-facing surface.

  A THIN module that `defdelegate`s each public function to its context (`Catalog`,
  `Enrollment`, `Accounts`) and owns NO logic: every function body is a bare
  `defdelegate` — zero `case`, zero `with`, zero mapping. Any logic (mapping the
  engine's projection to `%Enrolled{}`, the `enroll_and_welcome/2` `with` chain) lives
  in the CONTEXT it belongs to, never here. This keeps the master invariant honest: the
  web imports one module and the slices stay separate behind it (F6.4-INV2).

  Since F6.4 the facade names CONTEXTS, never `Portal.Engine`. The engine is the
  private write mechanism encapsulated behind `Portal.Enrollment`; the facade reaches
  the domain only through the three contexts' public functions.

  ## Exhaustive consumer sketch

  The closed outcome set is consumed exhaustively — `{:ok, data}` and one branch per
  `Portal.Error` code, with no catch-all, so a new code forces a new branch:

      case Portal.enroll(user_id, course_id) do
        {:ok, enrolled} -> {:created, enrolled}
        {:error, %Portal.Error{code: :already_enrolled}} -> :duplicate
        {:error, %Portal.Error{code: :course_not_found}} -> :no_such_course
        {:error, %Portal.Error{code: :lesson_locked}} -> :locked
        {:error, %Portal.Error{code: :invalid_progress}} -> :bad_progress
      end

  `:lesson_locked` and `:invalid_progress` are reserved (no producers today); the
  sketch still branches on all four so the finite outcome set is closed and complete.
  """

  # ── Enrollment (event-sourced over the EventStore port) ─────────────────────────
  defdelegate enroll(user_id, course_id), to: Portal.Enrollment
  defdelegate deliver_lesson(user_id, lesson_id), to: Portal.Enrollment
  defdelegate courses_of(user_id), to: Portal.Enrollment
  defdelegate progress_of(user_id), to: Portal.Enrollment
  defdelegate enroll_and_welcome(user_id, course_id), to: Portal.Enrollment

  # ── Catalog (Repo-backed Ecto context) ──────────────────────────────────────────
  defdelegate list_courses(), to: Portal.Catalog
  defdelegate search_courses(query), to: Portal.Catalog
  defdelegate get_course!(id), to: Portal.Catalog
  defdelegate fetch_course(id), to: Portal.Catalog
  defdelegate change_course(), to: Portal.Catalog
  defdelegate create_course(attrs), to: Portal.Catalog
  defdelegate lesson(id), to: Portal.Catalog

  # ── Accounts (Store-backed this rung) ───────────────────────────────────────────
  defdelegate user(user_id), to: Portal.Accounts
  defdelegate welcome(user_id), to: Portal.Accounts
end
