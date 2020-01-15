defmodule PowPostgresStoreTest do
  use ExUnit.Case
  doctest PowPostgresStore

  test "greets the world" do
    assert PowPostgresStore.hello() == :world
  end
end
