defmodule Chord.FingerTable do
  @type t :: %__MODULE__{
          finger: [{integer, integer, pid()}],
          predecessor: {integer, pid()},
          this: {integer, pid()}
        }
  defstruct [:predecessor, :this, :finger]

  defp max_id(), do: 2 ** Chord.n_bit_id()

  @spec new(integer(), pid()) :: Chord.FingerTable.t()
  def new(id, node) do
    %__MODULE__{
      predecessor: {id, node},
      this: {id, node},
      finger: Enum.map(0..(Chord.n_bit_id() - 1), fn i -> {2 ** i, id, node} end)
    }
  end

  @spec successor(Chord.FingerTable.t()) :: {integer, pid()}
  def successor(%Chord.FingerTable{finger: [{_, node_id, node} | _]}),
    do: {node_id, node}

  @spec closest_preceding_finger(Chord.FingerTable.t(), integer()) :: {integer(), pid()}
  def closest_preceding_finger(%Chord.FingerTable{this: {this_id, this_node}} = table, id) do
    case Integer.mod(id - this_id, max_id()) do
      0 ->
        table.predecessor

      1 ->
        table.this

      id ->
        {_, node_id, node} =
          Enum.reverse(table.finger)
          |> Enum.find({0, this_id, this_node}, fn {_, i, _} ->
            Integer.mod(i - this_id, max_id()) in 1..(id - 1)
          end)

        {node_id, node}
    end
  end

  @spec find_predecessor_table(Chord.FingerTable.t(), integer()) :: Chord.FingerTable.t()
  def find_predecessor_table(%Chord.FingerTable{this: {this_id, _}} = table, id) do
    {next_id, next_node} = Chord.FingerTable.closest_preceding_finger(table, id)

    if next_id == this_id do
      table
    else
      Chord.Node.find_predecessor_table(next_node, id)
      # Chord.FingerTable.find_predecessor_table(Chord.Node.finger_table(next_node), id)
    end
  end

  @spec find_predecessor(Chord.FingerTable.t(), integer()) :: {integer(), pid()}
  def find_predecessor(%Chord.FingerTable{this: {this_id, _}} = table, id) do
    {next_id, next_node} = Chord.FingerTable.closest_preceding_finger(table, id)

    if next_id == this_id do
      {next_id, next_node}
    else
      Chord.Node.find_predecessor(next_node, id)
      # Chord.FingerTable.find_predecessor(Chord.Node.finger_table(next_node), id)
    end
  end

  @spec find_successor(Chord.FingerTable.t(), integer()) :: {integer(), pid()}
  def find_successor(%Chord.FingerTable{this: {this_id, _}} = table, id) do
    {next_id, next_node} = Chord.FingerTable.closest_preceding_finger(table, id)

    if next_id == this_id do
      Chord.FingerTable.successor(table)
    else
      Chord.Node.find_successor(next_node, id)
      # Chord.FingerTable.find_successor(Chord.Node.finger_table(next_node), id)
    end
  end

  @spec init_finger_table(Chord.FingerTable.t(), pid()) :: Chord.FingerTable.t()
  def init_finger_table(
        %Chord.FingerTable{this: {this_id, _}, finger: [_ | finger]} = table,
        node
      ) do
    pred_table =
      Chord.Node.find_predecessor_table(node, this_id)

    suc = hd(pred_table.finger)

    Chord.Node.set_predecessor(elem(suc, 2), table.this)

    %Chord.FingerTable{
      table
      | finger: [suc | init_finger_table_(suc, finger, pred_table, this_id)],
        predecessor: pred_table.this
    }
  end

  @spec init_finger_table_(
          {integer(), integer(), pid()},
          [{integer(), integer(), pid()}],
          Chord.FingerTable.t(),
          integer()
        ) :: [{integer(), integer(), pid()}]
  defp init_finger_table_(
         {_, prev_id, prev_node},
         [{head_start, _, _} | tail],
         pred_table,
         node_id
       ) do
    next =
      if head_start in 0..Integer.mod(prev_id - node_id, max_id()) do
        {head_start, prev_id, prev_node}
      else
        {next_id, next_node} =
          find_successor(pred_table, Integer.mod(node_id + head_start, max_id()))

        {head_start, next_id, next_node}
      end

    [next | init_finger_table_(next, tail, pred_table, node_id)]
  end

  @spec init_finger_table_({integer(), integer(), pid()}, [], Chord.FingerTable.t(), integer()) ::
          []
  defp init_finger_table_(_, [], _, _) do
    []
  end

  @spec update_finger_table(Chord.FingerTable.t(), {integer(), pid()}, integer()) ::
          Chord.FingerTable.t()
  def update_finger_table(
        %Chord.FingerTable{this: {this_id, _}} = table,
        {id, node},
        i
      ) do
    {finger_id, finger_node_id, _} = Enum.at(table.finger, i)

    IO.puts("Received in #{this_id}")

    if Integer.mod(id - this_id, max_id()) in 1..Integer.mod(
         finger_node_id - this_id - 1,
         max_id()
       ) do
      Task.Supervisor.start_child(Chord.TaskSupervisor, fn ->
        Chord.Node.update_finger_table(elem(table.predecessor, 1), {id, node}, i)
      end)

      %Chord.FingerTable{
        table
        | finger: List.replace_at(table.finger, i, {finger_id, id, node})
      }
    else
      table
    end
  end

  @spec update_others(Chord.FingerTable.t()) :: list()
  def update_others(%Chord.FingerTable{this: {this_id, _}} = table) do
    for i <- 0..(Chord.n_bit_id() - 1) do
      {_pred_id, pred} = find_predecessor(table, Integer.mod(this_id - 2 ** i, max_id()))
      # if pred_id != this_id do
      Chord.Node.update_finger_table(pred, table.this, i)
      # end
    end
  end

  @spec set_predecessor(Chord.FingerTable.t(), {integer(), pid()}) :: t()
  def set_predecessor(
        %Chord.FingerTable{predecessor: {old_id, _}, this: {this_id, _}} = table,
        {pred_id, _} = pred
      ) do
    if Integer.mod(old_id - this_id, max_id()) > Integer.mod(pred_id - this_id, max_id()) do
      table
    else
      %Chord.FingerTable{
        table
        | predecessor: pred
      }
    end
  end
end
