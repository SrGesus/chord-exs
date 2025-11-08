defmodule ChordNodeTest do
  use ExUnit.Case
  doctest Chord.Node

  test "dump state" do
    Chord.start()

    id = 0
    {:ok, node} = Chord.Node.start_link(id)

    {_, %Chord.FingerTable{predecessor: {^id, pred}}} = Chord.Node.dump(node)

    count = 10000

    tasks =
      1..count
      |> Enum.map(fn i ->
        Task.async(fn ->
          {^id, ^node} = Chord.Node.closest_preceding_finger(node, i)
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
    Chord.start()

    {:ok, node0} = Chord.Node.start_link(0)
    {:ok, node1} = Chord.Node.start_link(div(2 ** 32, 4) * 1)
    {:ok, node2} = Chord.Node.start_link(div(2 ** 32, 4) * 2)
    {:ok, node3} = Chord.Node.start_link(div(2 ** 32, 4) * 3)

    Chord.Node.join(node2, node3)
    Chord.Node.join(node1, node3)
    Chord.Node.join(node0, node3)

    finger = Chord.Node.finger_table(node0)

    assert Enum.at(finger.finger, 0) |> elem(1) == 2 ** 30
    assert Enum.at(finger.finger, 31) |> elem(1) == 2 ** 31
  end
end
