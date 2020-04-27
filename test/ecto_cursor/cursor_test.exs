defmodule EctoCursorTest.Cursor do
  use ExUnit.Case
  alias EctoCursor.Cursor
  import MonEx.Option

  test "trimming" do
    assert %{limit: 50} = Cursor.trim_cursor()
    assert %{limit: 500} = Cursor.trim_cursor(%{limit: 5000})

    some(cursor) = Cursor.encode([1, "A"])
    assert %{cursor: [1, "A"]} = Cursor.trim_cursor(%{cursor: cursor})
    assert %{cursor: nil} = Cursor.trim_cursor(%{cursor: "SOMEBS"})
  end
end
