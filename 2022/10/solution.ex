defmodule AdventOfCode.Day10 do
  @moduledoc """
  Solution for Day 10
  """

  @doc """
  Solves task 1 of Day 10
  """
  @spec solve() :: number()
  def solve() do
    {result, _} =
      read_input()
      |> calc_cycles()
      |> Enum.drop(19)
      |> Enum.take_every(40)
      |> Enum.reduce({0, 20}, fn x, {result, cycle} -> {result + cycle * x, cycle + 40} end)

    result
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.split("\n")
    |> Enum.slice(0..-2)
    |> Enum.map(&parse_row/1)
  end

  defp parse_row("noop"), do: {"noop"}
  defp parse_row("addx " <> val), do: {"addx", String.to_integer(val)}

  defp calc_cycles(commands) do
    do_calc_cycles(commands, 1, [])
    |> Enum.reverse()
  end

  defp do_calc_cycles([], _, results), do: results

  defp do_calc_cycles([{"noop"} | rest], x, results) do
    do_calc_cycles(rest, x, [x | results])
  end

  defp do_calc_cycles([{"addx", val} | rest], x, results) do
    do_calc_cycles(rest, x + val, [x | [x | results]])
  end

  @doc """
  Solves task 2 of Day 10
  """
  @spec solve2() :: number()
  def solve2() do
    read_input()
    |> calc_cycles()
    |> Enum.with_index()
    |> Enum.map(fn {x, idx} -> abs(x -  rem(idx, 40)) <= 1 && "#" || "." end)
    |> Enum.chunk(40)
    |> draw()
  end

  defp draw(pixels) do
    Enum.each(pixels, fn row -> IO.puts(Enum.join(row)) end)
  end
end
