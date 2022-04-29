defmodule EctoConnectionResetter.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_connection_resetter,
      version: "0.2.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_deps: :apps_direct,
        plt_add_apps: [
          :ex_unit,
          :mix
        ]
      ],
      dialyzer_warnings: [
        :error_handling,
        :race_conditions,
        :unknown
      ],
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:db_connection, "~> 2.4.1"},
      {:ecto_sql, "~> 3.4"},
      {:credo, "~> 1.6.1", only: [:dev, :test], runtime: false},
      {:dialyzex, "~> 1.3.0", only: [:dev], runtime: false},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end

  defp package do
    [
      description:
        "An OTP process that allows a user to add one line to create a cron job to call disconnect all every X minutes.",
      maintainers: [
        "a |> louise"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/hawku-com/ecto_connection_resetter"
      }
    ]
  end
end
