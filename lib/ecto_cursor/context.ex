defmodule EctoCursor.Context do
  @moduledoc false
  defstruct [:limit, :cursor, :exprs, :signature, :placement]

  alias EctoCursor.{Expr, Cursor}

  @type t :: %__MODULE__{
    cursor: [any],
    limit: integer,
    exprs: [Expr.t],
    signature: binary,
    placement: :wheres | :havings
  }

  @spec build(Ecto.Query.t, Cursor.opts) :: t
  def build(query, opts) do
    signature = :crypto.hash(:sha256, :erlang.term_to_binary(query.order_bys))

    %__MODULE__{
      cursor: Cursor.extract_cursor(opts, signature),
      limit: Cursor.extract_limit(opts),
      exprs: Expr.extract(query.order_bys),
      signature: signature,
      placement: Enum.empty?(query.group_bys) && :wheres || :havings
    }
  end
end
