import gleam/dict
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import glearray
import simplifile

const day = "18"

const is_test = False

pub type Cell {
  Empty
  Wall
}

pub type Coords {
  Coords(x: Int, y: Int)
}

pub fn main() {
  let input = read_input()
  let #(dimension, steps) = case is_test {
    True -> #(7, 12)
    False -> #(71, 1024)
  }
  io.println("Part 1")
  let _ = part1(input, dimension, steps) |> io.debug()
  io.println("Part 2")
  let _ = part2(input, dimension) |> io.debug()
}

fn read_input() {
  simplifile.read(
    "./src/day"
    <> day
    <> {
      case is_test {
        True -> "/test_"
        False -> "/"
      }
    }
    <> "input.txt",
  )
  |> result.unwrap("")
  |> string.split("\n")
  |> list.filter(fn(x) { x != "" })
  |> list.map(fn(line) {
    let assert [x, y] =
      line
      |> string.split(",")
      |> list.map(int.parse)
      |> list.filter_map(fn(x) { x })

    Coords(x, y)
  })
}

fn part1(input, dimension, steps) {
  // 1. simulate first steps
  let map = simulate(input, dimension, steps)
  // 2. find the length of the shortest path to exit
  find_path_length(map, Coords(0, 0), Coords(dimension - 1, dimension - 1))
}

fn simulate(input, dimension, steps) {
  let empty_map = map_build(dimension)

  input
  |> list.take(steps)
  |> list.fold(empty_map, fn(map, step) { map_set(map, step, Wall) })
}

fn find_path_length(map, start, end) {
  do_find_path_length(map, [[start]], set.new(), end)
}

fn do_find_path_length(map, queue, visited, end) {
  // BFS
  case queue {
    [] -> Error(Nil)
    [[current, ..], ..] if current == end ->
      queue |> list.first() |> result.map(list.length)
    [path, ..rest] -> {
      let assert [current, ..] = path
      let Coords(x, y) = current
      let next =
        [Coords(x + 1, y), Coords(x - 1, y), Coords(x, y + 1), Coords(x, y - 1)]
        |> list.filter(fn(coords) { !set.contains(visited, coords) })
        |> list.filter(fn(coords) { map_get(map, coords) == Ok(Empty) })

      let upd_visited =
        next
        |> list.fold(visited, fn(visited, coords) {
          set.insert(visited, coords)
        })
      let next_path = next |> list.map(fn(coords) { [coords, ..path] })
      do_find_path_length(map, list.append(rest, next_path), upd_visited, end)
    }
  }
}

fn part2(input, dimension) {
  // 1. simulate steps, after each step check if the exit is reachable
  find_breaking_step(input, dimension)
}

fn find_breaking_step(input, dimension) {
  let empty_map = map_build(dimension)

  let #(_, last_step) =
    input
    |> list.fold_until(#(empty_map, 0), fn(state, coords) {
      let #(map, step) = state
      let new_map = map_set(map, coords, Wall)
      let path_length =
        find_path_length(
          new_map,
          Coords(0, 0),
          Coords(dimension - 1, dimension - 1),
        )
      case path_length {
        Ok(_) -> list.Continue(#(new_map, step + 1))
        Error(_) -> list.Stop(#(map, step))
      }
    })

  list.drop(input, last_step) |> list.first()
}

/// Map helpers
//

fn map_build(dimension) {
  iterator.repeat(Empty)
  |> iterator.take(dimension)
  |> iterator.map(fn(cell) {
    list.repeat(cell, dimension) |> glearray.from_list()
  })
  |> iterator.to_list()
  |> glearray.from_list()
}

fn map_get(map, coords) {
  let Coords(x, y) = coords
  glearray.get(map, y)
  |> result.try(glearray.get(_, x))
}

fn map_set(map, coords, cell) {
  let Coords(x, y) = coords
  let row = glearray.get(map, y) |> result.unwrap(glearray.new())
  let upd_row = glearray.copy_set(row, x, cell) |> result.unwrap(row)
  glearray.copy_set(map, y, upd_row) |> result.unwrap(map)
}

fn map_print(map) {
  glearray.iterate(map)
  |> iterator.each(fn(row) {
    row
    |> glearray.iterate()
    |> iterator.map(fn(cell) {
      case cell {
        Empty -> "."
        Wall -> "#"
      }
    })
    |> iterator.to_list()
    |> string.join("")
    |> io.println()
  })
  map
}
