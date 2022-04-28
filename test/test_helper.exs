Code.require_file("../deps/ecto_sql/integration_test/support/repo.exs", __DIR__)
Code.require_file("test_support.exs", __DIR__)

alias EctoSQL.TestAdapter

defmodule Ecto.Integration.TestRepo do
  use Ecto.Integration.Repo, otp_app: :ecto_sql, adapter: TestAdapter
end

alias Ecto.Integration.TestRepo

defmodule TestPool do
  use TestConnection, pool: DBConnection.ConnectionPool, pool_size: 1

  @doc false
  def pool_type, do: DBConnection.ConnectionPool
end

defmodule TestDatabaseObserver do
  def db_connection_reset_callback(_state) do
    IO.puts("Callback: track connection reset on APM")
  end
end

{:ok, _pid} = TestRepo.start_link()

ExUnit.start()
