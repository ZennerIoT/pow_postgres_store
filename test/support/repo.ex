defmodule Pow.Postgres.Repo do
  use Ecto.Repo, otp_app: :pow_postgres_store, adapter: Ecto.Adapters.Postgres
end
