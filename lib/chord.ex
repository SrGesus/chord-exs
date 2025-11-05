defmodule Chord do
  use Application

  @doc """
  Number of bits in the identifier of a node
  """
  def n_bit_id do
    32
  end

  #   @moduledoc """
  #   Documentation for `Chord`.
  #   """

  #   @doc """
  #   Hello world.

  #   ## Examples

  #       #iex> Chord.hello()
  #       #:world

  #   """
  #   def start(_type, _args) do
  #     children = [
  #       # Registry for virtual nodes
  #       {Registry, name: Chord, keys: :unique},
  #       {DynamicSupervisor, name: Chord.NodeSupervisor, strategy: :one_for_one}
  #     ]

  #     Supervisor.start_link(children, strategy: :one_for_one)
  #   end

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

  @spec closest_preciding_finger(Chord.FingerTable.t(), integer()) :: {integer(), pid()}
  def closest_preciding_finger(%Chord.FingerTable{finger: finger, this: {this_id, this_node}}, id) do
    # To avoid a lot of modulos, shift values
    id = rem(id - this_id, 2**Chord.n_bit_id())
    Enum.reverse(finger) |> Enum.find(this_node, fn {i, _} -> i in id..i end)
  end
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
  def handle_call({:join, node2}, _from, {map, finger}) do
  end

  def join(node1, node2) do
  end

  def dump(node) do
    GenServer.call(node, :dump, timeout())
  end
end
