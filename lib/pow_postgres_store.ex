defmodule Pow.Postgres.Store do
  @behaviour Pow.Store.Backend.Base

  alias Pow.Config

  @type key() :: [binary() | atom()] | binary()
  @type record() :: {key(), any()}
  @type key_match() :: [atom() | binary()]

  @spec put(Config.t(), record() | [record()]) :: :ok
  def put(config, record) do

  end

  @spec delete(Config.t(), key()) :: :ok
  def delete(config, key) do

  end

  @spec get(Config.t(), key()) :: any() | :not_found
  def get(config, key) do

  end

  @spec all(Config.t(), key_match()) :: [record()]
  def all(config, key_match) do

  end
end
