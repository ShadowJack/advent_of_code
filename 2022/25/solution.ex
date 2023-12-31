defmodule AdventOfCode.Day25 do
  @moduledoc """
  Solution for Day25
  """

  @doc """
  Solves task 1 of Day 25
  """
  @spec solve() :: number()
  def solve() do
    read_input()
    |> Enum.map(&to_decimal/1)
    |> Enum.sum()
    |> to_quintimal()
  end

  @doc """
  Solves task 2 of Day 25
  """
  @spec solve2() :: number()
  def solve2() do
    read_input()
  end

  ## Common
  #
  defp read_input() do
    File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
  end

  def to_decimal(quintimal) do
    {result, _} = quintimal
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.reduce({0, 1}, fn digit, {result, radix} ->
      case digit do
        "2" -> {result + 2 * radix, radix * 5}
        "1" -> {result + radix, radix * 5}
        "0" -> {result, radix * 5}
        "-" -> {result - radix, radix * 5}
        "=" -> {result - 2 * radix, radix * 5}
      end
    end)
    result
  end

  def to_quintimal(decimal) do
    do_to_quintimal(decimal, [])
  end

  defp do_to_quintimal(0, results) do
    results |> Enum.join("")
  end
  defp do_to_quintimal(num, results) do
    cond do
      rem(num - 2, 5) == 0 -> do_to_quintimal(div(num - 2, 5), ["2" | results])
      rem(num - 1, 5) == 0 -> do_to_quintimal(div(num - 1, 5), ["1" | results])
      rem(num, 5) == 0 -> do_to_quintimal(div(num, 5), ["0" | results])
      rem(num + 1, 5) == 0 -> do_to_quintimal(div(num + 1, 5), ["-" | results])
      rem(num + 2, 5) == 0 -> do_to_quintimal(div(num + 2, 5), ["=" | results])
    end
  end
end
