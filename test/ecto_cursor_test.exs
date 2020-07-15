defmodule EctoCursorTest do
  use ExUnit.Case
  import Ecto.Query
  alias TestApp.{Repo, Artist, Album}
  alias EctoCursor.Page

  setup_all do
    artists = Enum.zip(1..3, ~w(A C B))
    Repo.insert_all(Artist, Enum.map(artists, fn {id, name} -> %{id: id, name: name} end))
    Repo.insert_all(Album, [
      %{name: "Aa", year: 2012, artist_id: 1},
      %{name: "Ab", year: 2001, artist_id: 1},
      %{name: "Ac", year: 2020, artist_id: 1},
      %{name: "Ba", year: 1995, artist_id: 2},
      %{name: "Bb", year: 2020, artist_id: 2},
      %{name: "Ca", year: 2001, artist_id: 3},
      %{name: "Cb", year: 2002, artist_id: 3},
      %{name: "Cc", year: 2003, artist_id: 3},
      %{name: "Cd", year: 2004, artist_id: 3}
    ])
    :ok
  end

  test "simple case" do
    query = order_by(Artist, asc: :name)
    assert %Page{cursor: c1, entries: [%{name: "A"}]} = Repo.paginate(query, %{limit: 1})
    assert %Page{cursor: c2, entries: [%{name: "B"}]} = Repo.paginate(query, %{cursor: c1, limit: 1})
    assert %Page{cursor: c3, entries: [%{name: "C"}]} = Repo.paginate(query, %{cursor: c2, limit: 1})
    assert %Page{cursor: nil, entries: []} = Repo.paginate(query, %{cursor: c3, limit: 1})
  end

  test "with join" do
    query = Artist
    |> join(:left, [a], b in assoc(a, :albums))
    |> order_by([a, b], asc: a.id, desc: b.name)
    |> select([a, b], %{a: a.name, b: b.name, c: b.year})

    assert %Page{cursor: c1, entries: [album | _]} = Repo.paginate(query, %{limit: 4})
    assert album.a == "A" && album.b == "Ac"

    assert %Page{cursor: c2, entries: [album | _]} = Repo.paginate(query, %{cursor: c1, limit: 4})
    assert album.a == "C" && album.b == "Ba"

    assert %Page{cursor: c3, entries: rest} = Repo.paginate(query, %{cursor: c2, limit: 4})
    assert length(rest) == 1
    assert is_nil(c3)
  end

  test "with count and select_merge" do
    query = from artist in Artist,
      join: album in assoc(artist, :albums),
      group_by: artist.id,
      order_by: [desc: artist.name, asc: artist.id],
      select_merge: %{album_count: count(album)}

    assert %Page{cursor: c1, entries: [artist | _]} = Repo.paginate(query, %{limit: 2})
    assert artist.name == "C" && artist.album_count == 2

    assert %Page{cursor: c2, entries: [artist]} = Repo.paginate(query, %{cursor: c1, limit: 2})
    assert artist.name == "A" && artist.album_count == 3
  end

  test "with group by and max aggregate" do
    year = 2000
    query = from artist in Artist,
      join: album in assoc(artist, :albums),
      group_by: artist.id,
      order_by: [desc: max(album.year), asc: artist.id],
      having: max(album.year) > ^year,
      select: %{id: artist.id, name: artist.name, year: max(album.year)}

    assert %Page{cursor: c1, entries: [%{id: 1, year: 2020}]} = Repo.paginate(query, %{limit: 1})
    assert %Page{cursor: c2, entries: [%{id: 2, year: 2020}]} = Repo.paginate(query, %{cursor: c1, limit: 1})
    assert %Page{cursor: c3, entries: [%{id: 3, year: 2004}]} = Repo.paginate(query, %{cursor: c2, limit: 1})
    assert %Page{cursor: nil, entries: []} = Repo.paginate(query, %{cursor: c3, limit: 1})
  end

  test "with fragment similarity" do
    term = "Ab"

    query = Album
    |> order_by([a], desc: fragment("similarity(?, ?)", ^term, a.name), asc: a.id)
    |> select([a], %{a: a.id, b: a.name})

    assert %Page{cursor: c1, entries: [%{a: 2, b: ^term}]} = Repo.paginate(query, %{limit: 1})
    assert %Page{cursor: _, entries: [%{a: 1, b: "Aa"}]} = Repo.paginate(query, %{cursor: c1, limit: 1})
  end
end
