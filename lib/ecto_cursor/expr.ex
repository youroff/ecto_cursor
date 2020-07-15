defmodule EctoCursor.Expr do
  @moduledoc false

  defstruct [:term, :dir, :type, :params]

  @type ast :: {atom | ast, [any], [ast]}
  @type dir :: :desc | :desc_nulls_last | :desc_nulls_first | :asc | :asc_nulls_last | :asc_nulls_first

  @type t :: %__MODULE__{
    term: ast,
    dir: dir,
    type: any,
    params: [any]
  }

  def extract(exprs, expr_acc \\ [])

  def extract([], expr_acc) do
    expr_acc
  end

  def extract([%{expr: exprs, params: params} | rest], expr_acc) do
    extract(rest, expr_acc ++ split_params(exprs, params))
  end

  def build_where(exprs, params) do
    {tree, _} = Enum.zip(exprs, params)
    |> Enum.reduce({[], []}, fn {expr, param}, {acc, params_acc} ->
      current = Enum.reverse([build_comp(op(expr), expr, param) | params_acc])
      {[current | acc], [build_comp(:==, expr, param) | params_acc]}
    end)

    {clause_expr, clause_params} = Enum.reverse(tree)
    |> Enum.map(fn ands ->
      Enum.map(ands, & {&1.term, &1.params})
      |> Enum.reduce(comp_reducer(:and))
    end)
    |> Enum.reduce(comp_reducer(:or))

    %Ecto.Query.BooleanExpr{
      expr: clause_expr,
      params: clause_params,
      op: :and
    }
  end

  def build_select(exprs, select) do
    original_select = select || %Ecto.Query.SelectExpr{expr: {:&, [], [0]}}

    cursor_components = Enum.map(exprs, & &1.term)
    cursor_params = Enum.map(exprs, & &1.params) |> Enum.reduce(&Enum.concat/2)

    %{original_select |
      expr: {:{}, [], [original_select.expr, cursor_components]},
      params: original_select.params ++ cursor_params
    }
  end

  defp split_params([], _), do: []

  defp split_params([{dir, expr} | rest], params) do
    {term, fvs} = reset_free_vars(expr)
    [%__MODULE__{
      term: term,
      dir: dir,
      params: Enum.take(params, fvs),
      type: to_type(term)
    } | split_params(rest, Enum.drop(params, fvs))]
  end

  defp reset_free_vars(term, offset \\ 0)

  defp reset_free_vars({:^, meta, [v]}, offset) when is_integer(v) do
    {{:^, meta, [offset]}, offset + 1}
  end

  defp reset_free_vars({op, meta, children}, offset) do
    {op, offset} = reset_free_vars(op, offset)
    {children, offset} = Enum.reduce(children, {[], offset}, fn t, {ts, os} ->
      {t, os} = reset_free_vars(t, os)
      {[t | ts], os}
    end)
    {{op, meta, Enum.reverse(children)}, offset}
  end

  defp reset_free_vars({t, e}, o) do
    {op, offset} = reset_free_vars(e, o)
    {{t, op}, offset}
  end

  defp reset_free_vars(t, o), do: {t, o}

  # This is a huuuuuge TODO, but can be mitigated by coalesce in expression
  defp op(%{dir: :desc}), do: :<
  defp op(%{dir: :desc_nulls_last}), do: :<
  defp op(%{dir: :desc_nulls_first}), do: :<
  defp op(%{dir: :asc}), do: :>
  defp op(%{dir: :asc_nulls_last}), do: :>
  defp op(%{dir: :asc_nulls_first}), do: :>
  defp op(_), do: :>

  defp build_comp(op, expr, var) do
    %{expr |
      params: expr.params ++ [var],
      term: {op, [], [expr.term, {:^, [], [length(expr.params)]}]}
    }
  end

  defp comp_reducer(op), do: fn {term, params}, {term_acc, params_acc} ->
    {{op, [], [term_acc, shift_vars(term, length(params_acc))]}, params_acc ++ params}
  end

  defp shift_vars({:^, meta, [v]}, offset) when is_integer(v) do
    {:^, meta, [v + offset]}
  end

  defp shift_vars({op, meta, children}, offset) do
    {shift_vars(op, offset), meta, Enum.map(children, &shift_vars(&1, offset))}
  end

  defp shift_vars(node, _) do
    node
  end

  # Regular binding
  defp to_type({{:., _, [{:&, _, [binding]}, field]}, _, _}) do
    {binding, field}
  end

  # Not sure if this possibly can appear
  defp to_type({:type, _, [{:^, _, [arg]}, type]}) do
    {arg, type}
  end

  defp to_type({:count, _, _}) do
    :integer
  end

  defp to_type(_) do
    :any
  end
end
