defmodule AdventOfCode.Day23 do
  @moduledoc """
  Solution for Day23
  """

  @steps 10

  @doc """
  Solves task 1 of Day 23
  """
  @spec solve() :: number()
  def solve() do
    read_input()
    |> simulate(@steps)
    |> crop()
    |> count_free_cells()
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&String.graphemes/1)
  end

  defp simulate(map, rounds) do
    valid_directions = ["N", "S", "W", "E"]
    do_simulate(map, rounds, valid_directions)
  end

  defp do_simulate(map, 0, _directions), do: map
  defp do_simulate(map, rounds, directions) do
    proposals =
      map
      |> get_proposed_moves(directions)
      |> filter_proposals()

    upd_map = apply_proposals(map, proposals)
    upd_directions = Enum.drop(directions, 1) ++ [Enum.at(directions, 0)]
    do_simulate(upd_map, rounds - 1, upd_directions)
  end

  defp get_proposed_moves(map, directions) do
    max_y = Enum.count(map) - 1
    max_x = (Enum.at(map, 0) |> Enum.count()) - 1
    (for y <- 0..max_y, x <- 0..max_x, do: {x, y})
    |> Enum.reject(fn {x, y} -> at_map(map, x, y) == "." end)
    |> Task.async_stream(fn coords -> build_proposal(map, coords, directions, max_x, max_y) end)
    |> Enum.reduce([], fn {:ok, proposal}, result -> proposal != nil && [proposal | result] || result end)
    # |> IO.inspect(label: "Proposals")
  end

  defp build_proposal(map, {x, y}, directions, max_x, max_y) do
    north = [{x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1}] |> is_free(map, max_x, max_y)
    west = [{x - 1, y - 1}, {x - 1, y}, {x - 1, y + 1}] |> is_free(map, max_x, max_y)
    east = [{x + 1, y - 1}, {x + 1, y}, {x + 1, y + 1}] |> is_free(map, max_x, max_y)
    south = [{x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1}] |> is_free(map, max_x, max_y)
    if north && west && east && south do
    # noone around - stay in place
      nil
    else
      # propose a move
      Enum.find_value(directions, fn dir ->
        case dir do
          "N" -> north && {{x, y}, {x, y - 1}} || nil
          "W" -> west && {{x, y}, {x - 1, y}} || nil
          "E" -> east && {{x, y}, {x + 1, y}} || nil
          "S" -> south && {{x, y}, {x, y + 1}} || nil
        end
      end)
    end
  end

  defp is_free(coords, map, max_x, max_y) do
    coords
    |> Enum.all?(fn {x, y} ->
      x < 0 || x > max_x || y < 0 || y > max_y || at_map(map, x, y) == "."
    end)
  end

  defp filter_proposals(proposals) do
    # select moves that don't lead to duplicates
    Enum.reject(proposals, fn {{x, y}, {px, py}} ->
      Enum.any?(proposals, fn {{other_x, other_y}, {other_px, other_py}} ->
        (x != other_x || y != other_y) && px == other_px && py == other_py
      end)
    end)
  end

  defp apply_proposals(map, proposals) do
    {upd_map, upd_proposals} = reshape(map, proposals)
    # IO.puts("After reshape:")
    # draw(upd_map)

    # IO.inspect(upd_proposals, label: "Proposals")

    # IO.puts("After proposals are applied:")
    upd_proposals
    |> Enum.reduce(upd_map, fn {{x, y}, {px, py}}, curr_map ->
      curr_map
      |> replace_at_map(x, y, ".")
      |> replace_at_map(px, py, "#")
    end)
    # |> draw()
  end

  defp reshape(map, proposals) do
    ["N", "S", "W", "E"]
    |> Enum.reduce({map, proposals}, fn dir, {curr_map, curr_proposals} ->
      width = Enum.at(curr_map, 0) |> Enum.count()
      height = Enum.count(curr_map)
      case dir do
        "N" ->
          if Enum.any?(curr_proposals, fn {_, {_x, y}} -> y == -1 end) do
            new_row = for _ <- 0..(width - 1), do: "."
            extended_map = [new_row | curr_map]

            upd_proposals = curr_proposals
              |> Task.async_stream(fn {{x, y}, {px, py}} -> {{x, y + 1}, {px, py + 1}} end)
              |> Enum.reduce([], fn {:ok, res}, acc -> [res | acc] end)
            {extended_map, upd_proposals}
          else
            {curr_map, curr_proposals}
          end
        "S" ->
          if Enum.any?(curr_proposals, fn {_, {_x, y}} -> y == height end) do
            new_row = for _ <- 0..(width - 1), do: "."
            extended_map = curr_map ++ [new_row]

            {extended_map, curr_proposals}
          else
            {curr_map, curr_proposals}
          end
        "W" ->
          if Enum.any?(curr_proposals, fn {_, {x, _y}} -> x == -1 end) do
            extended_map = curr_map |> Enum.map(fn row -> ["." | row] end)

            # IO.inspect(curr_proposals, label: "Proposals before adding the first col")
            upd_proposals = curr_proposals
              |> Task.async_stream(fn {{x, y}, {px, py}} -> {{x + 1, y}, {px + 1, py}} end)
              |> Enum.reduce([], fn {:ok, res}, acc -> [res | acc] end)
            # IO.inspect(upd_proposals, label: "Proposals after adding the first col")
            {extended_map, upd_proposals}
          else
            {curr_map, curr_proposals}
          end
        "E" ->
          if Enum.any?(curr_proposals, fn {_, {x, _y}} -> x == width end) do
            extended_map = curr_map |> Enum.map(fn row -> row ++ ["."] end)

            {extended_map, curr_proposals}
          else
            {curr_map, curr_proposals}
          end
      end
    end)
  end

  defp at_map(map, x, y) do
    Enum.at(map, y) |> Enum.at(x)
  end

  defp replace_at_map(map, x, y, new_val) do
    new_row = Enum.at(map, y) |> List.replace_at(x, new_val)
    List.replace_at(map, y, new_row)
  end

  defp crop(map) do
    min_y = Enum.find_index(map, fn row -> Enum.any?(row, fn val -> val == "#" end) end)
    max_y = Enum.count(map) - Enum.find_index(Enum.reverse(map), fn row -> Enum.any?(row, fn val -> val == "#" end) end)
    min_x = (0..((Enum.at(map, 0) |> Enum.count()) - 1))
      |> Enum.find(fn x -> Enum.map(map, fn row -> Enum.at(row, x) end) |> Enum.any?(fn val -> val == "#" end) end)
    max_x = (((Enum.at(map, 0) |> Enum.count()) - 1)..0)
      |> Enum.find(fn x -> Enum.map(map, fn row -> Enum.at(row, x) end) |> Enum.any?(fn val -> val == "#" end) end)

    map
    |> Enum.slice(min_y..max_y)
    |> Enum.map(fn row -> Enum.slice(row, min_x..max_x) end)
  end

  defp count_free_cells(map) do
    List.flatten(map)
    |> Enum.count(fn val -> val == "." end)
  end

  defp draw(map) do
    map
    |> Enum.map(fn row -> Enum.join(row, "") end)
    |> Enum.join("\n")
    |> IO.write()
    IO.puts("")
    IO.puts("")
    map
  end

  @doc """
  Solves task 2 of Day 23
  """
  @spec solve2() :: number()
  def solve2() do
    read_input()
    |> simulate2()
  end

  defp simulate2(map) do
    valid_directions = ["N", "S", "W", "E"]
    do_simulate2(map, valid_directions, 1)
  end

  defp do_simulate2(map, directions, rounds) do
    proposals =
      map
      |> get_proposed_moves(directions)
      |> filter_proposals()

    if (Enum.empty?(proposals)) do
      rounds
    else
      upd_map = apply_proposals(map, proposals)
      upd_directions = Enum.drop(directions, 1) ++ [Enum.at(directions, 0)]
      do_simulate2(upd_map, upd_directions, rounds + 1)
    end
  end
end
