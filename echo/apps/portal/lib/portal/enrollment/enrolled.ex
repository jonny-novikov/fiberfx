defmodule Portal.Enrollment.Enrolled do
  @moduledoc """
  The PUBLISHED enrollment struct (F6.4-D2) — the public shape `Portal.Enrollment`
  returns to callers.

  `Portal.Enrollment` is event-sourced through the `Portal.EventStore` port, so this
  is NEVER an Ecto schema (the catalog is Repo-backed; enrollment is not — F6.4-INV4).
  The context maps the engine's internal `%Portal.Enrollment.Enrollment{}` projection
  row to this struct at the `enroll/2` + `courses_of/1` boundary, so the published
  shape stays distinct from the internal Store row. `@derive Jason.Encoder` keeps the
  web layer dumb — the struct serializes itself.
  """
  @derive {Jason.Encoder, only: [:id, :user_id, :course_id, :progress]}
  @enforce_keys [:id, :user_id, :course_id]
  defstruct [:id, :user_id, :course_id, progress: 0]

  @type t :: %__MODULE__{
          id: String.t(),
          user_id: String.t(),
          course_id: String.t(),
          progress: 0..100
        }
end
