defmodule Chord do
  def init(numNodes, numRequests) do
    # spawn nodes
    nodes = Enum.map(1..numNodes, fn node -> Node.start_link(%{}) end)

    # choose m for chord ring
    m = choose_m(8, numNodes)

    # hash pids
    pid_list = hash(nodes, m) |> Enum.sort

    # hash keys
    keys  = generate_keys(numNodes * @multiplicity)
    key_list = hash(keys, m) |> Enum.sort

    # create fingertables
    finger_tables = create_fingertables(pid_list, m)
    Enum.map(finger_tables, fn {pid, table} -> Node.set_table(pid, table) end)

    def loop(0), do: :ok
    def loop(N) do
      receive do
        {:CHECK, pid, value} ->
          IO.inspect numNodes
          loop(numNodes-1)
      end
    end
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

end

[numNodes, numRequests] = System.argv() |> Enum.map(fn arg -> String.to_integer(arg) end)
Chord.init(numNodes, numRequests)
