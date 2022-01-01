defmodule EctoConnectionResetter.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_connection_resetter,
      version: "0.1.0",
      elixir: "~> 1.13",
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
      ]
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
      {:credo, "~> 1.6.1", only: [:dev, :test], runtime: false},
      {:dialyzex, "~> 1.3.0", only: [:dev], runtime: false}
    ]
  end
end
