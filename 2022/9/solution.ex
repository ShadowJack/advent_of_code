defmodule AdventOfCode.Day9 do
  @moduledoc """
  Solution for Day9
  """

  @doc """
  Solves task 1 of Day 9
  """
  @spec solve() :: number()
  def solve() do
    input = read_input()
    head = {0, 0}
    tail = {0, 0}
    tail_positions = calculate_tail_positions(input, head, tail)
    tail_positions |> Enum.uniq() |> Enum.count()
  end

  defp read_input() do
    File.read!("input.txt")
      |> String.split("\n")
      |> Enum.slice(0..-2)
      |> Enum.map(&parse_row/1)
      |> List.flatten()
  end
  defp parse_row(row) do
    [direction, steps] = String.split(row, " ")
    int_steps = String.to_integer(steps)
    for _ <- 1..int_steps, do: direction
  end

  defp calculate_tail_positions(input, head, tail) do
    do_calculate_tail_positions(input, head, tail, [{0, 0}])
  end

  defp do_calculate_tail_positions([], _head, _tail, results), do: results
  defp do_calculate_tail_positions([dir | rest], head, tail, results) do
    new_head = move_head(head, dir)
    new_tail = move_tail(tail, head, new_head)
    do_calculate_tail_positions(rest, new_head, new_tail, [new_tail | results])
  end

  defp move_head({x, y}, dir) do
    case dir do
      "D" -> {x, y - 1}
      "L" -> {x - 1, y}
      "U" -> {x, y + 1}
      "R" -> {x + 1, y}
    end
  end

  defp move_tail({tx, ty}, {hx, hy}, {new_hx, new_hy}) do
    cond do
      # head and tail are still adjacent
      abs(tx - new_hx) <= 1 && abs(ty - new_hy) <= 1 ->
        {tx, ty}
      # head and tail were on a diagonal - move tail to prev head's position
      tx != hx && ty != hy ->
        {hx, hy}
      # straight - apply difference between new head and prev head to tail
      :otherwise ->
        {tx + new_hx - hx, ty + new_hy - hy}
    end
  end

  @doc """
  Solves task 2 of Day 9
  """
  @spec solve2() :: number()
  def solve2() do
    input = read_input()
    rope = (for _ <- 1..10, do: {0, 0})
    tail_positions = calculate_tail_positions(input, rope)
    # {{min_x, _}, {max_x, _}} = Enum.min_max_by(tail_positions, fn {x, _} -> x end)
    # {{_, min_y}, {_, max_y}} = Enum.min_max_by(tail_positions, fn {_, y} -> y end)
    # IO.puts("x: #{min_x}-#{max_x}; y: #{min_y}-#{max_y}")
    tail_positions |> Enum.uniq() |> Enum.count()
  end

  defp calculate_tail_positions(input, rope) do
    do_calculate_tail_positions(input, rope, [{0, 0}])
  end

  defp do_calculate_tail_positions([], _rope, results), do: results
  defp do_calculate_tail_positions([dir | rest], rope, results) do
    # draw_rope(rope)
    new_rope = move_rope(rope, dir)
    do_calculate_tail_positions(rest, new_rope, [List.last(new_rope) | results])
  end

  defp move_rope([head | rest], dir) do
    new_head = move_head(head, dir)
    move_nodes(rest, head, new_head, [new_head]) |> Enum.reverse()
  end

  defp move_nodes([], _head, _new_head, results), do: results
  defp move_nodes([node | rest], head, new_head, results) do
    new_node = move_node(node, head, new_head)
    move_nodes(rest, node, new_node, [new_node | results])
  end

  defp move_node({x, y}, {prev_hx, prev_hy}, {new_hx, new_hy}) do
    cond do
      # head and tail are still adjacent
      abs(x - new_hx) <= 1 && abs(y - new_hy) <= 1 ->
        {x, y}
      # prev node is moved by a diagonal - curr node should be moved in the same direction if they are not no the same row or col
      new_hx != prev_hx && new_hy != prev_hy ->
        cond do
          new_hx == x -> {x, y + new_hy - prev_hy}
          new_hy == y -> {x + new_hx - prev_hx, y}
          :otherwise -> {x + new_hx - prev_hx, y + new_hy - prev_hy}
        end
      # head and tail were on a diagonal - move tail to prev head's position
      x != prev_hx && y != prev_hy ->
        {prev_hx, prev_hy}
      # straight - apply difference between new head and prev head to tail
      :otherwise ->
        {x + new_hx - prev_hx, y + new_hy - prev_hy}
    end
  end

  defp draw_rope(rope) do
    grid = (
      for y <- -5..15 do
        for x <- -11..14 do
          {y, x, "·"}
        end
      end
    )
    {drawn_grid, _} = Enum.reduce(rope, {grid, 0}, fn (node, {g, idx}) ->
      updated_grid = draw_node(node, g, idx)
      {updated_grid, idx + 1}
    end)
    # print to file
    {:ok, file} = File.open("output.txt", [:utf8, :append])
    drawn_grid
    |> Enum.reverse()
    |> Enum.each(fn row ->
      row_str = row |> Enum.map(fn {_, _, val} -> val end) |> Enum.join("")
      IO.puts(file, row_str)
    end)
    IO.puts(file, "")
    File.close(file)
  end

  defp draw_node({x, y}, grid, node_number) do
    # check if there's already something in the spot
    row_idx = Enum.find_index(grid, fn r ->
      {gy, _, _} = List.first(r)
      gy == y
    end)
    row = Enum.at(grid, row_idx)
    col_idx = Enum.find_index(row, fn {_, gx, _} -> gx == x end)
    {_, _, grid_val} = Enum.at(row, col_idx)
    if grid_val != "·" do
      grid
    else
      # draw node value
      upd_row = List.replace_at(row, col_idx, {y, x, to_string(node_number)})
      List.replace_at(grid, row_idx, upd_row)
    end
  end
end
