Logger.configure(level: :info)

Application.put_env(:ecto, :primary_key_type, :id)
Application.put_env(:ecto, :async_integration_tests, true)
Application.put_env(:ecto_sql, :lock_for_update, "FOR UPDATE")

Code.require_file "./app/repo.exs", __DIR__

Application.put_env(:test_app, TestApp.Repo,
  url: "postgres://postgres:postgres@localhost/ecto_cursor_test",
  database: "ecto_cursor_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true
)

Code.require_file "./app/migration.exs", __DIR__

{:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(TestApp.Repo.config(), :temporary)
_   = Ecto.Adapters.Postgres.storage_down(TestApp.Repo.config())
:ok = Ecto.Adapters.Postgres.storage_up(TestApp.Repo.config())
{:ok, _pid} = TestApp.Repo.start_link()

:ok = Ecto.Migrator.up(TestApp.Repo, 0, TestApp.Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(TestApp.Repo, :auto)
ExUnit.start()
