defmodule EctoCursor.Cursor do
  @moduledoc false

  defstruct [:next, :limit]
  import MonEx.{Option, Result}

  @max_limit 500
  @default_limit 50

  def trim_cursor(opts \\ %{}) do
    Map.update(opts, :limit, @default_limit, &min(&1, Map.get(opts, :max_limit, @max_limit)))
    |> Map.update(:cursor, nil, &get_or_else(decode(&1), nil))
  end

  def encode(nil) do
    none()
  end

  def encode(t) do
    :erlang.term_to_binary(t)
    |> Base.url_encode64()
    |> some()
  end

  def decode(nil) do
    none()
  end

  def decode(cursor) do
    try do
      Base.url_decode64!(cursor)
      |> :erlang.binary_to_term([:safe])
      |> some()
    rescue
      _ -> none()
    end
  end
end
