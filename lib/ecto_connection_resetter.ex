defmodule EctoConnectionResetter do
  require Logger

  @moduledoc """
  Defines EctoConnectionResetter

  An OTP process that allows a user to add one line to create a cron job to call disconnect all every X minutes.

  In order to use it, update your `application.ex` with:

    def start(_type, _args) do
      children = [
        {EctoConnectionResetter, %{cycle_mins: 1, close_interval: 1, repo: YourRepo}}
      ]
    end
  """

  use GenServer

  alias __MODULE__, as: ECR

  @typedoc "Number of minutes between each cycle"
  @type cycle_mins :: integer

  @typedoc "Seconds to close once a disconnect_all is called"
  @type close_interval :: integer

  @typedoc "Repo that will be cycled"
  @type repo :: Ecto.Repo.t()

  @enforce_keys [:cycle_mins, :close_interval, :repo, :pool]

  defstruct @enforce_keys

  # Client

  @spec start_link(map()) :: :ignore | {:error, term()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(ECR, args, name: ECR)
  end

  # Callbacks

  @impl true
  def init(%{cycle_mins: _cycle_mins, close_interval: _close_interval, repo: _repo} = args) do
    schedule_work(args.cycle_mins)

    {:ok, args}
  rescue
    e ->
      Logger.warn("EctoConnectionResetter failed >> ")
      Logger.warn(e)
      Logger.warn("EctoConnectionResetter failed << ")
      {:ok, args}
  end

  def init(_args) do
    throw("You need cycle_mins, repo and close_interval parameters")
  catch
    message ->
      Logger.warn("EctoConnectionResetter failed >> ")
      Logger.warn(message)
      Logger.warn("EctoConnectionResetter failed << ")
      {:error, :missing_params}
  end

  @impl true
  def handle_info(:work, state) do
    %{pid: pid} = Ecto.Adapter.lookup_meta(state.repo)

    DBConnection.disconnect_all(pid, state.close_interval,
      pool: state[:pool] || DBConnection.ConnectionPool
    )

    schedule_work(state.cycle_mins)

    {:noreply, state}
  rescue
    e ->
      Logger.warn("EctoConnectionResetter failed >> ")
      Logger.warn(e)
      Logger.warn("EctoConnectionResetter failed << ")
      {:noreply, state}
  end

  defp schedule_work(cycle_mins) do
    Process.send_after(self(), :work, cycle_mins * 60 * 1000)
  end
end
