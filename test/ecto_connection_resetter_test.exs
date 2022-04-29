defmodule EctoConnectionResetterTest do
  use ExUnit.Case

  import Mock

  alias Ecto.Integration.TestRepo

  doctest EctoConnectionResetter

  setup do
    params = %{
      cycle_mins: 1,
      close_interval: 1,
      repo: TestRepo,
      pool: TestPool,
      verbose: false
    }

    [params: params]
  end

  describe "init/1" do
    test "inits EctoConnectionResetter", %{params: params} do
      assert {:ok,
              %{
                cycle_mins: 1,
                close_interval: 1,
                repo: TestRepo,
                pool: TestPool,
                verbose: false
              }} == EctoConnectionResetter.init(params)
    end

    test "fails to successfully init EctoConnectionResetter" do
      assert {:error, :missing_params} == EctoConnectionResetter.init(%{})
    end
  end

  describe "start_link/1" do
    test "accepts params", %{params: params} do
      assert {:ok, _pid} = EctoConnectionResetter.start_link(params)
    end
  end

  describe "handle_info/2" do
    test "accepts params", %{params: params} do
      assert {:noreply,
              %{
                cycle_mins: 1,
                close_interval: 1,
                repo: TestRepo,
                pool: TestPool
              }} = EctoConnectionResetter.handle_info(:work, params)
    end

    test "resets all connections from a given pool", %{params: params} do
      with_mock DBConnection,
        disconnect_all: fn _pid, _close_interval, _opts -> :noop end do
        EctoConnectionResetter.handle_info(:work, params)
        assert_called(DBConnection.disconnect_all(:_, 1, pool: TestPool))
      end
    end

    test "reset callback function gets called", %{params: params} do
      reset_callback = &TestDatabaseObserver.db_connection_reset_callback/1
      params = Map.put(params, :reset_callback, reset_callback)

      with_mock TestDatabaseObserver,
        db_connection_reset_callback: fn _state -> :noop end do
        EctoConnectionResetter.handle_info(:work, params)
        assert_called(TestDatabaseObserver.db_connection_reset_callback(params))
      end
    end
  end
end
