defmodule ChordTest do
  use ExUnit.Case
  doctest Chord

  test "greets the world" do
    assert Chord.hello() == :world
  end

  test "put key" do
    {:ok, node} = Chord.Node.start_link([])
    assert Chord.Node.get(node, "milk") == nil

    Chord.Node.put(node, "milk", 3)
    assert Chord.Node.get(node, "milk") == 3
  end
end
