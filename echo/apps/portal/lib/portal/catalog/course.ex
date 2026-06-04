defmodule Portal.Catalog.Course do
  @moduledoc """
  A course in the catalog (namespace CRS). Ecto schema over the `:courses` table (F6.3).

  The `:id` SURFACE is the branded `"CRS"`+Base62 string (the frozen `Portal.ID`
  convention) bridged to the `:bigint` column by the `Portal.Catalog.CourseID` custom
  type (F6.3-INV3) — the branded string is never a column. The struct stays
  constructable in the in-memory `Portal.Store` path: `%Course{}` built with
  id+title+slug is a plain struct the Store holds by branded id, never touching Repo.

  `@enforce_keys [:id, :title, :slug]` is declared BEFORE the schema block so
  Ecto.Schema honours it (Ecto auto-defines only defstruct, not enforce_keys),
  preserving the entities_test guard that omitting `:slug` raises at build time.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :title, :slug]}
  @enforce_keys [:id, :title, :slug]
  @primary_key {:id, Portal.Catalog.CourseID, autogenerate: false}

  schema "courses" do
    field(:title, :string)
    field(:slug, :string)
    field(:published, :boolean, default: false)

    timestamps(type: :utc_datetime)
  end

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          slug: String.t(),
          published: boolean(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc """
  The parse-don't-validate boundary (F6.3-D4 / INV2): turns untrusted attrs into a
  typed `%Ecto.Changeset{}`. `:id` is NOT cast — it is minted by the engine and set
  on the struct, never taken from untrusted input. `:published` is cast but not
  required (defaults false). `unique_constraint(:title)` surfaces a duplicate-title
  insert as a changeset error (via the courses_title_index), not a raw DB error.
  """
  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(course \\ struct(__MODULE__, %{}), attrs) do
    course
    |> cast(attrs, [:title, :slug, :published])
    |> validate_required([:title, :slug])
    |> validate_length(:title, min: 3)
    |> unique_constraint(:title)
  end

  @doc """
  A composable query for the published courses (F6.3-D6 / INV5). Returns an
  `Ecto.Queryable` — run it with `Portal.Repo.all/1`. Pure builder, DB-free to
  construct (only `Repo.all` touches the DB).
  """
  @spec published(Ecto.Queryable.t()) :: Ecto.Query.t()
  def published(query \\ __MODULE__) do
    import Ecto.Query
    from(c in query, where: c.published == true)
  end
end
