defmodule EctoCursorTest.Cursor do
  use ExUnit.Case
  alias EctoCursor.Cursor

  test "extracting limit" do
    assert 50 = Cursor.extract_limit(%{})
    assert 500 = Cursor.extract_limit(%{limit: 5000})
    assert 1000 = Cursor.extract_limit(%{limit: 5000, max_limit: 1000})
  end

  test "extracting cursor" do
    right_sig = <<0::256>>
    wrong_sig = <<1::256>>
    broken_sig = <<0::254, 1>>
    cur = :erlang.term_to_binary(["A", 1])
    mac = :crypto.hash(:sha256, right_sig <> cur)
    cursor = Base.url_encode64(mac <> cur)

    refute Cursor.extract_cursor(%{}, right_sig)
    refute Cursor.extract_cursor(%{cursor: cursor}, wrong_sig)
    refute Cursor.extract_cursor(%{cursor: cursor}, broken_sig)
    assert ["A", 1] = Cursor.extract_cursor(%{cursor: cursor}, right_sig)
  end

  test "computing cursor" do
    sig = <<0::256>>
    results = [
      {1, ["A", 1]},
      {2, ["A", 2]},
      {3, ["A", 3]}
    ]
    refute Cursor.compute(results, %{limit: 4, signature: sig})
    assert cursor = Cursor.compute(results, %{limit: 3, signature: sig})
    assert ["A", 3] = Cursor.extract_cursor(%{cursor: cursor}, sig)
  end
end
