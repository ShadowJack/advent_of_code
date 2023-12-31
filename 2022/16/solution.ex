defmodule AdventOfCode.Day16 do
  @moduledoc """
  Solution for Day16
  """

  defmodule Valve do
    defstruct name: nil, rate: nil, tunnels: []
    @type t :: %__MODULE__{name: String.t(), rate: integer(), tunnels: [String.t()]}

    @spec parse(String.t()) :: __MODULE__.t()
    def parse(line) do
      [_, name, rate, tunnels] = Regex.run(~r/Valve ([A-Z][A-Z]) has flow rate=(\d+); tunnels? leads? to valves? (.+)/, line)
      %__MODULE__{name: name, rate: String.to_integer(rate), tunnels: String.split(tunnels, ", ")}
    end
  end

  defmodule SignificantValve do
    defstruct name: nil, rate: nil, tunnels: []
    @type t :: %__MODULE__{name: String.t(), rate: integer(), tunnels: [{String.t(), integer()}]}
  end

  defmodule RC do
    def comb(0, _), do: [[]]
    def comb(_, []), do: []
    def comb(m, [h|t]) do
      (for l <- comb(m-1, t), do: [h|l]) ++ comb(m, t)
    end
  end

  @doc """
  Solves task 1 of Day 16
  """
  @spec solve() :: number()
  def solve() do
    data = read_input()
    nodes = [get_valve(data, "AA") | Enum.filter(data, fn v -> v.rate > 0 end)]
    significant_graph = nodes
    |> Enum.map(&build_significant_valve(data, nodes, &1))
    |> Map.new(fn node -> {node.name, node} end)

    dfs(significant_graph)
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&Valve.parse/1)
  end

  defp bfs(graph, source, target) do
    do_bfs(graph, target, [{source, 0}], [])
  end

  defp do_bfs(_graph, %Valve{name: name}, [{%Valve{name: name}, length} | _rest], _visited), do: length
  defp do_bfs(graph, target, [{curr, length} | rest], visited) do
    upd_visited = [curr.name | visited]
    neighbours = get_neighbours(graph, curr, upd_visited, length)
    do_bfs(graph, target, rest ++ neighbours, upd_visited)
  end

  defp get_neighbours(graph, node, visited, length) do
    node.tunnels
    |> Enum.reject(fn neib_name -> Enum.any?(visited, fn v -> v == neib_name end) end)
    |> Enum.map(fn neib_name -> {get_valve(graph, neib_name), length + 1} end)
  end

  defp get_valve(graph, valve_name) do
    Enum.find(graph, fn %Valve{name: name} -> name == valve_name end)
  end

  defp build_significant_valve(initial_graph, significant_nodes, valve) do
    %SignificantValve{
      name: valve.name,
      rate: valve.rate,
      tunnels: significant_nodes
      |> Enum.reject(fn snode -> snode.name == valve.name end)
      |> Enum.map(fn snode ->
        {snode.name, bfs(initial_graph, valve, snode)}
      end)
    }
  end

  defp dfs(graph) do
    root = graph["AA"]
    do_dfs(graph, root, MapSet.new(), 30, 0, 0)
  end

  defp do_dfs(_graph, _node, _visited, minutes_left, _curr_profit, max_profit) when minutes_left <= 0, do: max_profit
  defp do_dfs(graph, node, visited, minutes_left, curr_profit, max_profit) do
    # if curr node is not visited - open the valve and increase the curr sum + update global max sum if necessary
    is_visited = MapSet.member?(visited, node.name)
    upd_visited = MapSet.put(visited, node.name)
    upd_minutes = !is_visited && node.rate > 0 && minutes_left - 1 || minutes_left
    additional_profit = is_visited && 0 || (minutes_left - 1) * node.rate
    upd_curr_profit = curr_profit + additional_profit
    upd_max_profit = max(max_profit, upd_curr_profit)

    cond do
      MapSet.size(visited) == map_size(graph) ->
        max_profit
      Enum.all?(node.tunnels, fn {t, _} -> MapSet.member?(visited, t) end) ->
        upd_max_profit
      :otherwise ->
        node.tunnels
        |> Enum.reject(fn {name, _} -> MapSet.member?(visited, name) end)
        |> Enum.map(fn {neib_name, path_len} ->
          do_dfs(graph, graph[neib_name], upd_visited, upd_minutes - path_len, upd_curr_profit, upd_max_profit)
        end)
        |> Enum.max()

    end
  end

  @doc """
  Solves task 2 of Day 16
  """
  @spec solve2() :: number()
  def solve2() do
    data = read_input()
    nodes = [get_valve(data, "AA") | Enum.filter(data, fn v -> v.rate > 0 end)]
    significant_graph = nodes
    |> Enum.map(&build_significant_valve(data, nodes, &1))
    |> Map.new(fn node -> {node.name, node} end)

    :timer.tc(fn -> dfs3(significant_graph) end)
    # dfs3(significant_graph)
  end

  defp dfs2(graph) do
    root = graph["AA"]
    {first_half, second_half} = root.tunnels |> Enum.split(div(Enum.count(root.tunnels), 2))
    (for node1 <- first_half, node2 <- second_half, do: {node1, node2})
    |> Task.async_stream(fn {node1, node2} ->
      do_dfs2(graph, node1, node2, MapSet.new(), 26, 0, 0)
    end, timeout: :infinity)
    |> Enum.reduce(0, fn {:ok, result}, acc -> max(result, acc) end)
  end

  defp do_dfs2(_graph, _node1, _node2, _visited, minutes_left, _curr_profit, max_profit) when minutes_left <= 0, do: max_profit
  defp do_dfs2(graph, {node1_name, to_go1}, {node2_name, to_go2}, visited, minutes_left, curr_profit, max_profit) do
    cond do
      # everything is opened
      MapSet.size(visited) == map_size(graph) ->
        max_profit

      # both are moving
      to_go1 > 0 && to_go2 > 0 ->
        do_dfs2(
          graph,
          {node1_name, to_go1 - 1},
          {node2_name, to_go2 - 1},
          visited,
          minutes_left - 1,
          curr_profit,
          max_profit)

      # first moving - second arrived
      to_go1 > 0 && to_go2 == 0 ->
        if MapSet.member?(visited, node2_name) do
          # go to the neighbours
          graph[node2_name].tunnels
          |> Enum.reject(fn {neib_name, _} -> MapSet.member?(visited, neib_name) || neib_name == node1_name end)
          |> Enum.map(fn {neib_name, neib_len} ->
            do_dfs2(
              graph,
              {node1_name, to_go1 - 1},
              {neib_name, neib_len - 1},
              visited,
              minutes_left - 1,
              curr_profit,
              max_profit)
          end)
          |> Enum.max()
        else
          # open the valve:
          # spend one minute in this node while adding the profit
          upd_curr_profit = curr_profit + (minutes_left - 1) * graph[node2_name].rate
          do_dfs2(
            graph,
            {node1_name, to_go1 - 1},
            {node2_name, 0},
            MapSet.put(visited, node2_name),
            minutes_left - 1,
            upd_curr_profit,
            max(max_profit, upd_curr_profit))
        end

      # first arrived - second moving
      to_go1 == 0 && to_go2 > 0 ->
        if MapSet.member?(visited, node1_name) do
          # go to the neighbours
          graph[node1_name].tunnels
          |> Enum.reject(fn {neib_name, _} -> MapSet.member?(visited, neib_name) || neib_name == node2_name end)
          |> Enum.map(fn {neib_name, neib_len} ->
            do_dfs2(
              graph,
              {neib_name, neib_len - 1},
              {node2_name, to_go2 - 1},
              visited,
              minutes_left - 1,
              curr_profit,
              max_profit)
          end)
          |> Enum.max()
        else
          # open the valve:
          # spend one minute in this node while adding the profit
          upd_curr_profit = curr_profit + (minutes_left - 1) * graph[node1_name].rate
          do_dfs2(
            graph,
            {node1_name, 0},
            {node2_name, to_go2 - 1},
            MapSet.put(visited, node1_name),
            minutes_left - 1,
            upd_curr_profit,
            max(max_profit, upd_curr_profit))
        end

      # both arrived
      to_go1 == 0 && to_go2 == 0 ->
        cond do
          # both nodes are already visited - move both agents
          MapSet.member?(visited, node1_name) && MapSet.member?(visited, node2_name) ->
            n1_tunnels = graph[node1_name].tunnels
            |> Enum.reject(fn {neib_name, _} -> MapSet.member?(visited, neib_name) end)
            n2_tunnels = graph[node2_name].tunnels
            |> Enum.reject(fn {neib_name, _} -> MapSet.member?(visited, neib_name) end)
            (for n1 <- n1_tunnels, n2 <- n2_tunnels, do: {n1, n2})
            |> Enum.map(fn {{neib1_name, neib1_len}, {neib2_name, neib2_len}} ->
              do_dfs2(
                graph,
                {neib1_name, neib1_len - 1},
                {neib2_name, neib2_len - 1},
                visited,
                minutes_left - 1,
                curr_profit,
                max_profit)
            end)
            |> Enum.max()

          # first is visited - first goes, second opens the valve
          MapSet.member?(visited, node1_name) ->
            upd_curr_profit = curr_profit + (minutes_left - 1) * graph[node2_name].rate
            graph[node1_name].tunnels
            |> Enum.reject(fn {neib_name, _} -> MapSet.member?(visited, neib_name) || neib_name == node2_name end)
            |> Enum.map(fn {neib_name, neib_len} ->
              do_dfs2(
                graph,
                {neib_name, neib_len - 1},
                {node2_name, 0},
                MapSet.put(visited, node2_name),
                minutes_left - 1,
                upd_curr_profit,
                max(max_profit, upd_curr_profit))
            end)
            |> Enum.max()

          # second is visited - second goes, first opens the valve
          MapSet.member?(visited, node2_name) ->
            upd_curr_profit = curr_profit + (minutes_left - 1) * graph[node1_name].rate
            graph[node2_name].tunnels
            |> Enum.reject(fn {neib_name, _} -> MapSet.member?(visited, neib_name) || neib_name == node1_name end)
            |> Enum.map(fn {neib_name, neib_len} ->
              do_dfs2(
                graph,
                {node1_name, 0},
                {neib_name, neib_len - 1},
                MapSet.put(visited, node1_name),
                minutes_left - 1,
                upd_curr_profit,
                max(max_profit, upd_curr_profit))
            end)
            |> Enum.max()

          # none is visited - both agents should open valves
          :otherwise ->
            upd_curr_profit = curr_profit + (minutes_left - 1) * (graph[node1_name].rate + graph[node2_name].rate)
            do_dfs2(
              graph,
              {node1_name, 0},
              {node2_name, 0},
              MapSet.put(visited, node1_name) |> MapSet.put(node2_name),
              minutes_left - 1,
              upd_curr_profit,
              max(max_profit, upd_curr_profit))
        end
    end
  end

  defp dfs3(graph) do
    # human visits 1 node, elephant all the others
    # human 2 - elephant all others,
    # etc.
    #
    # take max from results
    root = graph["AA"]
    upd_graph = Map.delete(graph, "AA")
    max_count = div(map_size(upd_graph), 2)
    1..max_count
      |> Enum.flat_map(fn count -> split_graph(upd_graph, count) end)
      |> Enum.map(fn {graph1, graph2} ->
        graph1_result = root.tunnels
        |> Enum.filter(fn {name, _len} -> Map.has_key?(graph1, name) end)
        |> Task.async_stream(fn {neib_name, path_len} ->
          do_dfs(graph1, graph1[neib_name], MapSet.new(), 26 - path_len, 0, 0)
        end, timeout: :infinity)
        |> Enum.reduce(0, fn {:ok, result}, acc -> max(result, acc) end)

        graph2_result = root.tunnels
        |> Enum.filter(fn {name, _len} -> Map.has_key?(graph2, name) end)
        |> Task.async_stream(fn {neib_name, path_len} ->
          do_dfs(graph2, graph2[neib_name], MapSet.new(), 26 - path_len, 0, 0)
        end, timeout: :infinity)
        |> Enum.reduce(0, fn {:ok, result}, acc -> max(result, acc) end)

        graph1_result + graph2_result
      end)
    |> Enum.max()
  end

  defp split_graph(graph, count) do
    graph
    |> Enum.map(fn {k, _v} -> k end)
    |> split_names(count)
    |> Enum.map(fn {names1, names2} ->
      {subgraph(graph, names1), subgraph(graph, names2)}
    end)
  end
  defp split_names(names, count) do
    RC.comb(count, names)
    |> Enum.map(fn names1 -> {names1, Enum.reject(names, fn n -> Enum.any?(names1, fn n1 -> n1 == n end) end)} end)
  end

  defp subgraph(graph, names) do
    graph
    |> Enum.map(fn {k, v} ->
      filtered_tunnels = v.tunnels
        |> Enum.filter(fn {tn, _} -> Enum.any?(names, fn n -> n == tn end) end)
      {k, %AdventOfCode.Day16.SignificantValve{v | tunnels: filtered_tunnels}}
    end)
    |> Enum.filter(fn {k, _} -> Enum.any?(names, fn n -> n == k end) end)
    |> Map.new()
  end

end
