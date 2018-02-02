defmodule DraconicTest do
  use ExUnit.Case
  doctest Draconic

  test "greets the world" do
    assert Draconic.hello() == :world
  end
end
