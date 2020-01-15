defmodule Pow.Postgres.Store do
  @behaviour Pow.Store.Backend.Base

  alias Pow.Config
  import Ecto.Query

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
    query = key_match_to_query(config, key_match)
      |> select([s], {s.key, s.value})

    repo(config).all(query)
    |> Enum.map(fn {key, value} ->
      {
        Enum.map(key, &:erlang.binary_to_term/1),
        :erlang.binary_to_term(value)
      }
    end)
  end

  defp schema(config) do
    Config.get(config, :schema)
  end

  defp repo(config) do
    Config.get(config, :repo)
  end

  defp namespace(config) do
    Config.get(config, :namespace, "cache")
  end

  def key_match_to_query(config, key_match) do
    query = from s in schema(config),
      where: s.namespace == ^namespace(config),
      where: fragment("array_length(?) = ?", s.key, ^length(key_match))

    key_match
    |> Enum.with_index()
    |> Enum.reduce(query, fn {match, index}, query ->
      case match do
        :_ ->
          query

        key when is_atom(key) or is_binary(key) ->
          from s in query, where: fragment("?[?] = ?", s.key, ^index, ^:erlang.term_to_binary(key))
      end
    end)
  end
end
