defmodule ChordNodeTest do
  use ExUnit.Case
  doctest Chord.Node

  test "dump state" do
    id = 0
    {:ok, node} = Chord.Node.start_link(id)

    {_, %Chord.FingerTable{predecessor: {^id, pred}}} = Chord.Node.dump(node)

    assert node == pred
  end

  test "join nodes" do
    {:ok, node1} = Chord.Node.start_link(0)

    {:ok, node2} = Chord.Node.start_link(1)

    Chord.Node.join(node1, node2)

  end
end
