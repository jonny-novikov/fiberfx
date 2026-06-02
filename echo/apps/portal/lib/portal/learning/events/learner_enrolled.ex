defmodule Portal.Learning.Events.LearnerEnrolled do
  @moduledoc """
  A learner was enrolled in a course (F5.5). A past-tense, immutable fact:
  `Portal.Engine.Core.decide/2` emits it, `evolve/2` folds it. `at` is the
  occurrence time supplied by the boundary — the pure core mints no clock.
  """
  @derive {Jason.Encoder, only: [:user_id, :course_id, :at]}
  @enforce_keys [:user_id, :course_id, :at]
  defstruct [:user_id, :course_id, :at]

  @type t :: %__MODULE__{
          user_id: String.t(),
          course_id: String.t(),
          at: DateTime.t()
        }
end
