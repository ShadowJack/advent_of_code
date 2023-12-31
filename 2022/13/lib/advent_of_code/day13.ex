defmodule AdventOfCode.Day13 do
  @moduledoc """
  Solution for AdventOfCode Day13.
  """

  @doc """
  Solves task 1 of Day13
  """
  @spec solve() :: number()
  def solve() do
    read_input()
    |> Enum.with_index()
    |> Enum.reduce(0, fn ({pair, idx}, acc) ->
      if is_valid?(pair) do
        acc + idx + 1
      else
        acc
      end
    end)
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n\n")
    |> Enum.map(&parse_pairs/1)
  end

  defp parse_pairs(lines) do
    [left, right] = lines
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&Jason.decode!(&1))

    {left, right}
  end

  defp is_valid?({left, left}), do: :equal
  defp is_valid?({left, right}) when is_list(left) and is_list(right) do
    IO.puts("Compare: #{inspect(left)} and #{inspect(right)}")
    results = Enum.zip(left, right)
    |> Enum.map(&is_valid?/1)
    result = case Enum.find(results, fn x -> x != :equal end) do
      true -> true
      false -> false
      nil ->
        cond do
          Enum.count(left) < Enum.count(right) -> true
          Enum.count(left) == Enum.count(right) -> :equal
          Enum.count(left) > Enum.count(right) -> false
        end
    end
    IO.puts("Compare: #{inspect(left)} and #{inspect(right)} => #{inspect(result)}")
    result
  end
  defp is_valid?({left, right}) when is_integer(left) and is_integer(right) do
    IO.puts("Compare: #{inspect(left)} and #{inspect(right)}")
    result = left < right
    IO.puts("Compare: #{inspect(left)} and #{inspect(right)} => #{result}")
    result
  end
  defp is_valid?({left, right}) when is_integer(left) and is_list(right) do
    IO.puts("Compare int and list: #{inspect(left)} and #{inspect(right)}")
    result = is_valid?({[left], right})
    IO.puts("Compare int and list: #{inspect(left)} and #{inspect(right)} => #{inspect(result)}")
    result
  end
  defp is_valid?({left, right}) when is_list(left) and is_integer(right) do
    IO.puts("Compare list and int: #{inspect(left)} and #{inspect(right)}")
    result = is_valid?({left, [right]})
    IO.puts("Compare list and int: #{inspect(left)} and #{inspect(right)} => #{inspect(result)}")
    result
  end

  @doc """
  Solves task 2 of Day13
  """
  @spec solve2() :: number()
  def solve2() do
    packets = [[[2]], [[6]]] ++ read_input2()
    f = File.open!("output.txt", [:write, :utf8])
    sorted = packets
    |> Enum.sort(&is_valid?({&1, &2}))
    IO.write(f, sorted |> Enum.map(&Kernel.inspect(&1)) |> Enum.join("\n"))
    File.close(f)
    first_marker = Enum.find_index(sorted, fn x -> x == [[2]] end) + 1 |> IO.inspect()
    second_marker = Enum.find_index(sorted, fn x -> x == [[6]] end) + 1 |> IO.inspect()
    first_marker * second_marker
  end

  defp read_input2() do
    File.read!("input.txt")
    |> String.replace("\n\n", "\n")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&Jason.decode!(&1))
  end
end
