defmodule AdventOfCode.Day2 do
  @moduledoc """
  Solution for Day1
  """

  @doc """
  Solves task 1 of Day 2
  """
  @spec solve() :: number()
  def solve() do
    read_input()
    |> Enum.map(&get_score/1)
    |> Enum.sum()
  end

  @doc """
  Solves task 2 of Day 2
  """
  @spec solve2() :: number()
  def solve2() do
    read_input()
    |> Enum.map(&get_score2/1)
    |> Enum.sum()
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.split("\n")
    |> Enum.map(fn line -> String.split(line, " ") end)
  end

  ### Part 1
  #
  defp get_score([""]), do: 0
  defp get_score([left, right]) do
    played_item_score(right) + outcome_score([left, right])
  end

  defp played_item_score(item) do
    case item do
      "X" -> 1
      "Y" -> 2
      "Z" -> 3
    end
  end

  defp outcome_score(pair) do
    case pair do
      ["A", "Z"] -> 0
      ["B", "X"] -> 0
      ["C", "Y"] -> 0
      ["A", "X"] -> 3
      ["B", "Y"] -> 3
      ["C", "Z"] -> 3
      ["A", "Y"] -> 6
      ["B", "Z"] -> 6
      ["C", "X"] -> 6
    end
  end

  ### Part 2
  #
  defp get_score2([""]), do: 0
  defp get_score2([left, right]) do
    played_item_score(get_played_item([left, right])) + outcome_score2(right)
  end

  defp get_played_item(pair) do
    case pair do
      ["A", "X"] -> "Z"
      ["A", "Y"] -> "X"
      ["A", "Z"] -> "Y"
      ["B", "X"] -> "X"
      ["B", "Y"] -> "Y"
      ["B", "Z"] -> "Z"
      ["C", "X"] -> "Y"
      ["C", "Y"] -> "Z"
      ["C", "Z"] -> "X"
    end
  end

  defp outcome_score2(result) do
    case result do
      "X" -> 0
      "Y" -> 3
      "Z" -> 6
    end
  end
end
