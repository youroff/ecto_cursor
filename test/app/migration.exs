defmodule TestApp.Migration do
  use Ecto.Migration

  def change do
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
