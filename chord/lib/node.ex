defmodule Chord.Node do
  use GenServer

  # Client
  def start_link(state) do
    {:ok, pid} = GenServer.start_link(__MODULE__, state)
    pid
  end

  def set_state(pid, key, value) do
    GenServer.cast(pid, {:set_state, key, value})
  end

  def get_table(pid) do
    GenServer.call(pid, :get_table)
  end

  def get_parent(pid) do
    GenServer.call(pid, :get_parent)
  end

  def find_successor(pid, key, hops\\0) do
    GenServer.cast(pid, {:find_successor, key, hops})
  end

  # Server
  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_table, _from, state) do
    {:reply, state[:table], state}
  end

  def handle_call(:get_parent, _from, state) do
    {:reply, state[:parent], state}
  end

  def handle_cast({:set_state, key, value}, state) do
    state = Map.put(state, key, value)
    {:noreply, state}
  end

  def handle_cast({:find_successor, key, hops}, state) do
    {sid, _spid} = Enum.at(state[:table], 0)
    id = state[:id]
    table = state[:table]
    parent = state[:parent]
    cond do
      id < key && key <= sid ->
        send(parent, {:DONE, key, hops})
      id > sid ->
        cond do
          0 <= key && key <= sid -> send(parent, {:DONE, key, hops})
          key > id && key < :math.pow(2, length(table)) -> send(parent, {:DONE, key, hops})
          true -> {nid, npid} = closest_preceding_node(table, length(table)-1, key, id)
                  find_successor(npid, key, hops+1)
        end
      true ->
        {nid, npid} = closest_preceding_node(table, length(table)-1, key, id)
        find_successor(npid, key, hops+1)
    end
    {:noreply, state}
  end

  defp closest_preceding_node(table, i, key, curr_id) do
    {eid, epid} = Enum.at(table, i)
    cond do
      # normal case
      curr_id < key ->
        cond do
          curr_id < eid && eid < key -> {eid, epid}
          true -> closest_preceding_node(table, i-1, key, curr_id)
        end
      # special case: key in node behind the current node
      curr_id >= key ->
        cond do
          0 <= eid && eid < key -> {eid, epid}
          curr_id < eid && eid < :math.pow(2, length(table)) ->
            {eid, epid}
          true -> closest_preceding_node(table, i-1, key, curr_id)
        end
      # default case
      true -> closest_preceding_node(table, i-1, key, curr_id)
    end
  end
end