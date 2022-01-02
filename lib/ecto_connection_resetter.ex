defmodule EctoConnectionResetter do
  @moduledoc "Ecto Connection Resetter"

  use GenServer

  alias __MODULE__, as: ECR

  @typedoc "Number of minutes between each cycle"
  @type cycle_mins :: integer

  @typedoc "Seconds to close once a disconnect_all is called"
  @type close_interval :: integer

  @typedoc "Repo that will be cycled"
  @type repo :: atom

  @type state :: map

  # Client

  @spec start_link(map()) :: :ignore | {:error, term()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(ECR, args, name: ECR)
  end

  # Callbacks

  @impl true
  def init(args) do
    schedule_work(args[:cycle_mins])

    {:ok, args}
  end

  @impl true
  def handle_info(:work, state) do
    %{pid: pid} = Ecto.Adapter.lookup_meta(state[:repo])

    DBConnection.disconnect_all(pid, state[:close_interval],
      pool: state[:pool] || DBConnection.ConnectionPool
    )

    schedule_work(state[:cycle_mins])

    {:noreply, state}
  end

  defp schedule_work(cycle_mins) do
    Process.send_after(self(), :work, cycle_mins * 1000)
  end
end
