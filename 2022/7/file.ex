defmodule AdventOfCode.Day7.File do
  @enforce_keys [:size, :name]
  defstruct size: nil, name: nil
  @type t :: %__MODULE__{size: number(), name: String.t()}
end
