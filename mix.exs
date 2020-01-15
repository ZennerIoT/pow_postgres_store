defmodule PowPostgresStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :pow_postgres_store,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps(),
      aliases: [
        test: [
          # generate the schema to test if schema generation works
          "pow.postgres.gen.schema test/support/schema.ex",
          "ecto.create",
          # rollback all migrations to test if migrations work every time
          "ecto.rollback -n 1000",
          "ecto.migrate",
          # finally, call the tests
          "test"
        ]
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
      {:pow, "~> 1.0", only: :test},
      {:ecto_sql, "~> 3.2", only: :test},
      {:postgrex, "~> 0.15.3", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib","test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
