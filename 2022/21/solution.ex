defmodule AdventOfCode.Day21 do
  @moduledoc """
  Solution for Day21
  """

  @doc """
  Solves task 1 of Day 21
  """
  @spec solve() :: number()
  def solve() do
    data = read_input()
    root = Map.get(data, "root")
    calc(data, root)
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
    |> Map.new()
  end

  defp parse_line(line) do
    reg_number = ~r/([a-z]+): (\d+)/
    reg_operation = ~r/([a-z]+): ([a-z]+) (\+|\-|\/|\*) ([a-z]+)/

    if Regex.match?(reg_number, line) do
      [_, monkey, number] = Regex.run(reg_number, line)
      {monkey, String.to_integer(number)}
    else
      [_, monkey, left, op, right] = Regex.run(reg_operation, line)
      {monkey, {left, op, right}}
    end
  end

  defp calc(_data, num) when is_number(num), do: num
  defp calc(data, {left, op, right}) do
    left_val = Map.get(data, left)
    right_val = Map.get(data, right)
    case op do
      "+" -> calc(data, left_val) + calc(data, right_val)
      "-" -> calc(data, left_val) - calc(data, right_val)
      "*" -> calc(data, left_val) * calc(data, right_val)
      "/" -> calc(data, left_val) / calc(data, right_val)
    end
  end

  @doc """
  Solves task 2 of Day 21
  """
  @spec solve2() :: number()
  def solve2() do
    data = read_input()
    {left_name, _, right_name} = Map.get(data, "root")
    left = simplify(data, Map.get(data, left_name))
    right = simplify(data, Map.get(data, right_name))
    if is_number(left) do
      find_x(right, left)
    else
      find_x(left, right)
    end
  end

  defp simplify(_data, num) when is_number(num), do: num
  defp simplify(data, {"humn", op, right}) do
    {"humn", op, simplify(data, Map.get(data, right))}
  end
  defp simplify(data, {left, op, "humn"}) do
    {simplify(data, Map.get(data, left)), op, "humn"}
  end
  defp simplify(data, {left, op, right}) do
    left_result = simplify(data, Map.get(data, left))
    right_result = simplify(data, Map.get(data, right))
    cond do
      is_tuple(left_result) -> {left_result, op, right_result}
      is_tuple(right_result) -> {left_result, op, right_result}
      :both_are_numbers ->
        case op do
          "+" -> left_result + right_result
          "-" -> left_result - right_result
          "*" -> left_result * right_result
          "/" -> left_result / right_result
        end
    end
  end

  defp find_x({"humn", op, right}, required_value) do
    case op do
      "+" -> required_value - right
      "-" -> required_value + right
      "*" -> required_value / right
      "/" -> required_value * right
    end
  end
  defp find_x({left, op, "humn"}, required_value) do
    case op do
      "+" -> required_value - left
      "-" -> left - required_value
      "*" -> required_value / left
      "/" -> left / required_value
    end
  end
  defp find_x({left, op, right}, required_value) when is_number(right) do
    upd_required_value = case op do
      "+" -> required_value - right
      "-" -> required_value + right
      "*" -> required_value / right
      "/" -> required_value * right
    end
    find_x(left, upd_required_value)
  end
  defp find_x({left, op, right}, required_value) when is_number(left) do
    upd_required_value = case op do
      "+" -> required_value - left
      "-" -> left - required_value
      "*" -> required_value / left
      "/" -> left / required_value
    end
    find_x(right, upd_required_value)
  end
end
