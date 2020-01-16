defmodule Pow.Postgres.Store.AutoDeleteExpired do
  use GenServer
  require Logger

  @moduledoc """
  When started, this server will regularly clean up the table from expired records.

  It is not necessary to do this very often, since expired records won't be returned
  by get/2 or all/2. But it will keep the table size smaller.
  """

  @doc """
  Starts the server.

  **Options**:

   * `interval` - interval in milliseconds how often expired records will be cleaned from the database. Defaults to 1 hour.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    interval = Keyword.get(opts, :interval, :timer.hours(1))
    :timer.send_interval(interval, :delete)
    {:ok, []}
  end

  def handle_info(:delete, state) do
    Logger.debug("deleting expired records from pow store")
    Pow.Postgres.Store.delete_expired()
    {:noreply, state}
  end
end
