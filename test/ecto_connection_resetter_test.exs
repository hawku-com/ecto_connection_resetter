defmodule EctoConnectionResetterTest do
  use ExUnit.Case
  doctest EctoConnectionResetter

  alias Ecto.Integration.TestRepo

  describe "init/1" do
    test "inits EctoConnectionResetter" do
      assert {:ok,
              %{
                cycle_mins: 1,
                close_interval: 1,
                repo: TestRepo,
                pool: TestPool
              }} ==
               EctoConnectionResetter.init(%{
                 cycle_mins: 1,
                 close_interval: 1,
                 repo: TestRepo,
                 pool: TestPool
               })
    end
  end

  describe "start_link/1" do
    test "accepts params" do
      assert {:ok, _pid} =
               EctoConnectionResetter.start_link(%{
                 cycle_mins: 1,
                 close_interval: 1,
                 repo: TestRepo,
                 pool: TestPool
               })
    end
  end

  describe "handle_info/2" do
    test "accepts params" do
      assert {:noreply,
              %{
                cycle_mins: 1,
                close_interval: 1,
                repo: TestRepo,
                pool: TestPool
              }} =
               EctoConnectionResetter.handle_info(:work, %{
                 cycle_mins: 1,
                 close_interval: 1,
                 repo: TestRepo,
                 pool: TestPool
               })
    end
  end
end
