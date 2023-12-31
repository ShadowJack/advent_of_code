defmodule AdventOfCode.Day7.Folder do
  alias AdventOfCode.Day7.File

  @enforce_keys [:name]
  defstruct name: nil, files: [], folders: []
  @type t :: %__MODULE__{files: [File.t()], folders: [__MODULE__.t()]}
end
