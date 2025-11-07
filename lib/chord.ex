defmodule Chord do
  #   @moduledoc """
  #   Documentation for `Chord`.
  #   """
  use Application

  @doc """
  Number of bits in the identifier of a node
  """
  def n_bit_id do
    32
  end

  #   @doc """
  #   Hello world.

  #   ## Examples

  #       #iex> Chord.hello()
  #       #:world

  #   """
  @impl true
  def start(_type \\ [], _args \\ []) do
    children = [
      #       # Registry for virtual nodes
      #       {Registry, name: Chord, keys: :unique},
      #       {DynamicSupervisor, name: Chord.NodeSupervisor, strategy: :one_for_one}
      {Task.Supervisor, name: Chord.TaskSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  #   def create_node(id) do
  #     DynamicSupervisor.start_child(Chord.NodeSupervisor, {Chord.Node, name: via(id)})
  #   end

  #   def lookup_node(id) do
  #     GenServer.whereis(via(id))
  #   end

  #   defp via(id) do
  #     {:via, Registry, {Chord, id}}
  #   end
end
