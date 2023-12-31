defmodule AdventOfCode.Day20 do
  @moduledoc """
  Solution for Day20
  """

  @doc """
  Solves task 1 of Day 20
  """
  @spec solve() :: number()
  def solve() do
    mixed = read_input()
    |> Enum.with_index()
    |> mix()
    |> Enum.map(fn {val, _idx} -> val end)

    zero_idx = Enum.find_index(mixed, fn val -> val == 0 end)
    indices = [zero_idx + 1000, zero_idx + 2000, zero_idx + 3000]
      |> Enum.map(&wrap_index(&1, Enum.count(mixed)))
      |> Enum.map(&Enum.at(mixed, &1))
      |> Enum.sum()
  end

  defp read_input() do
    mixed = File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&String.to_integer/1)
  end

  def mix(data) do
    0..(Enum.count(data) - 1)
    |> Enum.reduce(data, &shift_number(&2, &1))
  end

  def shift_number(data, idx) do
    curr_idx = Enum.find_index(data, fn {val, i} -> i == idx end)
    elem = Enum.at(data, curr_idx)
    new_idx = get_new_idx(data, curr_idx)
    data
    |> List.delete_at(curr_idx)
    |> List.insert_at(new_idx, elem)
  end

  def get_new_idx(data, idx) do
    result = rem(idx + elem(Enum.at(data, idx), 0), Enum.count(data) - 1)
    if result >= 0 do
      result
    else
      result - 1
    end
  end

  def wrap_index(idx, count) do
    rem(idx, count)
  end

  @doc """
  Solves task 2 of Day 20
  """
  @spec solve2() :: number()
  def solve2() do
    mixed = read_input()
    |> Enum.map(fn x -> x * 811589153 end)
    |> Enum.with_index()
    |> mix()
    |> mix()
    |> mix()
    |> mix()
    |> mix()
    |> mix()
    |> mix()
    |> mix()
    |> mix()
    |> mix()
    |> Enum.map(fn {val, _idx} -> val end)

    zero_idx = Enum.find_index(mixed, fn val -> val == 0 end)
    indices = [zero_idx + 1000, zero_idx + 2000, zero_idx + 3000]
      |> Enum.map(&wrap_index(&1, Enum.count(mixed)))
      |> Enum.map(&Enum.at(mixed, &1))
      |> Enum.sum()
  end
end
