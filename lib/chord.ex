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
  def start(_type, _args) do
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

defmodule Chord.FingerTable do
  @type t :: %__MODULE__{
          finger: [{integer, integer, pid()}],
          predecessor: {integer, pid()},
          this: {integer, pid()}
        }
  defstruct [:predecessor, :this, finger: []]

  @spec new(integer(), pid()) :: Chord.FingerTable.t()
  def new(id, node) do
    %__MODULE__{
      predecessor: {id, node},
      this: {id, node},
      finger: Enum.map(0..(Chord.n_bit_id() - 1), fn i -> {i ** 2, id, node} end)
    }
  end

  @spec closest_preceding_finger(Chord.FingerTable.t(), integer()) :: {integer(), pid()}
  def closest_preceding_finger(%Chord.FingerTable{finger: finger, this: {this_id, this_node}}, id) do
    id = rem(id - this_id, 2 ** Chord.n_bit_id())

    {_, finger_id, finger_node} =
      Enum.reverse(finger) |> Enum.find({nil, this_id, this_node}, fn {_, i, _} -> i in id..i end)

    {finger_id, finger_node}
  end

  @spec successor(Chord.FingerTable.t()) :: {integer, pid()}
  def successor(%Chord.FingerTable{finger: [{_, finger_id, finger_node} | _]}), do: {finger_id, finger_node}
end

defmodule Chord.Node do
  use GenServer

  @spec timeout :: non_neg_integer
  defp timeout() do
    5000
  end

  def start_link(id, opts \\ []) do
    GenServer.start_link(__MODULE__, {id}, opts)
  end

  @impl true
  def init({id}) do
    {:ok, {%{}, Chord.FingerTable.new(id, self())}}
  end

  @impl true
  def handle_call(:dump, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:closest_preceding_finger, id}, _from, state) do
    {_, finger} = state
    reply = Chord.FingerTable.closest_preceding_finger(finger, id)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:find_predecessor, id}, from, state) do
    {_, finger} = state
    %Chord.FingerTable{this: {this_id, _}} = finger
    {next_id, node} = Chord.FingerTable.closest_preceding_finger(finger, id)
    if next_id == this_id do
      {:reply, {next_id, node}, state}
    else
      Task.Supervisor.start_child(Chord.TaskSupervisor, fn ->
        GenServer.reply(from, Chord.Node.closest_preceding_finger(node, id))
      end)
      {:noreply, state}
    end
  end

  @impl true
  def handle_call({:find_successor, id}, from, state) do
    Task.Supervisor.start_child(Chord.TaskSupervisor, fn ->
      {_, finger} = state
      %Chord.FingerTable{this: {this_id, _}} = finger
      {next_id, node} = Chord.FingerTable.closest_preceding_finger(finger, id)
      {_, pred} = if next_id == this_id do
        {next_id, node}
      else
          Chord.Node.closest_preceding_finger(node, id)
      end

      GenServer.reply(from, successor(pred))
    end)
    {:noreply, state}
  end

  @impl true
  def handle_call(:successor, _from, state) do
    {_, finger} = state
    {:reply, Chord.FingerTable.successor(finger), state}
  end

  @impl true
  def handle_call({:join, node2}, _from, {map, finger}) do
  end

  def join(node1, node2) do
  end

  @spec closest_preceding_finger(pid(), integer()) :: {integer(), pid()}
  def closest_preceding_finger(node, id) do
    GenServer.call(node, {:closest_preceding_finger, id}, timeout())
  end

  @spec find_predecessor(pid(), integer()) :: {integer(), pid()}
  def find_predecessor(node, id) do
    GenServer.call(node, {:find_predecessor, id})
  end

  @spec find_successor(pid(), integer()) :: {integer(), pid()}
  def find_successor(node, id) do
    GenServer.call(node, {:find_successor, id})
  end

  @spec successor(pid()) :: {integer(), pid()}
  def successor(node) do
    GenServer.call(node, :successor)
  end

  def dump(node) do
    GenServer.call(node, :dump, timeout())
  end
end
