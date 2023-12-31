defmodule AdventOfCode.Day1 do
	@moduledoc """
	Solution for Day1
	"""

	@doc """
	Solves task 1 of Day 1
	"""
	@spec solve() :: number()
	def solve() do
				read_input()
								|> summarize()
								|> find_max()
	end

				@doc """
				Solves task 2 of Day 1
				"""
				@spec solve2() :: number()
				def solve2() do
								read_input()
								|> summarize()
								|> find_3_max()
				end

  defp read_input() do
				File.read!("input.txt")
				|> String.split("\n")
  end

				defp summarize(list) do
								do_summarize(list, [])
								|> Enum.reverse()
				end

				defp do_summarize([], result) do
								result
				end
				defp do_summarize(["" | _tail] = list, []) do
								do_summarize(list, [0])
				end
				defp do_summarize([head | tail], []) do
								{int_head, _reminder} = Integer.parse(head)
								do_summarize(tail, [int_head])
				end
				defp do_summarize(["" | tail], result) do
								do_summarize(tail, [0 | result])
				end
				defp do_summarize([head | tail], [current | rest]) do
								{int_head, _reminder} = Integer.parse(head)
								do_summarize(tail, [current + int_head | rest])
				end

				defp find_max([]) do
					0
				end
				defp find_max(list) do
					Enum.max(list)
				end

				defp find_3_max([]) do
								0
				end
				defp find_3_max(list) do
								do_find_3_max(list, [0, 0, 0])
				end

				defp do_find_3_max([], results) do
					Enum.sum(results)
				end
				defp do_find_3_max([head | tail], [a, _b, _c] = results) when head < a do
								do_find_3_max(tail, results)
				end
				defp do_find_3_max([head | tail], [_a, b, c]) do
								new_results = [head, b, c] |> Enum.sort()
								do_find_3_max(tail, new_results)
				end

end
