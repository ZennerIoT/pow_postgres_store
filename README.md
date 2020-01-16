# PowPostgresStore

Implements Pow's `Pow.Backend.Store.Base` behaviour using a Postgres table.

## Installation

First, add the dependency:

```elixir
def deps do
  [
    {:pow_postgres_store, "~> 1.0"}
    # or 
    {:pow_postgres_store, github: "ZennerIoT/pow_postgres_store}
  ]
end
```

Run:

```sh
$ mix pow.postgres.gen.schema lib/my_app/util/pow_store.ex
``` 

to generate the ecto schema as well as the necessary migrations.

Tell `pow_postgres_store` where to find the ecto repository:

```elixir
config :pow, Pow.Postgres.Store,
  repo: MyApp.Repo
  # schema: Pow.Postgres.Schema
  # you can use a different name for the schema if you've modified the generated file
```

and tell `pow` to use this library as the store:

```elixir
config :my_app, Pow,  
  cache_store_backend: Pow.Postgres.Store
```

To automatically delete expired records from the database table, add this somewhere in your supervision tree:

```elixir
children = [
  #...
  worker(Pow.Postgres.Store.AutoDeleteExpired, [[interval: :timer.hours(1)]]),
  #...
]
```