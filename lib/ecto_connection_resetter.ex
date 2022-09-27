defmodule EctoConnectionResetter do
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

  require Logger

  alias __MODULE__, as: ECR

  @typedoc "Number of minutes between each cycle"
  @type cycle_mins :: integer()

  @typedoc "Seconds to close once a disconnect_all is called"
  @type close_interval :: integer()

  @typedoc "Repo that will be cycled"
  @type repo :: Ecto.Repo.t()

  @typedoc "Should it log additional information?"
  @type verbose :: boolean()

  @typedoc "Function to be called after requesting the connection reset"
  @type reset_callback :: function()

  @typedoc "name to pass to `GenServer.start_link` when initializing the application"
  @type name :: atom()

  @enforce_keys [:cycle_mins, :close_interval, :repo, :pool]

  @default_process_name ECR

  defstruct @enforce_keys

  # Client

  @spec start_link(map()) :: :ignore | {:error, term()} | {:ok, pid()}
  def start_link(args) do
    maybe_log_info("EctoConnectionResetter: starting process...", args)

    GenServer.start_link(ECR, args, name: process_name(args))
  end

  # Callbacks

  @impl true
  def init(
        %{cycle_mins: _cycle_mins, close_interval: _close_interval, repo: _repo} =
          args
      ) do
    schedule_work(args)
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

    maybe_log_info(
      "EctoConnectionResetter: reseting connections in the pool...",
      state
    )

    DBConnection.disconnect_all(pid, state.close_interval,
      pool: state[:pool] || DBConnection.ConnectionPool
    )

    if Map.get(state, :reset_callback, nil),
      do: state.reset_callback.(state)

    schedule_work(state)
    {:noreply, state}
  rescue
    e ->
      Logger.warn("EctoConnectionResetter failed >> ")
      Logger.warn(e)
      Logger.warn("EctoConnectionResetter failed << ")
      {:noreply, state}
  end

  defp schedule_work(%{cycle_mins: cycle_mins} = state) do
    cycle = cycle_mins * 60 * 1000
    next_schedule = DateTime.utc_now() |> DateTime.add(cycle, :millisecond)

    maybe_log_info(
      "EctoConnectionResetter: next reset scheduled for #{next_schedule} (UTC)",
      state
    )

    Process.send_after(self(), :work, cycle)
  end

  defp maybe_log_info(message, %{verbose: true} = args) do
    Logger.info("#{process_name(args)} *** #{message}")
  end

  defp maybe_log_info(_message, _args),
    do: nil

  defp process_name(%{name: process_name}), do: process_name

  defp process_name(_args), do: @default_process_name
end
