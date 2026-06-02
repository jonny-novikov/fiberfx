defmodule Portal.Error do
  @moduledoc """
  Closed vocabulary of expected domain failures (F5.4). An expected failure is
  `{:error, %Portal.Error{}}` whose `code` is from a small closed set the web maps
  to 4xx. Impossible states (progress outside 0..100) are NOT modelled here — they crash.
  F5.4 seeds the set at :course_not_found | :already_enrolled; F5.8 extends the union,
  adds an optional :field, and threads it through the Portal facade (additively).
  """
  @enforce_keys [:code, :message]
  defstruct [:code, :message]
  @type code :: :course_not_found | :already_enrolled
  @type t :: %__MODULE__{code: code(), message: String.t()}

  @spec new(code()) :: t()
  def new(code), do: %__MODULE__{code: code, message: message(code)}

  @spec message(code()) :: String.t()
  defp message(:course_not_found), do: "course not found"
  defp message(:already_enrolled), do: "already enrolled in this course"
end
