defmodule AdventOfCode.Day3 do
  @moduledoc """
  Solution for Day1
  """

  @doc """
  Solves task 1 of Day 3
  """
  @spec solve() :: number()
  def solve() do
    read_input()
    |> Enum.map(&find_error/1)
    |> Enum.sum()
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.split("\n")
    |> Enum.slice(0..-2)
    |> Enum.map(fn line ->
      compartment_size = div(String.length(line), 2)
      {left, right} = String.split_at(line, compartment_size)
      {convert_input(left), convert_input(right)}
    end)
  end

  defp convert_input(str) do
    str
    |> String.to_charlist()
    |> Enum.map(fn el ->
      el < ?a && el - 38 || el - 96
    end)
  end

  defp find_error({left, right}) do
    left_set = MapSet.new(left)
    Enum.find(right, fn el -> MapSet.member?(left_set, el) end)
  end

  ### Part 2
  #

  @doc """
  Solves task 2 of Day 3
  """
  @spec solve2() :: number()
  def solve2() do
    read_input2()
    |> Enum.chunk_every(3)
    |> Enum.map(&find_badge/1)
    |> Enum.sum()
  end

  defp read_input2() do
    File.read!("input.txt")
    |> String.split("\n")
    |> Enum.slice(0..-2)
    |> Enum.map(&convert_input/1)
  end

  defp find_badge([a, b, c]) do
    map_a = MapSet.new(a)
    map_b = MapSet.new(b)
    map_c = MapSet.new(c)

    map_a
    |> MapSet.intersection(map_b)
    |> MapSet.intersection(map_c)
    |> MapSet.to_list()
    |> List.first()
  end
end
