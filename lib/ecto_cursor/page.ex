defmodule EctoCursor.Page do
  @moduledoc false

  @type t(model) :: %__MODULE__{
    entries: [model],
    cursor: String.t | nil
  }

  defstruct [:entries, :cursor]
end
