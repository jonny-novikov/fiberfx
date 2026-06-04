defmodule Portal.Enrollment.Progress do
  @moduledoc "A learner's progress through a lesson (namespace PRG)."
  @derive {Jason.Encoder, only: [:id, :enrollment_id, :lesson_id, :percent]}
  @enforce_keys [:id, :enrollment_id, :lesson_id, :percent]
  defstruct [:id, :enrollment_id, :lesson_id, :percent]

  @type t :: %__MODULE__{
          id: String.t(),
          enrollment_id: String.t(),
          lesson_id: String.t(),
          percent: 0..100
        }
end
