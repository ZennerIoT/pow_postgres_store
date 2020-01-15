use Mix.Config

config :pow_postgres_store,
  ecto_repos: [Pow.Postgres.Repo]

config :pow_postgres_store, Pow.Postgres.Repo,
  username: "postgres",
  password: "postgres",
  database: "pow_postgres_store_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
