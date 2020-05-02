defmodule TestApp.Migration do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS \"pg_trgm\"", "DROP EXTENSION \"pg_trgm\"")
    execute("CREATE EXTENSION IF NOT EXISTS \"btree_gist\"", "DROP EXTENSION \"btree_gist\"")

    create table(:artists) do
      add :name, :string
    end

    create table(:albums) do
      add :name, :string
      add :year, :integer
      add :artist_id, references(:artists)
    end
  end
end
