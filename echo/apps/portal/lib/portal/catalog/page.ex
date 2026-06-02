defmodule Portal.Catalog.Page do
  @moduledoc "A page of content within a lesson (namespace PGE)."
  @derive {Jason.Encoder, only: [:id, :lesson_id, :body]}
  @enforce_keys [:id, :lesson_id, :body]
  defstruct [:id, :lesson_id, :body]

  @type t :: %__MODULE__{id: String.t(), lesson_id: String.t(), body: String.t()}
end
