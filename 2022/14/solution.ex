defmodule AdventOfCode.Day14 do
  @moduledoc """
  Solution for Day14
  """
  require IEx

  @doc """
  Solves task 1 of Day 14
  """
  @spec solve() :: number()
  def solve() do
    data = read_input()
    {{min_x, _}, {max_x, _}} = data
    |> List.flatten()
    |> Enum.min_max_by(fn {x, _y} -> x end)
    {{_, min_y}, {_, max_y}} = data
    |> List.flatten()
    |> Enum.min_max_by(fn {_x, y} -> y end)

    IO.inspect({min_x, max_x}, label: "x dimensions")
    IO.inspect({0, max_y}, label: "y dimensions")

    # build a raster map
    image = build_image(data, {min_x, 0}, {max_x, max_y})
    draw(image) |> IO.write()

    # simulate the sand
    simulate_sand(image, {500 - min_x, 0})
    |> IO.inspect()
  end

  defp read_input() do
    grid = File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
  end

  defp parse_line(line) do
    line
    |> String.split(" -> ")
    |> Enum.map(fn coords ->
      [x, y] = String.split(coords, ",") |> Enum.map(&String.to_integer/1)
      {x, y}
    end)
  end

  defp build_image(data, {min_x, min_y}, {max_x, max_y}) do
    image = (
      for y <- 0..max_y-min_y do
        for x <- 0..max_x-min_x do
          "."
        end
      end)
    all_lines_normalized = data
      |> Enum.flat_map(fn points ->
        points
        |> Enum.chunk_every(2, 1)
        |> Enum.slice(0..-2)
        |> Enum.map(&normalize_line(&1, min_x, min_y))
        |> Enum.uniq()
      end)
    Enum.reduce(all_lines_normalized, image, fn line, img -> add_line_to_image(img, line) end)
  end

  defp normalize_line([{x1, y1}, {x2, y2}], min_x, min_y) do
    order_line({x1 - min_x, y1 - min_y}, {x2 - min_x, y2 - min_y})
  end

  defp order_line({x, y1}, {x, y2}) do
    if y1 <= y2 do
      {{x, y1}, {x, y2}}
    else
      {{x, y2}, {x, y1}}
    end
  end
  defp order_line({x1, y}, {x2, y}) do
    if x1 <= x2 do
      {{x1, y}, {x2, y}}
    else
      {{x2, y}, {x1, y}}
    end
  end

  defp add_line_to_image(image, {{x, y1}, {x, y2}}) do
    (for y <- y1..y2, do: {x, y})
    |> Enum.reduce(image, fn dot, img -> add_dot_to_image(img, dot) end)
  end
  defp add_line_to_image(image, {{x1, y}, {x2, y}}) do
    (for x <- x1..x2, do: {x, y})
    |> Enum.reduce(image, fn dot, img -> add_dot_to_image(img, dot) end)
  end

  defp add_dot_to_image(image, coords), do: add_char_to_image(image, coords, "█")
  defp add_sand_to_image(image, coords), do: add_char_to_image(image, coords, "⚹")

  defp add_char_to_image(image, {x, y}, char) do
    upd_row = image |> Enum.at(y) |> List.replace_at(x, char)
    List.replace_at(image, y, upd_row)
  end

  defp draw(image) do
    pic = Enum.map(image, fn row -> Enum.join(row, "") end)
    |> Enum.join("\n")
    pic <> "\n\n"
  end

  defp simulate_sand(image, sand_root) do
    do_simulate_sand(image, sand_root, sand_root, 0)
  end

  defp do_simulate_sand(image, sand_root, {x, y}, sands_counter) do
    # IO.write(draw(image))
    # upd_image = add_char_to_image(image, {x, y}, ".")
    {next_pos, is_settled} = cond do
      get_value(image, {x, y + 1}) == "." ->
        {{x, y + 1}, false}
      get_value(image, {x - 1, y + 1}) == "." ->
        {{x - 1, y + 1}, false}
      get_value(image, {x + 1, y + 1}) == "." ->
        # IO.puts("Go right!")
        {{x + 1, y + 1}, false}
      :is_settled ->
        {sand_root, true}
    end
    cond do
      is_finish?(image, next_pos) ->
        IO.write(draw(image))
        sands_counter
      is_settled == true ->
        # upd_image = add_sand_to_image(upd_image, next_pos)
        do_simulate_sand(add_sand_to_image(image, {x, y}), sand_root, next_pos, sands_counter + 1)
      is_settled == false ->
        # upd_image = add_sand_to_image(upd_image, next_pos)
        do_simulate_sand(image, sand_root, next_pos, sands_counter)
    end
  end

  defp get_value(image, {x, y}) do
    cond do
      y >= Enum.count(image) -> "."
      x < 0 -> "."
      x >= Enum.at(image, 0) |> Enum.count() -> "."
      :otherwise -> image |> Enum.at(y) |> Enum.at(x)
    end
  end

  defp is_finish?(image, {x, y}) do
    y >= Enum.count(image)
  end

  @doc """
  Solves task 2 of Day 14
  """
  @spec solve2() :: number()
  def solve2() do
    data = read_input()
    {_, max_y} = data
    |> List.flatten()
    |> Enum.max_by(fn {_x, y} -> y end)

    max_y = max_y + 2

    min_x = 500 - max_y
    max_x = 500 + max_y
    IO.inspect({min_x, max_x}, label: "x dimensions")
    IO.inspect({0, max_y}, label: "y dimensions")

    # build a raster map
    image = build_image(data, {min_x, 0}, {max_x, max_y})
      |> build_floor(max_y, min_x, max_x)
    draw(image) |> IO.write()

    # simulate the sand
    simulate_sand2(image, {500 - min_x, 0})
    |> IO.inspect()
  end

  defp build_floor(image, y, min_x, max_x) do
    floor = List.duplicate("X", max_x - min_x + 1)
    List.replace_at(image, y, floor)
  end

  defp simulate_sand2(image, sand_root) do
    do_simulate_sand2(image, sand_root, sand_root, 0)
  end

  defp do_simulate_sand2(image, sand_root, {x, y}, sands_counter) do
    # IO.write(draw(image))
    # upd_image = add_char_to_image(image, {x, y}, ".")
    {next_pos, is_settled} = cond do
      get_value2(image, {x, y + 1}) == "." ->
        {{x, y + 1}, false}
      get_value2(image, {x - 1, y + 1}) == "." ->
        {{x - 1, y + 1}, false}
      get_value2(image, {x + 1, y + 1}) == "." ->
        {{x + 1, y + 1}, false}
      :is_settled ->
        {sand_root, true}
    end
    cond do
      sand_root == {x, y} && is_settled ->
        IO.write(draw(image))
        sands_counter + 1
      is_settled == true ->
        upd_image = add_sand_to_image(image, {x, y})
        # IO.write(draw(upd_image))
        # upd_image = add_sand_to_image(upd_image, next_pos)
        do_simulate_sand2(upd_image, sand_root, next_pos, sands_counter + 1)
      is_settled == false ->
        # upd_image = add_sand_to_image(upd_image, next_pos)
        do_simulate_sand2(image, sand_root, next_pos, sands_counter)
    end
  end

  defp get_value2(image, {x, y}) do
    cond do
      y >= Enum.count(image) ->  raise "Out of range: y is too big"
      x < 0 -> raise "Out of range: x < 0"
      x >= Enum.at(image, 0) |> Enum.count() -> raise "Out of range: x is too big"
      :otherwise -> image |> Enum.at(y) |> Enum.at(x)
    end
  end
end
