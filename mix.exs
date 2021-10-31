defmodule EctoCursor.MixProject do
  use Mix.Project

  def project, do: [
    app: :ecto_cursor,
    version: "0.1.4",
    elixir: "~> 1.10",
    deps: deps(),
    description: description(),
    package: package()
  ]

  def application, do: [
    extra_applications: [:logger]
  ]

  defp deps, do: [
    {:ecto, "~> 3.0"},
    {:ecto_sql, "~> 3.0"},
    {:postgrex, ">= 0.0.0", optional: true},
    {:dialyxir, "~> 1.1.0", only: :dev, runtime: false},
    {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
  ]

  defp description(), do: """
    A fully automatic cursor pagination for Ecto.
    It relies on analysis of the expressions in order_by clause
    and requires no configuration.
  """

  defp package, do: [
    files: ["lib", "mix.exs", "README*", "LICENSE*"],
    maintainers: ["Ivan Yurov"],
    licenses: ["Apache 2.0"],
    links: %{"GitHub" => "https://github.com/youroff/ecto_cursor"}
   ]
end
