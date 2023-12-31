defmodule AdventOfCode.Day18 do
  @moduledoc """
  Solution for Day18
  """

  require IEx

  @doc """
  Solves task 1 of Day 18
  """
  @spec solve() :: number()
  def solve() do
    nodes = read_input()
      |> Enum.sort()
    nodes
    |> Enum.reduce(0, fn node, acc -> count_free_sides(nodes, node) + acc end)
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
  end

  defp parse_line(line) do
    [x, y, z] = line
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
    {x, y, z}
  end

  defp count_free_sides(nodes, node) do
    6 - count_neighbors(nodes, node)
  end

  defp count_neighbors(nodes, {x, y, z}) do
    [
      {x - 1, y, z},
      {x + 1, y, z},
      {x, y - 1, z},
      {x, y + 1, z},
      {x, y, z - 1},
      {x, y, z + 1}]
      |> Enum.count(fn neighbor ->
        Enum.any?(nodes, fn node -> node == neighbor end)
      end)
  end

  @doc """
  Solves task 2 of Day 18
  """
  @spec solve2() :: number()
  def solve2() do
    nodes = read_input() |> Enum.sort()
    {xs, ys, zs} = Enum.reduce(nodes, {[], [], []}, fn {x, y, z}, {xs, ys, zs} -> {[x | xs], [y | ys], [z | zs]} end)
    {min_x, max_x} = Enum.min_max(xs) |> IO.inspect(label: "X")
    {min_y, max_y} = Enum.min_max(ys) |> IO.inspect(label: "Y")
    {min_z, max_z} = Enum.min_max(zs) |> IO.inspect(label: "Z")
    cube = {min_x - 1, min_y - 1, min_z - 1, max_x + 1, max_y + 1, max_z + 1}
    start = {min_x - 1, min_y - 1, min_z - 1}
    find_surface(nodes, cube)
  end

  defp find_surface(nodes, {x, y, z, _, _, _} = cube) do
    IO.inspect(cube, labe: "Cube")
    do_find_surface(nodes, cube, [{x, y, z}], [], 0)
  end

  defp do_find_surface(_nodes, _cube, [], _visited, result), do: result
  defp do_find_surface(nodes, cube, [curr | rest], visited, result) do
    upd_visited = [curr | visited]
    # IO.inspect(Enum.count(upd_visited), label: "Visited count")
    upd_result = result + count_neighbors(nodes, curr)
    neighbours = get_adjacent_air(nodes, cube, curr, upd_visited)
    # IO.inspect(Enum.count(neighbours), label: "Adjacent air")
    do_find_surface(nodes, cube, rest ++ neighbours, upd_visited ++ neighbours, upd_result)
  end

  defp get_adjacent_air(filled_nodes, {min_x, min_y, min_z, max_x, max_y, max_z}, {x, y, z}, visited) do
    # IO.inspect({x, y, z}, label: "Current node")
    # IO.inspect(visited, label: "Visited")
    [
      {x - 1, y, z},
      {x + 1, y, z},
      {x, y - 1, z},
      {x, y + 1, z},
      {x, y, z - 1},
      {x, y, z + 1}]
    |> Enum.reject(fn {cand_x, cand_y, cand_z} = cand ->
        cand_x < min_x ||
        cand_x > max_x ||
        cand_y < min_y ||
        cand_y > max_y ||
        cand_z < min_z ||
        cand_z > max_z ||
        Enum.any?(filled_nodes, fn filled_n -> filled_n == cand end) ||
        Enum.any?(visited, fn v -> v == cand end)
    end)
    # |> IO.inspect(label: "Adjacent free air")
  end
end
