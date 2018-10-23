defmodule Util do
  def choose_m(m, numNodes, step \\ 8) do
    cond do
      numNodes < :math.pow(2, m) -> m
      true -> choose_m(m+step, numNodes)
    end
  end

  def hash(data, m) do
    Enum.map(data, fn datum -> {inspect(datum), datum} end)
    |> Enum.map(fn {value, datum} -> {:crypto.hash(:sha, value), datum} end)
    |> Enum.map(fn {hash,  datum} -> {binary_part(hash, 0, trunc(m/8)), datum} end)
    |> Enum.map(fn {sliced_hash, datum} -> {:binary.decode_unsigned(sliced_hash), datum} end)
  end

  def create_fingertables(nodes, m) do
    ring_size = :math.pow(2, m) |> trunc
    tasks = Enum.map(nodes, fn {id, pid} -> loop_m(id, pid, nodes, m, ring_size) end)
  end

  def loop_m(id, pid, nodes, m, ring_size) do
    table = Enum.map(1..m, fn k ->
        key = (id + :math.pow(2, k-1)) |> trunc |> Integer.mod(ring_size)
        a = Enum.find(nodes, fn {id, pid} -> id >= key end)
        if a == nil do Enum.at(nodes, 0) else a end
      end)
    {pid, table}
  end

  def loop_request(_pid, 0, _m), do: :ok
  def loop_request(pid, numRequests, m) do
    key = (:math.pow(2, m) - 1) |> trunc |> :rand.uniform
    Chord.Node.find_successor(pid, key)
    loop_request(pid, numRequests-1, m)
  end

  def listen(0, count, acc), do: acc
  def listen(total_requests, count, acc) do
    receive do
      {:DONE, key, hops} ->
      listen(total_requests-1, count+1, acc+hops)
    end
  end
end