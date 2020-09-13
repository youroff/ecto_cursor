defmodule EctoCursor do
  @moduledoc """
  Documentation for `EctoCursor`.

  This is a fully automatic cursor based pagination for Ecto.
  It requires zero configuraion and is aiming to support arbitrary queries:
  joins, grouppings with aggregates, etc. Currently absolute support is not guaranteed,
  as this library is still under development (I appreciate issues).

  ### Usage

      defmodule YourApp.Repo do
        use Ecto.Repo,
          otp_app: :your_app,
          adapter: Ecto.Adapters.Postgres
        use EctoCursor
      end

  This adds function `paginate` to the Repo:

      params = %{cursor: str limit: int max_limit: int}
      %Page{entries: [...], cursor: next} = Repo.paginate(query, params)

  All parameters are optional, `max_limit` is used to trim client passed limit.
  Missing cursor means the beginning of the stream.

  ### Validation of cursor
  Cursor produced by the query is signed and supposed to work
  with the query with exactly the same ordering. Invalid cursor will be simply ignored.

  ### Generation of cursor
  Unlike very first version, where cursor was generated with a separate request,
  now it's all happening in one call. This might break with some complex expressions in select clause.
  Please report if it's broken for you.

  """

  alias EctoCursor.{Context, Cursor, Expr, Page}
  import Ecto.Query

  defmacro __using__(_) do
    quote do
      @spec paginate(Ecto.Query.t, Cursor.opts()) :: Page.t(Ecto.Schema.t())
      def paginate(query, opts \\ %{}) do
        if Enum.empty?(query.order_bys) do
          raise "cannot cursor-paginate unordered query"
        end

        context = Context.build(query, opts)

        results = EctoCursor.augument_query(query, context)
        |> EctoCursor.append_cursor(context)
        |> __MODULE__.all()

        %Page{
          entries: results |> Enum.map(&elem(&1, 0)),
          cursor: Cursor.compute(results, context)
        }
      end
    end
  end

  @doc """
  Applying condition from the cursor to the query.
  This includes generating additional `where` or `having` clauses and applying a limit.
  """
  @spec augument_query(Ecto.Query.t, Context.t) :: Ecto.Query.t
  def augument_query(query, %{cursor: nil, limit: lim}) do
    limit(query, ^lim)
  end

  def augument_query(query, %{cursor: cursor, limit: lim, placement: placement, exprs: exprs}) do
    params = Enum.zip(cursor, Enum.map(exprs, & &1.type))
    clause = Expr.build_where(exprs, params)
    Map.put(query, placement, Map.get(query, placement, []) ++ [clause])
    |> limit(^lim)
  end

  @doc """
  Injecting next cursor components into the query. This is done by wrapping original (or default)
  select into the tuple `select({original_select, {componen1, component2, ...}})` and potentiall
  can mess up complex queries.
  """
  @spec append_cursor(Ecto.Query.t, Context.t) :: Ecto.Query.t
  def append_cursor(query, ctx) do
    %{query | select: Expr.build_select(ctx.exprs, query.select)}
  end
end
