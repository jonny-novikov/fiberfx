defmodule Portal.Catalog.Lesson do
  @moduledoc "A lesson within a course (namespace LSN)."
  @derive {Jason.Encoder, only: [:id, :course_id, :title]}
  @enforce_keys [:id, :course_id, :title]
  defstruct [:id, :course_id, :title]

  @type t :: %__MODULE__{id: String.t(), course_id: String.t(), title: String.t()}
end
