defmodule AdventOfCode.Day4 do
  @moduledoc """
  Solution for Day1
  """

  @doc """
  Solves task 1 of Day 4
  """
  @spec solve() :: number()
  def solve() do
    read_input()
    |> Enum.count(&fully_contains?/1)
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.split("\n")
    |> Enum.slice(0..-2)
    |> Enum.map(fn line ->
      [first, second] = String.split(line, ",")
      {convert_input(first), convert_input(second)}
    end)
  end

  defp convert_input(range_str) do
    [left, right] = range_str
    |> String.split("-")
    |> Enum.map(&String.to_integer/1)
    {left, right}
  end

  defp fully_contains?({{l1, r1}, {l2, r2}}) do
    cond do
      l1 <= l2 && r1 >= r2 -> true
      l2 <= l1 && r2 >= r1 -> true
      :otherwise -> false
    end
  end

  @doc """
  Solves task 2 of Day 4
  """
  @spec solve2() :: number()
  def solve2() do
    read_input()
    |> Enum.count(&overlaps?/1)
  end

  defp overlaps?({{l1, r1}, {l2, r2}}) do
    cond do
      l1 <= l2 && r1 >= r2 -> true
      l2 <= l1 && r2 >= r1 -> true
      l1 <= l2 && r1 >= l2 -> true # l1..l2..r1..r2
      l2 <= l1 && r2 >= l1 -> true # l2..l1..r2..r1
      :otherwise -> false
    end
  end
end
