defmodule TestConnection do
  defmacro __using__(_opts) do
    quote do
      def disconnect_all(_pool, _checkout_count, _opts2 \\ []) do
        :ok
      end
    end
  end
end

defmodule MigrationsAgent do
  use Agent
  alias __MODULE__, as: MA

  def start_link(versions) do
    Agent.start_link(fn -> versions end, name: MA)
  end

  def get do
    Agent.get(MA, & &1)
  end

  def up(version, opts) do
    Agent.update(MA, &[{version, opts[:prefix]} | &1])
  end

  def down(version, opts) do
    Agent.update(MA, &List.delete(&1, {version, opts[:prefix]}))
  end
end

defmodule EctoSQL.TestAdapter do
  @behaviour Ecto.Adapter
  @behaviour Ecto.Adapter.Queryable
  @behaviour Ecto.Adapter.Schema
  @behaviour Ecto.Adapter.Transaction
  @behaviour Ecto.Adapter.Migration

  defmacro __before_compile__(_opts), do: :ok
  def ensure_all_started(_, _), do: {:ok, []}

  def init(_opts) do
    child_spec =
      Supervisor.child_spec({Task, fn -> :timer.sleep(:infinity) end}, [])

    {:ok, child_spec, %{meta: :meta}}
  end

  def checkout(_, _, _), do: raise("not implemented")
  def checked_out?(_), do: raise("not implemented")
  def delete(_, _, _, _), do: raise("not implemented")
  def insert_all(_, _, _, _, _, _, _, _), do: raise("not implemented")
  def rollback(_, _), do: raise("not implemented")
  def stream(_, _, _, _, _), do: raise("not implemented")
  def update(_, _, _, _, _, _), do: raise("not implemented")

  ## Types

  def loaders(_primitive, type), do: [type]
  def dumpers(_primitive, type), do: [type]
  def autogenerate(_), do: nil

  ## Queryable

  def prepare(operation, query), do: {:nocache, {operation, query}}

  # Migration emulation

  def execute(
        _,
        _,
        {:nocache, {:all, %{from: %{source: {"schema_migrations", _}}}}},
        _,
        opts
      ) do
    true = opts[:schema_migration]
    versions = MigrationsAgent.get()
    {length(versions), Enum.map(versions, &[elem(&1, 0)])}
  end

  def execute(
        _,
        _meta,
        {:nocache, {:delete_all, %{from: %{source: {"schema_migrations", _}}}}},
        [version],
        opts
      ) do
    true = opts[:schema_migration]
    MigrationsAgent.down(version, opts)
    {1, nil}
  end

  def insert(_, %{source: "schema_migrations"}, val, _, _, opts) do
    true = opts[:schema_migration]
    version = Keyword.fetch!(val, :version)
    MigrationsAgent.up(version, opts)
    {:ok, []}
  end

  def in_transaction?(_), do: Process.get(:in_transaction?) || false

  def transaction(mod, _opts, fun) do
    Process.put(:in_transaction?, true)
    send(test_process(), {:transaction, mod, fun})
    {:ok, fun.()}
  after
    Process.put(:in_transaction?, false)
  end

  ## Migrations

  def lock_for_migrations(mod, opts, fun) do
    send(test_process(), {:lock_for_migrations, mod, fun, opts})
    fun.()
  end

  def execute_ddl(_, command, _) do
    Process.put(:last_command, command)
    {:ok, []}
  end

  def supports_ddl_transaction? do
    get_config(:supports_ddl_transaction?, false)
  end

  defp test_process do
    get_config(:test_process, self())
  end

  defp get_config(name, default) do
    :ecto_sql
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(name, default)
  end
end
