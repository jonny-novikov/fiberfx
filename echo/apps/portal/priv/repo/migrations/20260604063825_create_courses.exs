defmodule Portal.Repo.Migrations.CreateCourses do
  use Ecto.Migration

  # F6.3-D2 / INV3 — :courses with an explicit :bigint Snowflake id the Portal mints
  # itself (autogenerate: false). `primary_key: false` drops Ecto's default :id so
  # `add :id, :bigint, primary_key: true` is the canonical integer the branded-string
  # surface (Portal.Catalog.CourseID) decodes to. The branded string is NEVER a
  # column — only the transport/surface form.
  def change do
    create table(:courses, primary_key: false) do
      add(:id, :bigint, primary_key: true)
      add(:title, :string, null: false)
      add(:slug, :string, null: false)
      add(:published, :boolean, null: false, default: false)

      timestamps(type: :utc_datetime)
    end

    # The changeset's unique_constraint(:title) (F6.3-D4) surfaces a duplicate-title
    # write as a changeset error rather than a raw Postgrex error.
    create(unique_index(:courses, [:title]))
  end
end
