defmodule Chord do
  def init(numNodes, numRequests) do
    # spawn nodes
    nodes = Enum.map(1..numNodes, fn node -> Node.start_link(node) end)

    # choose m for chord ring
    m = choose_m(8, numNodes)

    # hash pids
    pid_list = hash(nodes, m)
  end

  # loop for choosing m
  defp choose_m(m, numNodes, step \\ 8) do
    cond do
      numNodes < :math.pow(2, m) -> m
      true -> choose_m(m+step, numNodes)
    end
  end

  defp hash(data, m) do
    Enum.map(data, fn datum -> {inspect(datum), datum} end)
    |> Enum.map(fn {value, datum} -> {:crypto.hash(:sha, value), datum} end)
    |> Enum.map(fn {hash,  datum} -> {binary_part(hash, 0, trunc(m/8)), datum} end)
    |> Enum.map(fn {sliced_hash, datum} -> {:binary.decode_unsigned(sliced_hash), datum} end)
  end
end

defmodule Node do
  use GenServer

  # Client
  def start_link(state) do
    {:ok, pid} = GenServer.start_link(__MODULE__, state)
    pid
  end

  # Server
  def init(state) do
    {:ok, state}
  end
end

[numNodes, numRequests] = System.argv() 
                          |> Enum.map(fn arg -> String.to_integer(arg) end)
Chord.init(numNodes, numRequests)
