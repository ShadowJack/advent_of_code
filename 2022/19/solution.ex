defmodule AdventOfCode.Day19 do
  @moduledoc """
  Solution for Day19
  """

  require IEx
  @final_minute 33

  defmodule Resources do
    defstruct ore: 0, clay: 0, obsidian: 0, geode: 0
    @type t :: %__MODULE__{ore: number(), clay: number(), obsidian:  number(), geode: number()}
  end

  defmodule WorldState do
    defstruct minute: nil, resources: nil, robots: nil
    @type t :: %__MODULE__{minute: number(), resources: Resources.t(), robots: Resources.t()}
  end

  defmodule Blueprint do
    defstruct id: nil, ore: nil, clay: nil, obsidian: nil, geode: nil
    @type t :: %__MODULE__{id: number(), ore: Resources.t(), clay: Resources.t(), obsidian: Resources.t(), geode: Resources.t()}

    def parse(line) do
      reg = ~r/Blueprint (\d+): Each ore robot costs (\d+) ore\. Each clay robot costs (\d+) ore\. Each obsidian robot costs (\d+) ore and (\d+) clay\. Each geode robot costs (\d+) ore and (\d+) obsidian\./
      [id, ore_ore, clay_ore, obsidian_ore, obsidian_clay, geode_ore, geode_obsidian] = Regex.run(reg, line) |> Enum.drop(1) |> Enum.map(&String.to_integer/1)
      %__MODULE__{
        id: id,
        ore: %Resources{ore: ore_ore},
        clay: %Resources{ore: clay_ore},
        obsidian: %Resources{ore: obsidian_ore, clay: obsidian_clay},
        geode: %Resources{ore: geode_ore, obsidian: geode_obsidian}
      }
    end
  end

  @doc """
  Solves task 1 of Day 19
  """
  @spec solve() :: number()
  def solve() do
    read_input()
    |> Enum.map(&find_quality_level/1)
    |> Enum.sum()
  end

  defp read_input() do
    File.read!("input.txt")
    |> String.trim("\n")
    |> String.split("\n")
    |> Enum.map(&Blueprint.parse/1)
  end

  defp find_quality_level(blueprint) do
    blueprint.id * get_max_geodes(blueprint)
  end

  defp get_max_geodes(blueprint) do
    do_get_max_geodes(%WorldState{
      minute: 1,
      resources: %Resources{ore: 0, clay: 0, obsidian: 0, geode: 0},
      robots: %Resources{ore: 1, clay: 0, obsidian: 0, geode: 0}
    }, blueprint)
  end

  defp do_get_max_geodes(%WorldState{minute: @final_minute, resources: resources}, _blueprint) do
    resources.geode
  end
  defp do_get_max_geodes(curr_state, blueprint) do
    curr_state
    |> get_possilities(blueprint)
    |> Enum.map(fn next_robot ->
      curr_state
      |> build_next_robot(blueprint, next_robot)
      |> do_get_max_geodes(blueprint)
    end)
    |> Enum.max()
  end

  defp get_possilities(%WorldState{robots: robots}, blueprint) do
    [:ore, :clay, :obsidian, :geode]
    |> Enum.filter(&is_possible(&1, robots))
    |> Enum.reject(&is_already_enough_robots(&1, robots, blueprint))
  end

  defp is_possible(:ore, robots) do
    robots.ore > 0
  end
  defp is_possible(:clay, robots) do
    robots.ore > 0
  end
  defp is_possible(:obsidian, robots) do
    robots.ore > 0 && robots.clay > 0
  end
  defp is_possible(:geode, robots) do
    robots.ore > 0 && robots.obsidian > 0
  end

  defp is_already_enough_robots(:geode, _robots, _blueprint), do: false
  defp is_already_enough_robots(candidate, robots, blueprint) do
    max_required = [blueprint.ore, blueprint.clay, blueprint.obsidian, blueprint.geode]
    |> Enum.map(&Map.get(&1, candidate))
    |> Enum.max()
    Map.get(robots, candidate) >= max_required
  end

  defp build_next_robot(%WorldState{minute: @final_minute} = state, _blueprint, _next_robot) do
    state
  end
  defp build_next_robot(%WorldState{minute: min, resources: resources, robots: robots} = state, blueprint, next_robot) do
    required_resources = Map.get(blueprint, next_robot)
    if is_enough(resources, required_resources) do
      %WorldState{
        minute: min + 1,
        # produce and spend resources
        resources: %Resources{
          ore: resources.ore + robots.ore - required_resources.ore,
          clay: resources.clay + robots.clay - required_resources.clay,
          obsidian: resources.obsidian + robots.obsidian - required_resources.obsidian,
          geode: resources.geode + robots.geode - required_resources.geode
        },
        # build the next robot
        robots: Map.put(robots, next_robot, Map.get(robots, next_robot) + 1)
      }
    else
      build_next_robot(%WorldState{
          minute: min + 1,
          # produce resources
          resources: %Resources{
            ore: resources.ore + robots.ore,
            clay: resources.clay + robots.clay,
            obsidian: resources.obsidian + robots.obsidian,
            geode: resources.geode + robots.geode
          },
          robots: robots
        },
        blueprint,
        next_robot)
    end
  end

  defp is_enough(resources, required) do
    resources.ore >= required.ore &&
    resources.clay >= required.clay &&
    resources.obsidian >= required.obsidian &&
    resources.geode >= required.geode
  end

  @doc """
  Solves task 2 of Day 19
  """
  @spec solve2() :: number()
  def solve2() do
    read_input()
    |> Enum.take(3)
    |> Task.async_stream(&get_max_geodes/1, timeout: :infinity)
    |> Enum.reduce(1, fn {:ok, geodes}, acc -> acc * geodes end)
  end
end
