defmodule Chord do
  def init(numNodes, numRequests) do
    # spawn nodes
    nodes = Enum.map(1..numNodes, fn node -> Node.start_link(node) end)
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
