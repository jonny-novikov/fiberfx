defmodule Portal.Catalog.Course do
  @moduledoc "A course in the catalog (namespace CRS)."
  @derive {Jason.Encoder, only: [:id, :title, :slug]}
  @enforce_keys [:id, :title, :slug]
  defstruct [:id, :title, :slug]

  @type t :: %__MODULE__{id: String.t(), title: String.t(), slug: String.t()}
end
