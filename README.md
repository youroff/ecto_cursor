# EctoCursor

This is an experimental library for cursor (keyset) based pagination for Ecto. How is this different from other libraries:

* Zero configuration: cursor composed automatically based on ordering
* Group bys and joins are supported from the beginning, cursor can be based on arbitrary expressions appearing in `ORDER BY`, such as aggregates, that are not the part of the output

It's not ready for general use in production. It relies on AST analysis of the queries, and it will most likely crash on many complex queries. I this happened to you, I will apreciate the example of query with schema in issues. Thank you!

## Usage

```elixir
defmodule Repo do
  use Ecto.Repo, ....opts
  use EctoCursor
end

Repo.paginate(query, %{cursor: str, limit: int, max_limit: int})
```

## To do

- Validation of cursor token by query hash
- Configuration for default values
- Removing Runtime errors

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_cursor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_cursor, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ecto_cursor](https://hexdocs.pm/ecto_cursor).

