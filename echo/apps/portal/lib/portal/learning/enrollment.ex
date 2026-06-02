defmodule Portal.Learning.Enrollment do
  @moduledoc "A learner's enrollment in a course (namespace ENR)."
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
