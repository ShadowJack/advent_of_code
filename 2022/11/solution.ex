defmodule AdventOfCode.Day11 do
  @moduledoc """
  Solution for Day11
  """

  defmodule AdventOfCode.Day11.Monkey do
    defstruct items: [], inspections_count: 0, operation: nil, test: nil
    @type t :: %__MODULE__{items: [number()], inspections_count: number(), operation: (number() -> number()), test: (number() -> number())}

    def parse(description) do
      [items, operation, test, if_true, if_false] = description
      |> String.trim("\n")
      |> String.split("\n")
      |> Enum.drop(1)
      |> Enum.map(&String.trim/1)

      %__MODULE__{
        items: parse_items(items),
        inspections_count: 0,
        operation: parse_operation(operation),
        test: parse_test(test, if_true, if_false)
      }
    end

    defp parse_items("Starting items: " <> items_str) do
      items_str
      |> String.split(", ")
      |> Enum.map(&String.to_integer/1)
    end

    defp parse_operation("Operation: new = old * old") do
      fn old -> old * old end
    end
    defp parse_operation("Operation: new = old * " <> val) do
      fn old -> old * String.to_integer(val) end
    end
    defp parse_operation("Operation: new = old + " <> val) do
      fn old -> old + String.to_integer(val) end
    end

    defp parse_test("Test: divisible by " <> divider, "If true: throw to monkey " <> true_monkey, "If false: throw to monkey " <> false_monkey) do
      fn value ->
        if rem(value, String.to_integer(divider)) == 0 do
          String.to_integer(true_monkey)
        else
          String.to_integer(false_monkey)
        end
      end
    end
  end

  alias AdventOfCode.Day11.Monkey

  @doc """
  Solves task 1 of Day 11
  """
  @spec solve() :: number()
  def solve() do
    monkeys = read_input()
    Enum.reduce(1..20, monkeys, fn _, m -> play_round(m) end)
    |> Enum.map(fn m -> m.inspections_count end)
    |> Enum.sort(:desc)
    |> Enum.take(2)
    |> Enum.reduce(1, fn el, acc -> el * acc end)
  end

  defp read_input() do
    File.read!("input.txt")
      |> String.split("\n\n")
      |> Enum.map(&AdventOfCode.Day11.Monkey.parse/1)
  end

  defp play_round(monkeys) do
    monkeys_count = Enum.count(monkeys)
    Enum.reduce(0..(monkeys_count-1), monkeys, &play_monkey/2)
  end

  defp play_monkey(idx, monkeys) do
    monkey = Enum.at(monkeys, idx)
    Enum.reduce(monkey.items, monkeys, &process_item(&1, &2, monkey))
    |> List.replace_at(idx, %Monkey{monkey | items: [], inspections_count: monkey.inspections_count + Enum.count(monkey.items)})
  end

  defp process_item(item, monkeys, %Monkey{operation: operation, test: test}) do
    # do operation and divide by 3
    new_val = div(operation.(item), 3)
    # make a test
    next_monkey_idx = test.(new_val)
    # pass the item to the next monkey
    next_monkey = Enum.at(monkeys, next_monkey_idx)
    upd_next_monkey = %Monkey{next_monkey | items: next_monkey.items ++ [new_val]}
    monkeys
    |> List.replace_at(next_monkey_idx, upd_next_monkey)
  end

  @doc """
  Solves task 2 of Day 11
  """
  @spec solve2() :: number()
  def solve2() do
    monkeys = read_input()
    Enum.reduce(1..10_000, monkeys, fn _, m -> play_round2(m) end)
    |> Enum.with_index()
    |> Enum.sort_by(fn {monkey, idx} -> monkey.inspections_count end, :desc)
    |> Enum.take(2)
    |> Enum.map(fn {m, _} -> m.inspections_count end)
    |> Enum.reduce(1, fn el, acc -> el * acc end)
  end

  defp play_round2(monkeys) do
    monkeys_count = Enum.count(monkeys)
    result = Enum.reduce(0..(monkeys_count-1), monkeys, &play_monkey2/2)
    IO.puts("")
    result
  end

  defp play_monkey2(idx, monkeys) do
    monkey = Enum.at(monkeys, idx)

    Enum.reduce(monkey.items, monkeys, &process_item2(&1, &2, monkey))
    |> List.replace_at(idx, %Monkey{monkey | items: [], inspections_count: monkey.inspections_count + Enum.count(monkey.items)})
  end

  defp process_item2(item, monkeys, %Monkey{operation: operation, test: test}) do
    # do operation
    new_val = rem(operation.(item), 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19)
    # make a test
    next_monkey_idx = test.(new_val)
    # pass the item to the next monkey
    next_monkey = Enum.at(monkeys, next_monkey_idx)
    upd_next_monkey = %Monkey{next_monkey | items: next_monkey.items ++ [new_val]}
    monkeys
    |> List.replace_at(next_monkey_idx, upd_next_monkey)
  end
end
