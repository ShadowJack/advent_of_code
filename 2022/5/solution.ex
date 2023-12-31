defmodule AdventOfCode.Day5 do
  @moduledoc """
  Solution for Day5
  """

  @doc """
  Solves task 1 of Day 5
  """
  @spec solve() :: number()
  def solve() do
    {stacks, moves} = read_input()
    moves
    |> Enum.reduce(stacks, &apply_move/2)
    |> Enum.map(fn stack -> List.first(stack) end)
    |> Enum.join()
  end

  defp read_input() do
    lines = File.read!("input.txt")
      |> String.split("\n")
      |> Enum.slice(0..-2)
    stacks = read_stacks(lines)
    moves = read_moves(lines)
    {stacks, moves}
  end

  defp read_stacks(lines) do
    stack_lines = Enum.take_while(lines, fn line -> line =~ "]" end)
    stacks_count = List.last(stack_lines) |> String.split(" ") |> Enum.count()
    stack_lines
    |> Enum.reduce(build_initial_stacks(stacks_count), &parse_stacks_line/2)
  end

  defp build_initial_stacks(count) do
    for _ <- 1..count, do: []
  end

  defp parse_stacks_line(line, stacks) do
    items = line
    |> String.graphemes()
    |> Enum.chunk_every(3, 4)
    |> Enum.map(fn x -> Enum.at(x, 1) end)

    Enum.zip_reduce(items, stacks, [], fn item, stack, result -> if item == " ", do: [stack | result], else: [stack ++ [item] | result] end)
    |> Enum.reverse()
  end

  defp read_moves(lines) do
    lines
    |> Enum.drop_while(fn line -> not String.starts_with?(line, "move") end)
    |> Enum.map(fn line ->
      result = Regex.run(~r/move (\d+) from (\d) to (\d)/, line) |> Enum.drop(1)
        |> Enum.zip_reduce([:count, :from, :to], Keyword.new(), fn val, key, acc -> Keyword.put(acc, key, String.to_integer(val)) end)
    end)
  end

  defp apply_move(move, stacks) do
    do_apply_move(stacks, move[:from]-1, move[:to]-1, move[:count])
  end

  defp do_apply_move(stacks, _, _, 0) do
    stacks
  end
  defp do_apply_move(stacks, from, to, count) do
    [elem | updated_from] = Enum.at(stacks, from)
    updated_to = [elem | Enum.at(stacks, to)]
    updated_stacks = stacks
      |> List.replace_at(from, updated_from)
      |> List.replace_at(to, updated_to)
    do_apply_move(updated_stacks, from, to, count - 1)
  end



  @doc """
  Solves task 2 of Day 5
  """
  @spec solve2() :: number()
  def solve2() do
    {stacks, moves} = read_input()
    moves
    |> Enum.reduce(stacks, &apply_move2/2)
    |> Enum.map(fn stack -> List.first(stack) end)
    |> Enum.join()
  end

  defp apply_move2(move, stacks) do
    from = Enum.at(stacks, move[:from] - 1)
    to = Enum.at(stacks, move[:to] - 1)
    {elements, updated_from} = Enum.split(from, move[:count])
    updated_to = elements ++ to
    stacks
      |> List.replace_at(move[:from] - 1, updated_from)
      |> List.replace_at(move[:to] - 1, updated_to)
  end
end
