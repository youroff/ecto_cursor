defmodule EctoCursor.MixProject do
  use Mix.Project

  def project, do: [
    app: :ecto_cursor,
    version: "0.1.0",
    elixir: "~> 1.10",
    licenses: ,
    deps: deps(),
    description: description()
  ]

  def application, do: [
    extra_applications: [:logger]
  ]

  defp deps, do: [
    {:ecto, "~> 3.0"},
    {:ecto_sql, "~> 3.0"},
    {:postgrex, ">= 0.0.0", optional: true},
    {:monex, "~> 0.1"}
  ]

  defp description(), do: """
    This is a fully automatic cursor (keyset) based pagination for Ecto.
    It supports (or eventually will support) arbtrary expressions in order_by clause.
    Currently it's purely experimental (see tests for test cases that are definitely supported).
  """

  defp package, do: [
    files: ["lib", "mix.exs", "README*", "LICENSE*"],
    maintainers: ["Ivan Yurov"],
    licenses: ["Apache 2.0"],
    links: %{"GitHub" => "https://github.com/youroff/ecto_cursor"}
   ]
end
