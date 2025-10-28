defmodule Chord do
  use Application

  @moduledoc """
  Documentation for `Chord`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Chord.hello()
      :world

  """
  def start(_type, _args) do
    children = [
      # Registry for virtual nodes
      {Registry, name: Chord, keys: :unique},
      {DynamicSupervisor, name: Chord.NodeSupervisor, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def create_node(id) do
    DynamicSupervisor.start_child(Chord.NodeSupervisor, {Chord.Node, name: via(id)})
  end

  def lookup_node(id) do
    GenServer.whereis(via(id))
  end

  defp via(id) do
    {:via, Registry, {Chord, id}}
  end
end

defmodule Chord.FingerTable do
  use Agent
  @timeout 5000

  defp timeout() do
    @timeout
  end

  def start_link(opts) do
    Agent.start_link(fn -> [] end, opts)
  end

  def add(table, id, pid) do
  end
end

defmodule Chord.Node do
  use Agent
  @timeout 5000

  defp timeout() do
    @timeout
  end

  def start_link(opts) do
    Agent.start_link(fn -> %{} end, opts)
  end

  def get(node, key) do
    Agent.get(node, &Map.get(&1, key), timeout())
  end

  def put(node, key, value) do
    Agent.update(node, &Map.put(&1, key, value), timeout())
  end
end
