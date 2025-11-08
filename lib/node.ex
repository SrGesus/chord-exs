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

  @spec finger_table(pid()) :: Chord.FingerTable.t()
  def finger_table(node), do: GenServer.call(node, :finger_table)

  def update_finger_table(node, s, i) do
    GenServer.call(node, {:update_finger_table, s, i})
  end

  @impl true
  def handle_call(:dump, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call(:finger_table, _from, {_, finger} = state), do: {:reply, finger, state}

  @impl true
  def handle_call({:closest_preceding_finger, id}, _from, state) do
    {_, finger} = state
    reply = Chord.FingerTable.closest_preceding_finger(finger, id)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:find_predecessor_table, id}, from, {_, finger} = state) do
    Task.Supervisor.start_child(Chord.TaskSupervisor, fn ->
      GenServer.reply(from, Chord.FingerTable.find_predecessor_table(finger, id))
    end)
    {:noreply, state}
  end

  @impl true
  def handle_call({:find_predecessor, id}, from, {_, finger} = state) do
    Task.Supervisor.start_child(Chord.TaskSupervisor, fn ->
      GenServer.reply(from, Chord.FingerTable.find_predecessor(finger, id))
    end)
    {:noreply, state}
  end

  @impl true
  def handle_call({:find_successor, id}, from, {_, finger} = state) do
    Task.Supervisor.start_child(Chord.TaskSupervisor, fn ->
      GenServer.reply(from, Chord.FingerTable.find_successor(finger, id))
    end)
    {:noreply, state}
  end

  @impl true
  def handle_call({:update_finger_table, s, i}, _from, {map, table}) do
    {:reply, :ok, {map, Chord.FingerTable.update_finger_table(table, s, i)}}
  end

  @impl true
  def handle_call({:join, node2}, _from, {map, finger}) do
    new_finger = Chord.FingerTable.init_finger_table(finger, node2)
    # Task.Supervisor.start_child(Chord.TaskSupervisor, fn ->
    Chord.FingerTable.update_others(new_finger)
    # end)
    {:reply, new_finger, {map, new_finger}}
  end

  @impl true
  def handle_call(:successor, _from, {_, finger} = state) do
    {:reply, Chord.FingerTable.successor(finger), state}
  end

  @impl true
  def handle_call({:set_predecessor, p}, _from, {map, finger}) do
    {:reply, :ok, {map, Chord.FingerTable.set_predecessor(finger, p)}}
  end

  def join(node1, node2) do
    GenServer.call(node1, {:join, node2}, timeout())
  end

  @spec closest_preceding_finger(pid(), integer()) :: {integer(), pid()}
  def closest_preceding_finger(node, id) do
    GenServer.call(node, {:closest_preceding_finger, id}, timeout())
  end

  @spec find_predecessor_table(pid(), integer()) :: Chord.FingerTable.t()
  def find_predecessor_table(node, id) do
    GenServer.call(node, {:find_predecessor_table, id})
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

  @spec set_predecessor(pid(), {integer(), pid()}) :: nil
  def set_predecessor(node, p) do
    GenServer.call(node, {:set_predecessor, p})
  end

  def dump(node) do
    GenServer.call(node, :dump, timeout())
  end
end
