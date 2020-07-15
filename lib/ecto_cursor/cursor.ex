defmodule EctoCursor.Cursor do
  @moduledoc false

  @max_limit Application.get_env(EctoCursor, :max_limit, 500)
  @default_limit Application.get_env(EctoCursor, :default_limit, 50)

  @type opts :: %{
    optional(:cursor) => String.t,
    optional(:limit) => integer,
    optional(:max_limit) => integer
  }

  @doc """
  Getting the limit from options while trimming it at the same time if needed.
  Use EctoCursor, :max_limit | :default_limit config options to set the defaults.
  It is also possible to pass :max_limit right into configuration map,
  which is useful to prevent attacks per query.
  """
  @spec extract_limit(opts) :: integer
  def extract_limit(opts) do
    Map.get(opts, :limit, @default_limit)
    |> min(Map.get(opts, :max_limit, @max_limit))
  end

  @doc """
  This function extracts the cursor from parameters and validates it
  against the query signature. Whenever cursor is missing or invalid,
  nil is returned, which essentially means getting back to the top.
  """
  @spec extract_cursor(opts, <<_::256>>) :: [any] | nil
  def extract_cursor(opts, sig) do
    try do
      with token when not is_nil(token) <- Map.get(opts, :cursor),
        <<mac::binary-size(32), cur::binary>> <- Base.url_decode64!(token),
        ^mac <- :crypto.hash(:sha256, sig <> cur)
      do
        :erlang.binary_to_term(cur, [:safe])
      else
        _ -> nil
      end
    rescue
      _ -> nil
    end
  end

  @doc """
  Returns the new cursor or nil, if the amount of results was below the limit.
  Cursor is signed and only compatible with this particular query, which
  is established by the hash of 'order_by' clauses.
  """
  @spec compute([{any, [any]}], EctoCursor.Context.t) :: String.t | nil
  def compute(results, %{limit: lim, signature: sig}) do
    case Enum.at(results, lim - 1) do
      {_, cursor} ->
        cur = :erlang.term_to_binary(cursor)
        mac = :crypto.hash(:sha256, sig <> cur)
        Base.url_encode64(mac <> cur)
      _ -> nil
    end
  end
end
