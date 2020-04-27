defmodule EctoCursor do
  @moduledoc """
  Documentation for `EctoCursor`.
  """

  alias EctoCursor.{Cursor, Expr}
  import MonEx.Option
  import Ecto.Query

  defmacro __using__(_) do
    quote do
      def paginate(query, opts \\ %{}) do
        if Enum.empty?(query.order_bys) do
          raise "cannot cursor-paginate unordered query"
        end

        opts = Cursor.trim_cursor(opts)
        |> Map.put(:exprs, EctoCursor.Expr.extract(query.order_bys))
        |> Map.put(:module, __MODULE__)
        |> Map.put(:simple, Enum.empty? query.group_bys)

        query = EctoCursor.augument_query(query, opts)
        next = Task.async(fn -> EctoCursor.get_next_cursor(query, opts) end)

        %EctoCursor.Page{
          entries: __MODULE__.all(query),
          cursor: Task.await(next)
        }
      end
    end
  end

  def augument_query(query, %{cursor: nil, limit: l}) do
    limit(query, ^l)
  end

  def augument_query(query, %{cursor: cursor, limit: l} = opts) do
    if length(cursor) != length(opts.exprs) do
      raise "number of values in cursor doesn't match number of ordering clauses"
    end

    clause = Expr.build_clause(opts.exprs, Enum.zip(cursor, Enum.map(opts.exprs, & &1.type)))
    placement = if opts.simple, do: :wheres, else: :havings
    Map.put(query, placement, Map.get(query, placement, []) ++ [clause])
    |> limit(^l)
  end

  def get_next_cursor(query, opts) do
    %{query | select: %Ecto.Query.SelectExpr{
      expr: {:{}, [], Enum.map(opts.exprs, & &1.term)},
      params: Enum.map(opts.exprs, & &1.params) |> Enum.reduce(&Enum.concat/2)
    }}
    |> offset(^(opts.limit - 1))
    |> limit(1)
    |> opts.module.one()
    |> to_option()
    |> MonEx.map(&Tuple.to_list/1)
    |> MonEx.flat_map(&Cursor.encode/1)
    |> get_or_else(nil)
  end
end
