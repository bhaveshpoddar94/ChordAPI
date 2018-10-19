defmodule Chord do
  def init(numNodes, numRequests) do
    # spawn nodes
    nodes = Enum.map(1..numNodes, fn node -> Node.start_link(node) end)

    # choose m for chord ring
    m = choose_m(8, numNodes)

    # hash pids
    pid_list = hash(nodes, m)

    # hash keys
    keys  = generate_keys(numNodes * 5)
    IO.inspect keys
    key_list = hash(keys, m)
  end

  # loop for choosing m
  defp choose_m(m, numNodes, step \\ 8) do
    cond do
      numNodes < :math.pow(2, m) -> m
      true -> choose_m(m+step, numNodes)
    end
  end

  defp generate_keys(length) do
    Enum.map(1..length, fn _x -> gen_util(8))
  end

  @bytes "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  defp gen_util(n) do
    Enum.map(1..n, fn _x -> :binary.at(@bytes, :rand.uniform(byte_size(@bytes) - 1)) end) 
    |> List.to_string
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
