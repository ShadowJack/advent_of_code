defmodule AdventOfCode.Day22 do
  @moduledoc """
  Solution for Day22
  """

  @doc """
  Solves task 1 of Day 22
  """
  @spec solve() :: number()
  def solve() do
    {map, path} = read_input()
    {x, y, dir} = simulate(map, path)
    1000 * (y + 1) + 4 * (x + 1) + points_for_dir(dir)
  end

  defp read_input() do
    [map, path] = File.read!("input.txt")
    |> String.split("\n\n")
    {parse_map(map), parse_path(path)}
  end

  defp parse_map(map) do
    lines = map
    |> String.trim("\n")
    |> String.split("\n")

    max_len = Enum.max_by(lines, fn line -> String.length(line) end) |> String.length()

    lines
    |> Enum.map(fn line ->
      line
      |> String.pad_trailing(max_len)
      |> String.graphemes()
    end)
  end

  defp parse_path(path) do
    Regex.scan(~r/\d+|L|R/, path)
    |> List.flatten()
    |> Enum.map(fn x ->
      case x do
        "R" -> "R"
        "L" -> "L"
        num -> String.to_integer(num)
      end
    end)
  end

  defp points_for_dir(dir) do
    case dir do
      "U" -> 3
      "R" -> 0
      "D" -> 1
      "L" -> 2
    end
  end

  defp simulate(map, path) do
    x = find_top_left(map)
    do_simulate(map, path, {x, 0, "R"})
  end

  defp find_top_left(map) do
    map
    |> Enum.at(0)
    |> Enum.find_index(fn x -> x != " " end)
  end

  defp do_simulate(_map, [], pos), do: pos
  defp do_simulate(map, [step | rest], pos) do
    new_pos = get_next_pos(map, pos, step)
    do_simulate(map, rest, new_pos)
  end

  defp get_next_pos(_map, {x, y, dir}, "L") do
    new_dir = case dir do
      "U" -> "L"
      "R" -> "U"
      "D" -> "R"
      "L" -> "D"
    end
    {x, y, new_dir}
  end
  defp get_next_pos(_map, {x, y, dir}, "R") do
    new_dir = case dir do
      "U" -> "R"
      "R" -> "D"
      "D" -> "L"
      "L" -> "U"
    end
    {x, y, new_dir}
  end
  defp get_next_pos(_map, pos, 0), do: pos
  defp get_next_pos(map, {x, y, dir}, steps) do
    {next_x, next_y} = get_next_coords(map, {x, y, dir})
    case at_map(map, next_x, next_y) do
      "#" -> {x, y, dir}
      "." -> get_next_pos(map, {next_x, next_y, dir}, steps - 1)
    end
  end

  defp get_next_coords(map, {x, y, dir}) do
    {new_x, new_y} = case dir do
      "U" -> {x, y - 1}
      "R" -> {x + 1, y}
      "D" -> {x, y + 1}
      "L" -> {x - 1, y}
    end
    max_x = (Enum.at(map, y) |> Enum.count()) - 1
    max_y = Enum.count(map) - 1
    cond do
      # check end of the field by coords
      new_x < 0 -> find_opposite_edge(map, {x, y, dir}, max_x, max_y)
      new_x > max_x -> find_opposite_edge(map, {x, y, dir}, max_x, max_y)
      new_y < 0 -> find_opposite_edge(map, {x, y, dir}, max_x, max_y)
      new_y > max_y -> find_opposite_edge(map, {x, y, dir}, max_x, max_y)
      # check end of the field by whitespace characters
      at_map(map, new_x, new_y) == " " -> find_opposite_edge(map, {x, y, dir}, max_x, max_y)
      # normal coordinates - just move straight
      :otherwise -> {new_x, new_y}
    end
  end

  defp at_map(map, x, y) do
    Enum.at(map, y) |> Enum.at(x)
  end

  defp find_opposite_edge(map, {x, y, dir}, max_x, max_y) do
    case dir do
      "U" ->
        # find the lowest available coord in the curr column
        found_y = map
          |> Enum.map(fn row -> Enum.at(row, x) end)
          |> Enum.reverse()
          |> Enum.find_index(fn val -> val != " " end)
        {x, max_y - found_y}
      "R" ->
        # find the left available coord in the curr row
        found_x = map
          |> Enum.at(y)
          |> Enum.find_index(fn val -> val != " " end)
        {found_x, y}
      "D" ->
        # find the highest available coord in the curr column
        found_y = map
          |> Enum.map(fn row -> Enum.at(row, x) end)
          |> Enum.find_index(fn val -> val != " " end)
        {x, found_y}
      "L" ->
        # find the right available coord in the curr row
        found_x = map
          |> Enum.at(y)
          |> Enum.reverse()
          |> Enum.find_index(fn val -> val != " " end)
        {max_x - found_x, y}
    end
  end

  @doc """
  Solves task 2 of Day 22
  """
  @spec solve2() :: number()
  def solve2() do
    {map, path} = read_input()

    width = map |> Enum.at(0) |> Enum.count()
    face_width = div(width, 3)
    height = map |> Enum.count()
    face_height = div(height, 4)
    cube = map_to_cube(map, width, height, face_width, face_height)

    {face_x, face_y, dir, face_id} = simulate2(cube, path)
    {x, y} = global_coords(face_x, face_y, face_id, face_width, face_height)
    1000 * (y + 1) + 4 * (x + 1) + points_for_dir(dir)
  end

  defp map_to_cube(map, width, height, face_width, face_height) do
    %{
      "1" => region_from_map(map, (2 * face_width)..(width - 1), 0..(face_height - 1)),
      "2" => region_from_map(map, face_width..(2 * face_width - 1), 0..(face_height - 1)),
      "3" => region_from_map(map, face_width..(2 * face_width - 1), face_height..(2 * face_height - 1)),
      "4" => region_from_map(map, face_width..(2 * face_width - 1), (2 * face_height)..(3 * face_height - 1)),
      "5" => region_from_map(map, 0..(face_width - 1), (2 * face_height)..(3 * face_height - 1)),
      "6" => region_from_map(map, 0..(face_width - 1), (3 * face_height)..(4 * face_height - 1))
    }
  end

  defp global_coords(x, y, face_id, face_width, face_height) do
    case face_id do
      "1" -> {x + 2 * face_width, y}
      "2" -> {x + face_width, y}
      "3" -> {x + face_width, y + face_height}
      "4" -> {x + face_width, y + 2 * face_height}
      "5" -> {x, y + 2 * face_height}
      "6" -> {x, y + 3 * face_height}
    end
  end

  defp region_from_map(map, xs, ys) do
    map
    |> Enum.slice(ys)
    |> Enum.map(fn row -> Enum.slice(row, xs) end)
  end

  defp simulate2(cube, path) do
    do_simulate2(cube, path, {0, 0, "R", "2"})
  end

  defp do_simulate2(_cube, [], pos), do: pos
  defp do_simulate2(cube, [step | rest], pos) do
    new_pos = get_next_pos2(cube, pos, step)
    do_simulate2(cube, rest, new_pos)
  end

  defp get_next_pos2(_cube, {x, y, dir, face_id}, "L") do
    new_dir = case dir do
      "U" -> "L"
      "R" -> "U"
      "D" -> "R"
      "L" -> "D"
    end
    {x, y, new_dir, face_id}
  end
  defp get_next_pos2(_cube, {x, y, dir, face_id}, "R") do
    new_dir = case dir do
      "U" -> "R"
      "R" -> "D"
      "D" -> "L"
      "L" -> "U"
    end
    {x, y, new_dir, face_id}
  end
  defp get_next_pos2(_cube, pos, 0), do: pos
  defp get_next_pos2(cube, {x, y, dir, face_id}, steps) do
    {next_x, next_y, next_dir, next_face_id} = get_next_coords2(cube, {x, y, dir, face_id})
    case at_map(cube[next_face_id], next_x, next_y) do
      "#" -> {x, y, dir, face_id}
      "." -> get_next_pos2(cube, {next_x, next_y, next_dir, next_face_id}, steps - 1)
    end
  end

  defp get_next_coords2(cube, {x, y, dir, face_id}) do
    {new_x, new_y} = case dir do
      "U" -> {x, y - 1}
      "R" -> {x + 1, y}
      "D" -> {x, y + 1}
      "L" -> {x - 1, y}
    end
    max_x = (Enum.at(cube[face_id], 0) |> Enum.count()) - 1
    max_y = Enum.count(cube[face_id]) - 1
    cond do
      new_x < 0 -> change_face({x, y, dir, face_id}, max_x, max_y)
      new_x > max_x -> change_face({x, y, dir, face_id}, max_x, max_y)
      new_y < 0 -> change_face({x, y, dir, face_id}, max_x, max_y)
      new_y > max_y -> change_face({x, y, dir, face_id}, max_x, max_y)
      # normal coordinates - just move straight
      :otherwise -> {new_x, new_y, dir, face_id}
    end
  end

  defp change_face({x, y, dir, face_id}, max_x, max_y) do
    case face_id do
      "1" ->
        case dir do
          "U" -> {x, max_y, "U", "6"}
          "R" -> {max_x, max_y - y, "L", "4"}
          "D" -> {max_x, x, "L", "3"}
          "L" -> {max_x, y, "L", "2"}
        end
      "2" ->
        case dir do
          "U" -> {0, x, "R", "6"}
          "R" -> {0, y, "R", "1"}
          "D" -> {x, 0, "D", "3"}
          "L" -> {0, max_y - y, "R", "5"}
        end
      "3" ->
        case dir do
          "U" -> {x, max_y, "U", "2"}
          "R" -> {y, max_y, "U", "1"}
          "D" -> {x, 0, "D", "4"}
          "L" -> {y, 0, "D", "5"}
        end
      "4" ->
        case dir do
          "U" -> {x, max_y, "U", "3"}
          "R" -> {max_x, max_y - y, "L", "1"}
          "D" -> {max_x, x, "L", "6"}
          "L" -> {max_x, y, "L", "5"}
        end
      "5" ->
        case dir do
          "U" -> {0, x, "R", "3"}
          "R" -> {0, y, "R", "4"}
          "D" -> {x, 0, "D", "6"}
          "L" -> {0, max_y - y, "R", "2"}
        end
      "6" ->
        case dir do
          "U" -> {x, max_y, "U", "5"}
          "R" -> {y, max_y, "U", "4"}
          "D" -> {x, 0, "D", "1"}
          "L" -> {y, 0, "D", "2"}
        end
    end
  end
end
