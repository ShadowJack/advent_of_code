defmodule AdventOfCode.Day8 do
  @moduledoc """
  Solution for Day8
  """

  @doc """
  Solves task 1 of Day 8
  """
  @spec solve() :: number()
  def solve() do
    grid = read_input()
    rows = Enum.count(grid)
    cols = grid |> List.first() |> Enum.count()
    for i <- 0..(rows - 1), j <- 0..(cols - 1) do
      if is_visible(grid, rows, cols, i, j), do: 1, else: 0
    end
    |> Enum.sum()
  end

  defp read_input() do
    File.read!("input.txt")
      |> String.split("\n")
      |> Enum.slice(0..-2)
      |> Enum.map(&String.graphemes/1)
  end

  defp is_visible(_grid, _rows, _cols, 0, _j), do: true
  defp is_visible(_grid, _rows, _cols, _i, 0), do: true
  defp is_visible(grid, rows, _cols, i, _j) when i == rows - 1, do: true
  defp is_visible(grid, _rows, cols, _i, j) when j == cols - 1, do: true
  defp is_visible(grid, _rows, _cols, i, j) do
    row = Enum.at(grid, i)
    col = get_col(grid, j)
    tree_hight = Enum.at(row, j)

    left = Enum.slice(row, 0..j-1)
    right = Enum.slice(row, j+1..-1)
    top = Enum.slice(col, 0..i-1)
    bottom = Enum.slice(col, i+1..-1)

    result = Enum.all?(left, fn t -> t < tree_hight end)
    || Enum.all?(right, fn t -> t < tree_hight end)
    || Enum.all?(top, fn t -> t < tree_hight end)
    || Enum.all?(bottom, fn t -> t < tree_hight end)

    # IO.puts("#{i}, #{j}: hight=#{tree_hight}, is visible=#{result}")
    result
  end

  defp get_col(grid, j) do
    Enum.map(grid, fn row -> Enum.at(row, j) end)
  end

  @doc """
  Solves task 2 of Day 8
  """
  @spec solve2() :: number()
  def solve2() do
    grid = read_input()
    rows = Enum.count(grid)
    cols = grid |> List.first() |> Enum.count()
    for i <- 0..(rows - 1), j <- 0..(cols - 1) do
      get_scenic_score(grid, rows, cols, i, j)
    end
    |> Enum.max()
  end

  defp get_scenic_score(grid, rows, cols, i, j) do
    row = Enum.at(grid, i)
    col = get_col(grid, j)
    tree_hight = Enum.at(row, j)

    left = j == 0 && [] || (Enum.slice(row, 0..j-1) |> Enum.reverse())
    right = j == cols - 1 && [] || Enum.slice(row, j+1..-1)
    top = i == 0 && [] || (Enum.slice(col, 0..i-1) |> Enum.reverse())
    bottom = i == rows - 1 && [] || Enum.slice(col, i+1..-1)

    count_visible_trees(left, tree_hight)
      * count_visible_trees(right, tree_hight)
      * count_visible_trees(top, tree_hight)
      * count_visible_trees(bottom, tree_hight)
  end

  defp count_visible_trees(trees, tree_hight) do
    case Enum.find_index(trees, fn t -> t >= tree_hight end) do
      nil -> Enum.count(trees)
      idx -> idx + 1
    end
  end
end
