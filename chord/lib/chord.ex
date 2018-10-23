defmodule Chord do
  def main(args) do
    [numNodes, numRequests] = Enum.map(args, fn arg -> String.to_integer(arg) end)
    Chord.init(numNodes, numRequests)
  end

  def init(numNodes, numRequests) do
    # spawn nodes
    nodes = Enum.map(1..numNodes, fn node -> Chord.Node.start_link(%{}) end)

    # choose m for chord ring
    m = Util.choose_m(8, numNodes)

    # hash pids
    pid_list = Util.hash(nodes, m) |> Enum.sort

    # assign ids to the nodes
    Enum.each(pid_list, fn {id, pid} -> Chord.Node.set_state(pid, :id, id) end)

    # create and set fingertables
    finger_tables = Util.create_fingertables(pid_list, m)
    Enum.each(finger_tables, fn {pid, table} -> Chord.Node.set_state(pid, :table, table) end)

    # assign parent's pid to each node
    Enum.each(pid_list, fn {_id, pid} -> Chord.Node.set_state(pid, :parent, self()) end)

    # start making requests
    Enum.each(nodes, fn pid -> Util.loop_request(pid, numRequests, m) end)

    # listen for total number of hops
    total_requests = numNodes * numRequests |> trunc
    total_hops     = Util.listen(total_requests, 0, 0)
    average_hops   = total_hops/total_requests
    IO.puts "Average hops #{average_hops}"
  end
end
