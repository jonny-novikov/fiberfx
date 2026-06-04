defmodule Portal.Error do
  @moduledoc """
  Closed vocabulary of expected domain failures (F5.4, extended F5.8). An expected
  failure is `{:error, %Portal.Error{}}` whose `code` is from a small closed set the
  web maps to 4xx. Impossible states (progress outside 0..100) are NOT modelled here
  — they crash.

  F5.4 seeded the set at `:course_not_found | :already_enrolled`; F5.8 closes the
  union at four codes, adds an optional `:field`, and adds `from/1`. The union is
  **final at four**, but only `:course_not_found` and `:already_enrolled` have
  producers today (from `Portal.Engine.Core.authorize/2`); `:lesson_locked` and
  `:invalid_progress` are **reserved** — no deliver-lesson gate or progress
  validation exists yet, so no producer is added for them (F5.8-INV3). `from/1` maps
  all four with **no catch-all**, so an unmapped reason fails to match and surfaces
  as a bug rather than leaking, and a later producer needs no `from/1` change.
  """
  @enforce_keys [:code, :message]
  defstruct [:code, :message, :field]

  @type code ::
          :already_enrolled
          | :course_not_found
          | :lesson_locked
          | :invalid_progress
          | :invalid
  @type t :: %__MODULE__{code: code(), message: String.t(), field: atom() | nil}

  @doc ~S'''
  Builds a closed-vocabulary error from its code, attaching the human-readable message.

      iex> Portal.Error.new(:already_enrolled)
      %Portal.Error{code: :already_enrolled, message: "already enrolled in this course"}
  '''
  @spec new(code()) :: t()
  def new(code), do: %__MODULE__{code: code, message: message(code)}

  @doc ~S'''
  Maps an internal failure reason to a closed `%Portal.Error{}` — one clause per
  code, with **no catch-all** (F5.8-INV3). An unmapped reason raises
  `FunctionClauseError` rather than leaking untyped. All four codes are mapped even
  though two are reserved (no producers today), so adding a producer later needs no
  change here.

      iex> Portal.Error.from(:course_not_found)
      %Portal.Error{code: :course_not_found, message: "course not found"}
  '''
  @spec from(code()) :: t()
  def from(:already_enrolled), do: new(:already_enrolled)
  def from(:course_not_found), do: new(:course_not_found)
  def from(:lesson_locked), do: new(:lesson_locked)
  def from(:invalid_progress), do: new(:invalid_progress)

  @doc ~S'''
  Bridges a failed `%Ecto.Changeset{}` into the closed `%Portal.Error{}` vocabulary
  (F6.3-D5 / INV2), so a caller receives the closed contract — never a raw changeset.
  A SEPARATE entry point from `from/1`: a changeset is not a `code`, so folding it
  into `from/1` would breach that function's no-catch-all closedness (F5.8-INV3).
  `code` is `:invalid`; `field` is the first errored field; `message` is the first
  error with its `%{...}` placeholders interpolated.

      iex> %{title: "ab", slug: "s"}
      ...> |> Portal.Catalog.Course.changeset()
      ...> |> Portal.Error.from_changeset()
      ...> |> Map.take([:code, :field])
      %{code: :invalid, field: :title}
  '''
  @spec from_changeset(Ecto.Changeset.t()) :: t()
  def from_changeset(%Ecto.Changeset{} = changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    {field, [message | _]} = Enum.at(errors, 0)
    %__MODULE__{code: :invalid, field: field, message: message}
  end

  @spec message(code()) :: String.t()
  defp message(:already_enrolled), do: "already enrolled in this course"
  defp message(:course_not_found), do: "course not found"
  defp message(:lesson_locked), do: "lesson locked"
  defp message(:invalid_progress), do: "invalid progress"
  defp message(:invalid), do: "invalid"
end
