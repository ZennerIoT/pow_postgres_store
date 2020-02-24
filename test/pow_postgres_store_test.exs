defmodule Pow.Postgres.StoreTest do
  use ExUnit.Case
  alias Pow.Postgres.Store

  test "inserts records" do
    config = []
    assert :ok = Store.put(config, {"abc", 13})
    assert :ok = Store.put(config, [
      {[:numbers, 1], 1},
      {[:numbers, 2], 2},
      {[:numbers, 3], 3},
    ])

    assert 13 = Store.get(config, "abc")
    records = Store.all(config, [:numbers, :_])
    assert 3 = length(records)
    assert 2 = Store.get(config, [:numbers, 2])
  end

  test "deletes records" do
    config = []
    assert :ok = Store.put(config, {"def", 20})
    assert :ok = Store.delete(config, "def")
    assert :not_found = Store.get(config, "def")
  end

  test "overwrites existing records" do
    config = []
    assert :ok = Store.put(config, {"overwrite", 20})
    assert 20 = Store.get(config, "overwrite")
    assert :ok = Store.put(config, {"overwrite", :abc})
    assert :abc = Store.get(config, "overwrite")
  end

  test "records expire if ttl option is set" do
    config = [ttl: -5000] # negative ttl will immediately expire
    assert :ok = Store.put(config, {"key", 10})
    assert :not_found = Store.get(config, "key")
    config = [ttl: 50_000]
    assert :ok = Store.put(config, {"key", 20})
    assert 20 = Store.get(config, "key")
  end

  test "integer keys" do
    config = []
    assert :ok = Store.put(config, {["users", 20, "struct"], %{name: "boo"}})
    assert %{name: "boo"} = Store.get(config, ["users", 20, "struct"])

    result = Store.all(config, ["users", 20, :_])
    assert [{_, %{name: "boo"}}] = result

  end

  test "deletes only expired records" do
    assert :ok = Store.put([ttl: -5000], {:expired, 1})
    assert :ok = Store.put([ttl: 5000], {:existing, 1})
    assert :ok = Store.delete_expired()
    assert 1 = Store.get([], :existing)
  end
end
