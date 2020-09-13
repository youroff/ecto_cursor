# EctoCursor

[![Build Status](https://travis-ci.org/youroff/ecto_cursor.svg?branch=master)](https://travis-ci.org/youroff/ecto_cursor)

This is a fully automatic cursor based pagination for Ecto.
It requires zero configuraion and is aiming to support arbitrary queries:
joins, grouppings with aggregates, etc. Currently complete support is not guaranteed,
as this library is still under development (and I appreciate issues reports on github).

How is this different from other libraries:

* Zero configuration: cursor composed automatically based on ordering
* Cursor is signed and only works with queries with the same ordering clauses
* Group bys and joins are supported from the beginning, cursor can be based on arbitrary expressions appearing in `ORDER BY`, such as aggregates, that are not the part of the output

It's not ready for general use in production. It relies on AST analysis of the queries, and it will most likely crash on many complex queries. For example, it is expected to crash on embedded preloads and some complex select clauses. Has happened to you, I apreciate the example of query with schema in github issues. Thank you!

## Usage

```elixir
defmodule Repo do
  use Ecto.Repo, ....opts
  use EctoCursor
end

page = Repo.paginate(query, %{cursor: str, limit: int, max_limit: int})

%Page{entries: [...], cursor: next} = page
```

## Configuration
Use `EctoCursor, :max_limit` | `:default_limit` config options to set the defaults for cursor params.
It is also possible to pass :max_limit right into params. Defaults are `500` and `50` respectively.

## Validation of cursor
Cursor produced by the query is signed and expected to work only
with the query with exactly the same ordering. Invalid cursor will be simply ignored.

## Generation of cursor
Unlike very first version, where cursor was generated within a separate query,
now it's all happening in one request. This might break with some complex expressions in select clause.
Please report if it's broken for you.

## TODO
* Research supporting backward cursor
* Meaningful support for `{asc|desc}_nulls_{first|last}`

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

