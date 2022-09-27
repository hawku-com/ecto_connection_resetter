# EctoConnectionResetter

An OTP process that allows a user to add one line to create a cron job to call disconnect all every X minutes.

## Usage

In your `application.ex`, add:

```elixir
def start(_type, _args) do
  ...

  children = [
    ...
    {EctoConnectionResetter, %{cycle_mins: 1, close_interval: 1, repo: YourRepo}}
  ]

  ...
end
```

where:

- `cycle_mins`: number of minutes between each cycle;
- `close_interval`: seconds to close once a disconnect_all is called;
- `repo`: your Repo;
- `verbose`: (optional) log additional text when spawning the lib's OTP process and when scheduling the next resetting. Default is false;
- `reset_callback`: (optional) function to be called every time connections are reset in the pool (e.g. useful for APM metrics).
- `name`: (optional) name to pass to `GenServer.start_link` when initializing the application. Useful when you want to run multiple instances in parallel.

## Support for multiple Ecto Repo instances

In your `application.ex`, add instead:

```elixir
def start(_type, _args) do
  ...

  children = [
    ...
    Supervisor.child_spec(
      {EctoConnectionResetter, %{cycle_mins: 1, close_interval: 1, repo: RepoOne, name: RepoOneECR}},
      id: :repo_one_ecr
    ),
    Supervisor.child_spec(
      {EctoConnectionResetter, %{cycle_mins: 1, close_interval: 1, repo: RepoTwo, name: RepoTwoECR}},
      id: :repo_two_ecr
    )
  ]

  ...
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_connection_resetter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_connection_resetter, "~> 0.3"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ecto_connection_resetter>.
