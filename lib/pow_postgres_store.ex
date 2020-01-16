defmodule Pow.Postgres.Store do
  @behaviour Pow.Store.Backend.Base

  alias Pow.Config
  import Ecto.Query

  @type key() :: [binary() | atom()] | binary()
  @type record() :: {key(), any()}
  @type key_match() :: [atom() | binary()]

  @spec put(Config.t(), record() | [record()]) :: :ok
  def put(config, record) do
    schema = schema()
    namespace = namespace(config)
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expires_at = case Config.get(config, :ttl) do
      nil ->
        nil

      ttl when is_integer(ttl) ->
        now
        |> DateTime.add(ttl, :millisecond)
        |> DateTime.truncate(:second)
    end

    records =
      List.wrap(record)
      |> Enum.map(fn {original_key, value} ->
        key = List.wrap(original_key)
        [
          namespace: namespace,
          key: Enum.map(key, &:erlang.term_to_binary/1),
          original_key: :erlang.term_to_binary(original_key),
          value: :erlang.term_to_binary(value),
          expires_at: expires_at,
          inserted_at: now,
          updated_at: now,
        ]
      end)

    case repo().insert_all(
        schema,
        records,
        on_conflict: {:replace, [:value, :expires_at, :updated_at]},
        conflict_target: [:namespace, :original_key]
      ) do
      {_rows, _entries} -> :ok
    end
  end

  @spec delete(Config.t(), key()) :: :ok
  def delete(config, key) do
    query =
      schema()
      |> filter_key(key)
      |> filter_namespace(config)

    case repo().delete_all(query) do
      {_rows, _} ->
        :ok
    end
  end

  @spec delete_expired() :: :ok
  def delete_expired() do
    query =
      schema()
      |> filter_expired()

    case repo().delete_all(query) do
      {_rows, _} ->
        :ok
    end
  end

  @spec get(Config.t(), key()) :: any() | :not_found
  def get(config, key) do
    query =
      schema()
      |> filter_key(key)
      |> filter_namespace(config)
      |> reject_expired()
      |> select_value()

    case repo().one(query) do
      nil ->
        :not_found

      value ->
        decode_value(value)
    end
  end

  @spec all(Config.t(), key_match()) :: [record()]
  def all(config, key_match) do
    query =
      schema()
      |> filter_key_match(key_match)
      |> filter_namespace(config)
      |> reject_expired()
      |> select_record()

    repo().all(query)
    |> Enum.map(&decode_record/1)
  end

  defp namespace(config) do
    Config.get(config, :namespace, "cache")
  end

  defp config() do
    Application.get_env(:pow, __MODULE__, [])
  end

  defp repo() do
    Keyword.get(config(), :repo, Pow.Postgres.Repo)
  end

  defp schema() do
    Keyword.get(config(), :schema, Pow.Postgres.Schema)
  end

  def filter_namespace(query, config) do
    where(query, [s], s.namespace == ^namespace(config))
  end

  def select_record(query) do
    select(query, [s], {s.original_key, s.value})
  end

  def select_value(query) do
    select(query, [s], s.value)
  end

  def filter_key_match(query, key_match) do
    query = where(query, [s], fragment("array_length(?, 1) = ?", s.key, ^length(key_match)))

    key_match
    |> Enum.with_index(1) # postgres index begins at 1
    |> Enum.reduce(query, fn {match, index}, query ->
      case match do
        :_ ->
          query

        key when is_atom(key) or is_binary(key) ->
          from s in query, where: fragment("?[?] = ?", s.key, ^index, ^:erlang.term_to_binary(key))
      end
    end)
  end

  def filter_key(query, key) do
    where(query, [s], s.original_key == ^:erlang.term_to_binary(key))
  end

  def reject_expired(query) do
    where(query, [s], is_nil(s.expires_at) or s.expires_at > ^DateTime.utc_now())
  end

  def filter_expired(query) do
    where(query, [s], not is_nil(s.expires_at) and s.expires_at <= ^DateTime.utc_now())
  end

  def decode_record({key, value}) do
    {
      :erlang.binary_to_term(key),
      :erlang.binary_to_term(value)
    }
  end

  def decode_value(value) do
    :erlang.binary_to_term(value)
  end
end
