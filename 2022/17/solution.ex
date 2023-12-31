defmodule AdventOfCode.Day17 do
  @moduledoc """
  Solution for Day17
  """

  @stop_after_rocks 2492 + 8483
  # @stop_after_rocks 2022
  @rocks [
      #0 ####
      [{0, 0}, {1, 0}, {2, 0}, {3, 0}],
      #2 .#.
      #1 ###
      #0 .#.
      [{1, 0}, {0, 1}, {1, 1}, {2, 1}, {1, 2}],
      #2 ..#
      #1 ..#
      #0 ###
      [{0, 0}, {1, 0}, {2, 0}, {2, 1}, {2, 2}],
      #3 #
      #2 #
      #1 #
      #0 #
      [{0, 0}, {0, 1}, {0, 2}, {0, 3}],
      #1 ##
      #0 ##
      [{0, 0}, {1, 0}, {0, 1}, {1, 1}]
    ]

  @doc """
  Solves task 1 of Day 17
  """
  @spec solve() :: number()
  def solve() do
    shifts = read_input()
    IO.inspect(Enum.count(shifts), label: "Shifts")
    simulate(shifts, @rocks)
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.trim()
    |> String.graphemes()
  end

  defp simulate(shifts, rocks) do
    do_simulate(shifts, rocks, {2, 3}, [], 0, 0, 0)
  end
  defp do_simulate(_shifts, _rocks, _coords, field, @stop_after_rocks, truncated, _counter) do
    IO.inspect(truncated, label: "Truncated")
    Enum.count(field) + truncated
  end
  defp do_simulate([shift | rest_shifts], [rock | rest_rocks], coords, field, settled_count, truncated, counter) do
    rem(counter, 50455) == 0 && IO.puts("Height: #{Enum.count(field) + truncated}, settled: #{settled_count}") || nil
    # 1. do the shift if possible
    coords_after_shift = try_shift(coords, shift, rock, field)
    # 2. go down if possible - if not - settle and update the state
    coords_after_move = try_move(coords_after_shift, rock, field)
    if coords_after_shift == coords_after_move do
      # the stone is settled - update state
      {upd_field, truncated_len} =
        field
        |> add_settled_rock(coords_after_move, rock)
        |> truncate_field()
      new_coords = {2, Enum.count(upd_field) + 3}
      do_simulate(rest_shifts ++ [shift], rest_rocks ++ [rock], new_coords, upd_field, settled_count + 1, truncated + truncated_len, counter + 1)
    else
      # move next
      do_simulate(rest_shifts ++ [shift], [rock | rest_rocks], coords_after_move, field, settled_count, truncated, counter + 1)
    end
  end

  defp try_shift({x, y}, shift, rock, field) do
    shifted_coords = shift == "<" && {x - 1, y} || {x + 1, y}
    if is_valid_position?(shifted_coords, rock, field) do
      shifted_coords
    else
      {x, y}
    end
  end

  defp try_move({x, y}, rock, field) do
    moved_coords = {x, y - 1}
    if is_valid_position?(moved_coords, rock, field) do
      moved_coords
    else
      {x, y}
    end
  end

  defp is_valid_position?({x, y}, rock, field) do
    # For each coord of the rock check if there's something in
    # the field or if this coord is out of the valid range
    Enum.all?(rock, fn {loc_x, loc_y} ->
      {abs_x, abs_y} = {x + loc_x, y + loc_y}
      cond do
        abs_x < 0 -> false
        abs_x > 6 -> false
        abs_y < 0 -> false
        abs_y >= Enum.count(field) -> true
        field |> Enum.at(abs_y) |> Enum.at(abs_x) == "#" -> false
        :otherwise -> true
      end
    end)
  end

  defp add_settled_rock(field, {x, y}, rock) do
    # add new rows if necessary
    curr_last_y = Enum.count(field) - 1
    {_, max_y} = Enum.max_by(rock, fn {_x, r_y} -> r_y end)
    new_last_y = y + max_y
    new_rows_count = new_last_y > curr_last_y && (new_last_y - curr_last_y) || 0
    # IO.puts("")
    extended_field = if new_rows_count > 0 do
      new_rows = for _ <- 0..new_rows_count-1, do: [".", ".", ".", ".", ".", ".", "."]
      field ++ new_rows
    else
      field
    end

    # add the rock
    Enum.reduce(rock, extended_field, fn {loc_x, loc_y}, curr_field ->
      upd_row = curr_field |> Enum.at(y + loc_y) |> List.replace_at(x + loc_x, "#")
      List.replace_at(curr_field, y + loc_y, upd_row)
    end)
  end

  defp truncate_field(field) do
    min_y = (for x <- 0..6, do: x)
    |> Enum.map(fn x ->
      reverse_max_y = field
        |> Enum.map(fn f -> Enum.at(f, x) end)
        |> Enum.reverse()
        |> Enum.find_index(fn val -> val == "#" end)
      if reverse_max_y == nil do
        -1
      else
        Enum.count(field) - 1 - reverse_max_y
      end
    end)
    |> Enum.min()

    if min_y == -1 do
      # do nothing
      {field, 0}
    else
      # truncate up to the min_y
      {Enum.drop(field, min_y + 1), min_y + 1}
    end
  end

  defp draw(field) do
    IO.puts("-------")
    field
    |> Enum.reverse()
    |> Enum.map(fn row -> Enum.join(row) end)
    |> Enum.join("\n")
    |> IO.write()
    IO.puts("")

    field
  end

end
