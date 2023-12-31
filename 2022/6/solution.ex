defmodule AdventOfCode.Day6 do
  @moduledoc """
  Solution for Day6
  """

  @doc """
  Solves task 1 of Day 6
  """
  @spec solve() :: number()
  def solve() do
    read_input()
    |> find_code()
  end

  defp read_input() do
   File.read!("input.txt")
  end

  defp find_code(buffer) do
    do_find_code(buffer, 4, 0)
  end

  defp do_find_code(buffer, unique_chars, count) do
    first_chars = String.slice(buffer, 0, unique_chars) 
      |> String.graphemes()
    if first_chars |> Enum.uniq() |> Enum.count() == unique_chars do
      # code is found
      count + unique_chars
    else
      # look ahead
      updated_buffer = String.slice(buffer, 1..-1)
      do_find_code(updated_buffer, unique_chars, count + 1)
    end
  end

  @doc """
  Solves task 2 of Day 6
  """
  @spec solve2() :: number()
  def solve2() do
    read_input() |> find_code2()
  end
  defp find_code2(buffer) do
    do_find_code(buffer, 14, 0)
  end
end
