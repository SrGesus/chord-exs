defmodule ChordNodeTest do
  use ExUnit.Case
  doctest Chord.Node

  test "dump state" do
    Chord.start(nil, nil)

    id = 0
    {:ok, node} = Chord.Node.start_link(id)

    {_, %Chord.FingerTable{predecessor: {^id, pred}}} = Chord.Node.dump(node)


    count = 10000
    tasks = 1..count
    |> Enum.map(fn _c ->
      Task.async(fn ->
        {^id, ^node} = Chord.Node.find_predecessor(node, 1)
      end)
    end)
    start = Time.utc_now()
    Task.await_many(tasks)
    {^id, ^node} = Chord.Node.closest_preceding_finger(node, 1)
    endt = Time.utc_now()

    assert Time.diff(endt, start, :microsecond) / count == 10

    assert node == pred
  end

  test "join nodes" do
    {:ok, node1} = Chord.Node.start_link(0)

    {:ok, node2} = Chord.Node.start_link(1)

    Chord.Node.join(node1, node2)

  end
end
