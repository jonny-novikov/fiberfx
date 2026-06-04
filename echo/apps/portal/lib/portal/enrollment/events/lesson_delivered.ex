defmodule Portal.Enrollment.Events.LessonDelivered do
  @moduledoc """
  A lesson was delivered to a learner (F5.5). A past-tense, immutable fact; see
  `Portal.Enrollment.Events.LearnerEnrolled`. `at` is supplied by the boundary.
  """
  @derive {Jason.Encoder, only: [:user_id, :lesson_id, :at]}
  @enforce_keys [:user_id, :lesson_id, :at]
  defstruct [:user_id, :lesson_id, :at]

  @type t :: %__MODULE__{
          user_id: String.t(),
          lesson_id: String.t(),
          at: DateTime.t()
        }
end
