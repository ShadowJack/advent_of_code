defmodule AdventOfCode.Day7 do
  @moduledoc """
  Solution for Day7
  """

  @doc """
  Solves task 1 of Day 7
  """
  @spec solve() :: number()
  def solve() do
    read_input()
      |> parse_log()
      |> get_all_folders_with_sizes()
      |> Enum.filter(fn {_, size} -> size <= 100_000 end)
      |> Enum.reduce(0, fn {_, size}, acc -> acc + size end)
  end

  defp read_input() do
    File.read!("input.txt")
      |> String.split("\n")
      |> Enum.slice(0..-2)
  end

  defp parse_log(logs) do
    do_parse_log(logs, %AdventOfCode.Day7.Folder{name: "/"}, "/")
  end

  defp do_parse_log([], file_system, _pwd) do
    file_system
  end
  defp do_parse_log(["$ ls" | rest], file_system, pwd) do
    print_debug(file_system, pwd, "$ ls")
    do_parse_log(rest, file_system, pwd)
  end
  defp do_parse_log(["$ cd /" | rest], file_system, pwd) do
    print_debug(file_system, pwd, "$ cd /")
    do_parse_log(rest, file_system, "/")
  end
  defp do_parse_log(["$ cd .." | rest], file_system, pwd) do
    print_debug(file_system, pwd, "$ cd ..")
    do_parse_log(rest, file_system, go_up(pwd))
  end
  defp do_parse_log(["$ cd " <> dir_name | rest], file_system, pwd) do
    print_debug(file_system, pwd, "$ cd #{dir_name}")
    # check if the folder is already in the file system
    # if not - add it
    updated_file_system = try_add_folder(file_system, pwd, dir_name)
    updated_pwd = pwd == "/" && "/#{dir_name}" || "#{pwd}/#{dir_name}"
    do_parse_log(rest, updated_file_system, updated_pwd)
  end
  defp do_parse_log(["dir " <> dir_name | rest], file_system, pwd) do
    print_debug(file_system, pwd, "dir #{dir_name}")
    # ignore this log entry, as we'll add this in the `cd {dir_name}`
    do_parse_log(rest, file_system, pwd)
  end
  defp do_parse_log([file_info | rest], file_system, pwd) do
    print_debug(file_system, pwd, file_info)
    # add info about the file to the folder at pwd
    updated_file_system = try_add_file(file_system, pwd, parse_file_info(file_info))
    do_parse_log(rest, updated_file_system, pwd)
  end

  defp print_debug(file_system, pwd, log_entry) do
    # IO.puts("----")
    # IO.puts("pwd: #{pwd}")
    # IO.puts("Log entry: #{log_entry}")
    # IO.puts("File system: #{inspect(file_system)}")
  end

  defp go_up("/" <> pwd) do
    relative_path = pwd
      |> String.split("/")
      |> Enum.drop(-1)
      |> Enum.join("/")
    "/#{relative_path}"
  end

  defp try_add_folder(fs, pwd, dir_name) do
    curr_folder = get_folder_at_path(fs, pwd)
    if Enum.any?(curr_folder.folders, fn f -> f.name == dir_name end) do
      # the folder is already present in the file system
      fs
    else
      # add the new folder
      updated_curr_folder = %{curr_folder | folders: [%AdventOfCode.Day7.Folder{name: dir_name} | curr_folder.folders]}
      replace_folder_at_path(fs, pwd, updated_curr_folder)
    end
  end

  defp get_folder_at_path(fs, "/") do
    fs
  end
  defp get_folder_at_path(fs, "/" <> pwd) do
    do_get_folder_at_path(fs, String.split(pwd, "/"))
  end
  defp do_get_folder_at_path(folder, []) do
    folder
  end
  defp do_get_folder_at_path(folder, [path_part | rest]) do
    inner_folder = folder.folders |> Enum.find(fn f -> f.name == path_part end)
    do_get_folder_at_path(inner_folder, rest)
  end

  defp replace_folder_at_path(_fs, "/", updated_folder) do
    updated_folder
  end
  defp replace_folder_at_path(fs, "/" <> pwd, updated_folder) do
      do_replace_folder_at_path(fs, pwd |> String.split("/"), updated_folder)
  end
  defp do_replace_folder_at_path(folder, [_folder_name], updated_folder) do
    idx = Enum.find_index(folder.folders, fn f -> f.name == updated_folder.name end)
    updated_folders =  List.replace_at(folder.folders, idx, updated_folder)
    %{folder | folders: updated_folders}
  end
  defp do_replace_folder_at_path(folder, [curr_path_part | rest], updated_folder) do
    child_folder = Enum.find(folder.folders, fn f -> f.name == curr_path_part end) |> do_replace_folder_at_path(rest, updated_folder)
    idx = Enum.find_index(folder.folders, fn f -> f.name == curr_path_part end)
    updated_folders = List.replace_at(folder.folders, idx, child_folder)
    %{folder | folders: updated_folders}
  end

  defp parse_file_info(file_info) do
    [size_str, name] = String.split(file_info, " ")
    %AdventOfCode.Day7.File{size: String.to_integer(size_str), name: name}
  end

  defp try_add_file(file_system, pwd, file) do
    curr_folder = get_folder_at_path(file_system, pwd)
    if Enum.any?(curr_folder.files, fn f -> f.name == file.name end) do
      # the file is already present in the file system
      file_system
    else
      # add the new file
      updated_curr_folder = %{curr_folder | files: [file | curr_folder.files]}
      replace_folder_at_path(file_system, pwd, updated_curr_folder)
    end
  end

  defp get_all_folders_with_sizes(folder) do
    child_results = Enum.map(folder.folders, fn f -> get_all_folders_with_sizes(f) end)
    folder_size =  Enum.reduce(child_results, 0, fn ([{_, size} | _subfolders], acc) -> acc + size end) + Enum.reduce(folder.files, 0, fn f, acc -> acc + f.size end)
    all_child_folders = List.flatten(child_results)
    [{folder.name, folder_size} | all_child_folders]
  end


  @doc """
  Solves task 2 of Day 7
  """
  @spec solve2() :: number()
  def solve2() do
    folders_with_sizes = read_input()
      |> parse_log()
      |> get_all_folders_with_sizes()
    [{_root_name, total_occupied} | _rest] = folders_with_sizes
    IO.puts("Occupied: #{total_occupied}")
    free_space = 70_000_000 - total_occupied
    IO.puts("Free space: #{free_space}")
    space_to_free_up = 30_000_000 - free_space
    IO.puts("Space to free up: #{space_to_free_up}")
    {_, smallest_to_delete} =
      folders_with_sizes
      |> Enum.sort_by(fn {_, size} -> size end)
      |> Enum.find(fn {_, size} -> size >= space_to_free_up end)
    smallest_to_delete
  end
end
