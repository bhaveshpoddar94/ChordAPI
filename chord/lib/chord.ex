defmodule Chord do
  def init(numNodes, numRequests) do
    # spawn nodes
    nodes = Enum.map(1..numNodes, fn node -> Node.start_link(%{}) end)

    # choose m for chord ring
    m = choose_m(8, numNodes)

    # hash pids
    pid_list = hash(nodes, m) |> Enum.sort

    # create fingertables
    finger_tables = create_fingertables(pid_list, m)
    Enum.each(finger_tables, fn {pid, table} -> Node.set_state(pid, :table, table) end)

    # assign parent's pid to each node
    Enum.each(pid_list, fn {_id, pid} -> Node.set_state(pid, :parent, self()) end)

  end

  # loop for choosing m
  defp choose_m(m, numNodes, step \\ 8) do
    cond do
      numNodes < :math.pow(2, m) -> m
      true -> choose_m(m+step, numNodes)
    end
  end

  defp generate_keys(length) do
    Enum.map(1..length, fn _x -> gen_util(8) end)
  end

  defp hash(data, m) do
    Enum.map(data, fn datum -> {inspect(datum), datum} end)
    |> Enum.map(fn {value, datum} -> {:crypto.hash(:sha, value), datum} end)
    |> Enum.map(fn {hash,  datum} -> {binary_part(hash, 0, trunc(m/8)), datum} end)
    |> Enum.map(fn {sliced_hash, datum} -> {:binary.decode_unsigned(sliced_hash), datum} end)
  end

  defp create_fingertables(nodes, m) do
    ring_size = :math.pow(2, m) |> trunc
    Enum.map(nodes, fn {id, pid} -> {pid, loop_m(id, nodes, m, ring_size)} end)
  end

  defp loop_m(curr_id, nodes, m, ring_size) do
    Enum.map(1..m, fn k ->
      (curr_id + :math.pow(2, k-1)) |> trunc |> Integer.mod(ring_size)
      |> loop_nodes(nodes, 0) end)
  end

  defp loop_nodes(lim, nodes, index) when index >= length(nodes) do
    Enum.at(nodes, 0)
  end
  defp loop_nodes(lim, nodes, index) do
    {id, pid} = Enum.at(nodes, index)
    cond do
      id >= lim -> {id, pid}
      true -> loop_nodes(lim, nodes, index+1)
    end
  end
end

defmodule Node do
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
    GenServer.cast(pid, {:find_successor, key})
  end

  # Server
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:set_state, key, value}, state) do
    state = Map.put(state, key, value)
    {:noreply, state}
  end

  def handle_call(:get_table, _from, state) do
    {:reply, state[:table], state}
  end

  def handle_call(:get_parent, _from, state) do
    {:reply, state[:parent], state}
  end

  def handle_cast({:find_successor, key, acc}, state) do
    {sid, spid} = Enum.at(state[:table], 0)
    if sid > key do
     send(state[:parent], {:DONE, acc})
    else
      npid = closest_preceding_node(state[:table], length(state[:table])-1, key)
      find_successor(npid, )
    end
    {:noreply, state}
  end

  defp closest_preceding_node(table, -1, _key), do: Enum.max(table)
  defp closest_preceding_node(table, i, key) do
    {eid, epid} = Enum.at(table, i)
    cond do
      eid < key -> {eid, epid}
      true -> closest_preceding_node(table, i-1, key)
    end
  end
end

[numNodes, numRequests] = System.argv() |> Enum.map(fn arg -> String.to_integer(arg) end)
Chord.init(numNodes, numRequests)
