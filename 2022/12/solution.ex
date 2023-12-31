defmodule AdventOfCode.Day12 do
  @moduledoc """
  Solution for Day12
  """
  require IEx

  @doc """
  Solves task 1 of Day 12
  """
  @spec solve() :: number()
  def solve() do
    {grid, start, finish} = read_input()
    find_shortest_path(grid, start, finish)
  end

  defp read_input() do
    grid = File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&String.to_charlist/1)

    # find start and finish
    start_i = Enum.find_index(grid, fn row -> Enum.any?(row, fn x -> x == ?S end) end)
    start_j = Enum.at(grid, start_i) |> Enum.find_index(fn x -> x == ?S end)
    finish_i = Enum.find_index(grid, fn row -> Enum.any?(row, fn x -> x == ?E end) end)
    finish_j = Enum.at(grid, start_i) |> Enum.find_index(fn x -> x == ?E end)

    # replace start and finish with 'a' and 'z'
    upd_grid = replace_at(grid, start_i, start_j, ?a) |> replace_at(finish_i, finish_j, ?z)

    {upd_grid, {start_i, start_j}, {finish_i, finish_j}}
  end

  defp replace_at(grid, i, j, new_val) do
    List.replace_at(grid, i, Enum.at(grid, i) |> List.replace_at(j, new_val))
  end

  defp find_shortest_path(grid, start, finish) do
    do_find_shortest_path(grid, finish, [{start, 0}], [start])
  end

  defp do_find_shortest_path(_grid, _finish, [], _visited) do
    nil
  end
  defp do_find_shortest_path(_grid, finish, [{finish, steps} | _rest], _visited) do
    steps
  end
  defp do_find_shortest_path(grid, finish, [{curr, steps} | rest], visited) do
    # get all possible neighbors that are not visited and add them to the queue
    # dbg({curr, rest, visited})
    neighbors = get_new_neighbors(grid, curr, visited)
    queue = rest ++ (neighbors |> Enum.map(fn neib -> {neib, steps + 1} end))
    do_find_shortest_path(grid, finish, queue, visited ++ neighbors)
  end

  defp get_new_neighbors(grid, {i, j}, visited) do
    curr_val = val_at(grid, i, j)
    candidates= [{i - 1, j}, {i, j + 1}, {i + 1, j}, {i, j - 1}]

    candidates
    |> Enum.reject(fn {ni, nj} ->
      ni < 0
        || nj < 0
        || ni == Enum.count(grid)
        || nj == (grid |> Enum.at(ni) |> Enum.count())
        || val_at(grid, ni, nj) - curr_val > 1
      end)
    |> Enum.reject(fn {ni, nj} ->
      Enum.any?(visited, fn {vi, vj} -> vi == ni && vj == nj end)
    end)
  end

  defp val_at(grid, i, j) do
    grid |> Enum.at(i) |> Enum.at(j)
  end

  @doc """
  Solves task 2 of Day 12
  """
  @spec solve2() :: number()
  def solve2() do
    # start from finish and find the closest ?a
    {grid, _start, finish} = read_input()
    find_shortest_path2(grid, finish)
  end

  defp find_shortest_path2(grid, finish) do
    do_find_shortest_path2(grid, [{finish, 0}], [finish])
  end

  defp do_find_shortest_path2(_grid, [], _visited) do
    raise "The path is not found"
  end
  defp do_find_shortest_path2(grid, [{{i, j}, steps} | rest], visited) do
    if val_at(grid, i, j) == ?a do
      steps
    else
      # get all possible neighbors that are not visited and add them to the queue
      neighbors = get_new_neighbors2(grid, {i, j}, visited)
      queue = rest ++ (neighbors |> Enum.map(fn neib -> {neib, steps + 1} end))
      do_find_shortest_path2(grid, queue, visited ++ neighbors)
    end
  end

  defp get_new_neighbors2(grid, {i, j}, visited) do
    curr_val = val_at(grid, i, j)
    candidates= [{i - 1, j}, {i, j + 1}, {i + 1, j}, {i, j - 1}]

    candidates
    |> Enum.reject(fn {ni, nj} ->
      ni < 0
        || nj < 0
        || ni == Enum.count(grid)
        || nj == (grid |> Enum.at(ni) |> Enum.count())
        || curr_val - val_at(grid, ni, nj)  > 1
      end)
    |> Enum.reject(fn neib ->
      Enum.any?(visited, fn v -> v == neib end)
    end)
  end
end
