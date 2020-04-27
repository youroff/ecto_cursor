defmodule TestApp.Repo do
  use Ecto.Repo,
    otp_app: :test_app,
    adapter: Ecto.Adapters.Postgres
  use EctoCursor
end

defmodule TestApp.Artist do
  use Ecto.Schema

  schema "artists" do
    field :name, :string
    has_many :albums, TestApp.Album
  end
end

defmodule TestApp.Album do
  use Ecto.Schema

  schema "albums" do
    field :name, :string
    field :year, :integer
    belongs_to :artist, TestApp.Artist
  end
end
