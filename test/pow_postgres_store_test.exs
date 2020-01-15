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
end
