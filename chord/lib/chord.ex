defmodule Chord do
  def init(numNodes, numRequests) do
    # spawn nodes
    nodes = Enum.map(1..numNodes, fn node -> Node.start_link(node) end)

    # choose m for chord ring
    m = choose_m(8, numNodes)
  end

  # loop for choosing m
  defp choose_m(m, numNodes, step \\ 8) do
    cond do
      numNodes < :math.pow(2, m) -> m
      true -> choose_m(m+step, numNodes)
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

  # Server
  def init(state) do
    {:ok, state}
  end
end

[numNodes, numRequests] = System.argv() 
                          |> Enum.map(fn arg -> String.to_integer(arg) end)
Chord.init(numNodes, numRequests)
