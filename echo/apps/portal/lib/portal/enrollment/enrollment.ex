defmodule Portal.Enrollment.Enrollment do
  @moduledoc """
  A learner's enrollment in a course (namespace ENR) — the internal Store-projection
  row.

  The dual-write read row the engine projects (`Portal.Engine` mints + stores it after
  a successful append) and `:courses_of` lists. INTERNAL to the `Portal.Enrollment`
  slice: the context maps it to the public `%Portal.Enrollment.Enrolled{}` struct at
  its boundary, so callers never receive this projection row directly.
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
