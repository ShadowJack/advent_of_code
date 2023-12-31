defmodule AdventOfCode.Day24 do
  @moduledoc """
  Solution for Day24
  """
  require IEx
  alias AdventOfCode.Day24.BFS

  defmodule PriorityQueue do
    defstruct [:set]

    def new(), do: %__MODULE__{set: :gb_sets.empty()}
    def new([]), do: new()
    def new([{_prio, _elem} | _] = list), do: %__MODULE__{set: :gb_sets.from_list(list)}

    def add_with_priority(%__MODULE__{} = q, elem, prio) do
      # IO.puts("Adding #{inspect(elem)} with priority #{prio}")
      %{q | set: :gb_sets.add({prio, elem}, q.set)}
    end

    def size(%__MODULE__{} = q) do
      :gb_sets.size(q.set)
    end

    def contains?(%__MODULE__{} = q, elem) do
      :gb_sets.is_member(elem, q.set)
    end

    def extract_min(%__MODULE__{} = q) do
      case :gb_sets.size(q.set) do
        0 -> :empty
        _else ->
          {{prio, elem}, set} = :gb_sets.take_smallest(q.set)
          {{prio, elem}, %{q | set: set}}
      end
    end
  end


  defmodule BFS do
    alias AdventOfCode.Day24.PriorityQueue

    def run(start, finish, h, get_neighbors, steps \\ 0) do
      q = PriorityQueue.new() |> PriorityQueue.add_with_priority({start, steps}, h.(start))
      loop(q, finish, h, get_neighbors, [])
    end

    defp loop(queue, finish, h, get_neighbors, visited) do
      case PriorityQueue.extract_min(queue) do
        :empty -> raise "Path is not found"
        {{_prio, {^finish, steps}}, _u_queue} -> steps
        {{_prio, {curr, steps}}, u_queue} ->
          upd_visited = [{curr, steps} | visited]
          upd_queue = get_neighbors.(curr, steps)
          |> Enum.reject(fn neib -> Enum.any?(upd_visited, fn v -> v == {neib, steps + 1} end) end)
          |> Enum.reduce(u_queue, fn neib, upd_queue ->
            PriorityQueue.add_with_priority(upd_queue, {neib, steps + 1}, steps + h.(neib))
            # PriorityQueue.add_with_priority(upd_queue, {neib, steps + 1}, h.(neib))
          end)
          loop(upd_queue, finish, h, get_neighbors, upd_visited)
      end
    end
  end

  @doc """
  Solves task 1 of Day 24
  """
  @spec solve() :: number()
  def solve() do
    read_input()
    |> find_shortest_path()
  end

  defp read_input() do
    grid = File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.slice(1..-2)
    |> Enum.map(fn line ->
      line
      |> String.to_charlist()
      |> Enum.slice(1..-2)
    end)

    max_y = Enum.count(grid) - 1
    max_x = Enum.count(Enum.at(grid, 0)) - 1
    start = {0, -1}
    finish = {max_x, max_y + 1}

    blizzards = (for x <- 0..max_x, y <- 0..max_y, do: {x, y})
      |> Enum.reduce([], fn {x, y}, results ->
        case val_at(grid, x, y) do
          ?. -> results
          ?> -> [{x, y, ?>} | results]
          ?< -> [{x, y, ?<} | results]
          ?^ -> [{x, y, ?^} | results]
          ?v -> [{x, y, ?v} | results]
        end
      end)
    {max_x, max_y, start, finish, blizzards}
  end

  defp val_at(grid, x, y) do
    grid |> Enum.at(y) |> Enum.at(x)
  end

  defp find_shortest_path({max_x, max_y, start, finish, blizzards}) do
    BFS.run(start, finish, &heuristic(&1, finish), &get_neighbors(&1, &2, max_x, max_y, blizzards))
  end

  defp heuristic({x, y}, {fx, fy}) do
    abs(fx - x) + abs(fy - y)
  end

  defp get_neighbors({x, y}, steps, max_x, max_y, blizzards) do
    get_candidates(max_x, max_y, x, y)
    |> Enum.reject(fn {cx, cy} ->
      cx < 0 ||
      cy < 0 && cx != 0 || # special case for the initial position
      cx > max_x ||
      cy > max_y && cx != max_x ||
      is_in_blizzard({cx, cy}, steps + 1, max_x, max_y, blizzards)
    end)
  end

  defp get_candidates(_max_x, _max_y, 0, -1) do
    [{0, -1}, {0, 0}]
  end
  defp get_candidates(max_x, max_y, x, y) do
    if x == max_x && y == max_y + 1 do
      # finish
      [{x, y}, {x, y - 1}]
    else
      [{x, y}, {x - 1, y}, {x, y + 1}, {x + 1, y}, {x, y - 1}]
    end
  end

  # Check if the coordinate will be covered by any blizzard
  # from `blizzards` after `steps` steps
  defp is_in_blizzard({x, y}, steps, max_x, max_y, blizzards) do
    Enum.any?(blizzards, fn {bx, by, dir} ->
      cond do
        by == y && dir == ?< && bx == wrap(x + steps, max_x + 1) -> true
        by == y && dir == ?> && bx == wrap(x - steps, max_x + 1) -> true
        bx == x && dir == ?^ && by == wrap(y + steps, max_y + 1) -> true
        bx == x && dir == ?v && by == wrap(y - steps, max_y + 1) -> true
        :otherwise -> false
      end
    end)
  end

  defp wrap(coord, size) when coord >= 0 do
    rem(coord, size)
  end
  defp wrap(coord, size) do
    wrap(coord + size, size)
  end

  @doc """
  Solves task 2 of Day 24
  """
  @spec solve2() :: number()
  def solve2() do
    # start from finish and find the closest ?a
    read_input()
    |> find_shortest_path2()
  end

  defp find_shortest_path2({max_x, max_y, start, finish, blizzards}) do
    steps_start_to_finish = BFS.run(start, finish, &heuristic(&1, finish), &get_neighbors(&1, &2, max_x, max_y, blizzards), 0)
    steps_finish_to_start = BFS.run(finish, start, &heuristic(&1, start), &get_neighbors(&1, &2, max_x, max_y, blizzards), steps_start_to_finish)
    BFS.run(start, finish, &heuristic(&1, finish), &get_neighbors(&1, &2, max_x, max_y, blizzards), steps_finish_to_start)
  end
end
