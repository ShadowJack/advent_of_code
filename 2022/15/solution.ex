defmodule AdventOfCode.Day15 do
  @moduledoc """
  Solution for Day15
  """
  require IEx

  @target_row 2_000_000 # result = 4883971
  # @target_row 10

  @doc """
  Solves task 1 of Day 15
  """
  @spec solve() :: number()
  def solve() do
    data = read_input()
    beacons = get_beacons(data)
    data
    |> Enum.map(&get_covered_interval(&1, @target_row))
    |> Enum.reject(fn x -> x == nil end)
    |> merge_intervals()
    |> count_covered_points()
    |> remove_beacons(beacons, @target_row)
    |> IO.inspect()
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
  end

  defp parse_line(line) do
    [
      [_, sx, sy],
      [_, bx, by]
    ] = Regex.scan(~r/x=(-?\d+), y=(-?\d+)/, line)
    {{String.to_integer(sx), String.to_integer(sy)}, {String.to_integer(bx), String.to_integer(by)}}
  end

  defp get_beacons(data) do
    data
    |> Enum.map(fn {_sensor, beacon} -> beacon end)
  end

  defp get_covered_interval({sensor, beacon}, target_row) do
    # find distance between the sensor and the beacon
    distance = get_distance(sensor, beacon)
    sx = elem(sensor, 0)
    # go left and right until the points are covered by the sensor
    distance_to_target_row = get_distance(sensor, {sx, target_row})
    if distance_to_target_row > distance do
      nil
    else
      right_border = sx + distance - distance_to_target_row
      left_border = sx - distance + distance_to_target_row
      left_border..right_border
    end
  end

  defp get_distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  defp merge_intervals(intervals) do
    intervals
    |> Enum.sort_by(fn x -> x.first end)
    |> Enum.reduce([], &merge_interval/2)
  end

  defp merge_interval(interval, []), do: [interval]
  defp merge_interval(interval, [last | rest] = results) do
    if Range.disjoint?(interval, last) do
      # no intersection - add a new interval
      [interval | results]
    else
      # intersection - extend the last result
      [Range.new(last.first, max(last.last, interval.last)) | rest]
    end
  end

  defp count_covered_points(intervals) do
    intervals
    |> Enum.reduce(0, fn i, acc -> acc + (i.last - i.first + 1) end)
  end

  defp remove_beacons(sum, beacons, target_row) do
    beacons_count = beacons
      |> Enum.filter(fn {_x, y} -> y == target_row end)
      |> Enum.uniq()
      |> Enum.count()
    max(sum - beacons_count, 0)
  end

  @doc """
  Solves task 2 of Day 15
  """
  @spec solve2() :: number()
  def solve2() do
    data = read_input()
    {bx, by} = Enum.find_value(0..4_000_000, fn y ->
      intervals = data
      |> Enum.map(&get_clipped_covered_interval(&1, y))
      |> Enum.reject(fn int -> int == nil end)
      |> merge_intervals()
      |> Enum.reverse()

      case intervals do
        [0..4_000_000] -> nil
        [1..4_000_000] -> {0, y}
        [0..3_999_999] -> {4_000_000, y}
        [left, right] -> {left.last + 1, y}
      end
    end) |> IO.inspect()

    result = bx * 4_000_000 + by
    IO.inspect(result)
  end

  defp get_clipped_covered_interval({sensor, beacon}, target_row) do
    # find distance between the sensor and the beacon
    distance = get_distance(sensor, beacon)
    sx = elem(sensor, 0)
    # go left and right until the points are covered by the sensor
    distance_to_target_row = get_distance(sensor, {sx, target_row})
    if distance_to_target_row > distance do
      nil
    else
      right_border = min(sx + distance - distance_to_target_row, 4_000_000)
      left_border = max(sx - distance + distance_to_target_row, 0)
      if (right_border < left_border) do
        nil
      else
        left_border..right_border
      end
    end
  end
end
