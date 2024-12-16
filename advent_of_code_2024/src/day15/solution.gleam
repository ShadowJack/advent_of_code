import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import glearray
import simplifile

const day = "15"

const is_test = False

type Map =
  glearray.Array(glearray.Array(Cell))

pub type Coords {
  Coords(x: Int, y: Int)
}

pub type CoordRange {
  CoordRange(x1: Int, x2: Int, y: Int)
}

pub type Cell {
  Crate
  CrateStart
  CrateEnd
  Empty
  Wall
}

pub type Move {
  Up
  Right
  Down
  Left
}

pub fn main() {
  let input = read_input()
  io.println("Part 1")
  let _ = part1(input) |> io.debug()
  io.println("Part 2")
  let _ = part2(input) |> io.debug()
}

fn read_input() {
  let assert [map_str, moves_str] =
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
    |> string.split("\n\n")

  let map = parse_map(map_str)
  let moves = parse_moves(moves_str)
  let width =
    map |> glearray.get(0) |> result.unwrap(glearray.new()) |> glearray.length()
  let start = find_start(map_str, width)
  #(map, moves, start)
}

fn parse_map(map_str) {
  map_str
  |> string.split("\n")
  |> list.filter(fn(row) { row != "" })
  |> list.map(fn(row) {
    row
    |> string.split("")
    |> list.map(fn(cell) {
      case cell {
        "." -> Empty
        "#" -> Wall
        "O" -> Crate
        _ -> Empty
      }
    })
    |> glearray.from_list()
  })
  |> glearray.from_list()
}

fn parse_moves(moves_str: String) {
  moves_str
  |> string.replace("\n", "")
  |> string.split("")
  |> list.filter(fn(x) { x == "^" || x == ">" || x == "v" || x == "<" })
  |> list.map(fn(char) {
    case char {
      "^" -> Up
      ">" -> Right
      "v" -> Down
      "<" -> Left
      _ -> Up
    }
  })
}

fn find_start(map_str, width) {
  let idx =
    map_str
    |> string.replace("\n", "")
    |> string.to_graphemes()
    |> list.index_map(fn(x, idx) { #(x, idx) })
    |> list.key_find("@")
    |> result.unwrap(0)
  let x = idx % width
  let y = idx / width
  Coords(x, y)
}

fn part1(input) {
  let #(map, moves, start) = input
  simulate(map, moves, start)
  |> sum_gps()
}

fn simulate(map: Map, moves: List(Move), start: Coords) -> Map {
  // for each move do it if possible
  //io.println("Initial state:")
  //print_map(map, start)
  let #(result, _) =
    list.fold(moves, #(map, start), fn(state, move) {
      let #(new_map, new_pos) = make_move(state.0, state.1, move)
      //io.println("")
      //io.println("Move " <> string.inspect(move) <> ":")
      //print_map(new_map, new_pos)
      #(new_map, new_pos)
    })
  result
}

fn make_move(map: Map, pos: Coords, move: Move) -> #(Map, Coords) {
  // find the first empty cell in the direction of movement
  // stop if we hit a wall
  let #(dx, dy) = case move {
    Up -> #(0, -1)
    Right -> #(1, 0)
    Down -> #(0, 1)
    Left -> #(-1, 0)
  }
  case find_free_cell(map, Coords(pos.x + dx, pos.y + dy), #(dx, dy)) {
    Ok(free_cell) -> #(
      update_map(map, pos, free_cell, #(dx, dy)),
      Coords(pos.x + dx, pos.y + dy),
    )
    Error(_) -> #(map, pos)
  }
}

fn find_free_cell(
  map: Map,
  pos: Coords,
  dir: #(Int, Int),
) -> Result(Coords, Nil) {
  case get_cell(map, pos) |> result.unwrap(Wall) {
    Empty -> Ok(pos)
    Wall -> Error(Nil)
    Crate -> find_free_cell(map, Coords(pos.x + dir.0, pos.y + dir.1), dir)
    _ -> Error(Nil)
  }
}

fn update_map(map: Map, pos: Coords, free_cell: Coords, dir: #(Int, Int)) -> Map {
  // move everything from pos to free_cell
  case Coords(pos.x + dir.0, pos.y + dir.1), free_cell {
    next_pos, free_cell if next_pos == free_cell -> map
    next_pos, free_cell ->
      map |> map_set(next_pos, Empty) |> map_set(free_cell, Crate)
  }
}

fn get_cell(map: Map, pos: Coords) {
  glearray.get(map, pos.y) |> result.try(glearray.get(_, pos.x))
}

fn map_set(map: Map, pos: Coords, cell: Cell) {
  let row =
    glearray.get(map, pos.y)
    |> result.unwrap(glearray.new())
    |> glearray.copy_set(pos.x, cell)
    |> result.unwrap(glearray.new())
  glearray.copy_set(map, pos.y, row) |> result.unwrap(map)
}

fn map_get_row(map: Map, y: Int) {
  glearray.get(map, y)
  |> result.unwrap(glearray.new())
}

fn sum_gps(map: Map) {
  let width =
    glearray.get(map, 0) |> result.unwrap(glearray.new()) |> glearray.length()
  let height = glearray.length(map)
  iterator.range(0, width * height - 1)
  |> iterator.fold(0, fn(acc, idx) {
    let x = idx % width
    let y = idx / width
    case glearray.get(map, y) |> result.try(glearray.get(_, x)) {
      Ok(Crate) -> acc + 100 * y + x
      _ -> acc
    }
  })
}

fn print_map(map: Map, pos: Coords) {
  glearray.iterate(map)
  |> iterator.index()
  |> iterator.each(fn(row_with_index) {
    let #(row, y) = row_with_index
    row
    |> glearray.iterate()
    |> iterator.index()
    |> iterator.map(fn(cell_with_index) {
      let #(cell, x) = cell_with_index
      case cell, Coords(x, y) {
        _, p if p == pos -> "@"
        Empty, _ -> "."
        Wall, _ -> "#"
        Crate, _ -> "O"
        CrateStart, _ -> "["
        CrateEnd, _ -> "]"
      }
    })
    |> iterator.to_list()
    |> string.join("")
    |> io.println()
  })
  map
}

/// Part 2
//

fn part2(input: #(Map, List(Move), Coords)) {
  let #(map, moves, start) = input
  let start = Coords(start.x * 2, start.y)
  let map = extend_map(map)
  simulate2(map, moves, start)
  |> sum_gps3()
}

fn extend_map(map: Map) -> Map {
  glearray.iterate(map)
  |> iterator.map(fn(row) {
    row
    |> glearray.iterate()
    |> iterator.map(fn(cell) {
      case cell {
        Crate -> [CrateStart, CrateEnd]
        Empty -> [Empty, Empty]
        Wall -> [Wall, Wall]
        _ -> [Empty, Empty]
      }
    })
    |> iterator.to_list()
    |> list.flatten()
    |> glearray.from_list()
  })
  |> iterator.to_list()
  |> glearray.from_list()
}

fn simulate2(map: Map, moves: List(Move), start: Coords) -> Map {
  // for each move do it if possible
  io.println("Initial state:")
  print_map(map, start)
  let #(result, final_pos) =
    list.fold(moves, #(map, start), fn(state, move) {
      let #(new_map, new_pos) = make_move2(state.0, state.1, move)
      //io.println("")
      //io.println("Move " <> string.inspect(move) <> ":")
      //print_map(new_map, new_pos)
      #(new_map, new_pos)
    })
  print_map(result, final_pos)
  result
}

fn has_broken_wall(map: Map) {
  glearray.iterate(map)
  |> iterator.any(fn(row) {
    row
    |> glearray.iterate()
    |> iterator.index()
    |> iterator.any(fn(cell_with_index) {
      let #(cell, x) = cell_with_index
      case cell {
        Wall -> {
          glearray.get(row, x - 1) != Ok(Wall)
          && glearray.get(row, x + 1) != Ok(Wall)
        }
        _ -> False
      }
    })
  })
}

fn make_move2(map: Map, pos: Coords, move: Move) -> #(Map, Coords) {
  // find the first empty cell in the direction of movement
  // stop if we hit a wall
  let #(dx, dy) = case move {
    Up -> #(0, -1)
    Right -> #(1, 0)
    Down -> #(0, 1)
    Left -> #(-1, 0)
  }
  let next_front = case dx {
    0 -> [CoordRange(pos.x, pos.x, pos.y + dy)]
    _ -> [CoordRange(pos.x + dx, pos.x + dx, pos.y)]
  }
  case find_free_cell2(map, [next_front], #(dx, dy)) {
    Ok(free_ranges) -> #(
      update_map2(map, pos, free_ranges, #(dx, dy)),
      Coords(pos.x + dx, pos.y + dy),
    )
    Error(_) -> #(map, pos)
  }
}

fn find_free_cell2(
  map: Map,
  fronts: List(List(CoordRange)),
  dir: #(Int, Int),
) -> Result(List(List(CoordRange)), Nil) {
  let assert [front, ..] = fronts
  // Check each range in the front
  let found_obstacles =
    list.fold(front, #(False, []), fn(acc, rng) {
      // TODO: for each cell in rng find walls and crates
      let has_walls =
        iterator.range(rng.x1, rng.x2)
        |> iterator.any(fn(x) {
          let coord = Coords(x, rng.y)
          case get_cell(map, coord) |> result.unwrap(Wall) {
            Wall -> True
            _ -> False
          }
        })

      let crates =
        iterator.range(rng.x1, rng.x2)
        |> iterator.fold(set.new(), fn(crates, x) {
          let coord = Coords(x, rng.y)
          case get_cell(map, coord) |> result.unwrap(Wall) {
            CrateStart -> set.insert(crates, CoordRange(x, x + 1, rng.y))
            CrateEnd -> set.insert(crates, CoordRange(x - 1, x, rng.y))
            _ -> crates
          }
        })

      #(acc.0 || has_walls, list.append(acc.1, set.to_list(crates)))
    })

  case found_obstacles {
    #(False, []) -> Ok(fronts)
    #(True, _) -> Error(Nil)
    #(False, crates) -> {
      let next_front = case dir.0 {
        0 ->
          list.map(crates |> set.from_list() |> set.to_list(), fn(c) {
            CoordRange(c.x1, c.x2, c.y + dir.1)
          })
        _ -> {
          let curr = front |> list.first() |> result.unwrap(CoordRange(0, 0, 0))
          [CoordRange(curr.x1 + dir.0, curr.x2 + dir.0, curr.y)]
        }
      }
      find_free_cell2(map, [next_front, ..fronts], dir)
    }
  }
}

fn update_map2(
  map: Map,
  pos: Coords,
  free_ranges: List(List(CoordRange)),
  dir: #(Int, Int),
) -> Map {
  // move everything from pos to free_cell
  case dir.0 {
    0 -> {
      // move vertically using the front logic one row at a time starting
      // from free range
      // going up to(or down to) the pos
      // start from free range - upadte the row with data below/above it
      // go to the next row while updating the range that must be copied
      update_map2_vertically(map, free_ranges, dir)
    }
    _ -> {
      // move horizontally everything between pos and free_range
      let assert [[free_range], ..] = free_ranges
      let row = map_get_row(map, pos.y) |> glearray.to_list()
      let upd_row = case dir.0 > 0 {
        True -> {
          // Move right
          row
          |> list_insert_before(pos.x + 1, Empty)
          |> list_delete(free_range.x1 + 1)
        }
        False -> {
          // Move left
          row
          |> list_insert_before(pos.x, Empty)
          |> list_delete(free_range.x1)
        }
      }
      glearray.copy_set(map, pos.y, glearray.from_list(upd_row))
      |> result.unwrap(map)
    }
  }
}

fn update_map2_vertically(
  map: Map,
  free_ranges: List(List(CoordRange)),
  dir: #(Int, Int),
) {
  case free_ranges {
    // we're done
    [] -> map
    [free_range, ..rest] -> {
      let upd_map =
        list.fold(free_range, map, fn(map, free_range) {
          // copy next row to the free_range
          let free_y = free_range.y
          let next_y = free_y - dir.1
          let free_row = map_get_row(map, free_y) |> glearray.to_list()
          let next_row = map_get_row(map, next_y) |> glearray.to_list()
          let upd_free_row =
            list_replace_range(
              free_row,
              #(free_range.x1, free_range.x2),
              list_subrange(next_row, #(free_range.x1, free_range.x2)),
            )
          let upd_next_row =
            list_replace_range(
              next_row,
              #(free_range.x1, free_range.x2),
              list.repeat(Empty, free_range.x2 - free_range.x1 + 1),
            )
          map
          |> glearray.copy_set(free_y, glearray.from_list(upd_free_row))
          |> result.unwrap(map)
          |> glearray.copy_set(next_y, glearray.from_list(upd_next_row))
          |> result.unwrap(map)
        })
      update_map2_vertically(upd_map, rest, dir)
    }
  }
}

fn sum_gps2(map: Map) {
  // for each crate find the closest edge vertically and horizontally
  let width =
    glearray.get(map, 0) |> result.unwrap(glearray.new()) |> glearray.length()
  let height = glearray.length(map)
  iterator.range(0, width * height - 1)
  |> iterator.fold(0, fn(acc, idx) {
    let x = idx % width
    let y = idx / width
    case glearray.get(map, y) |> result.try(glearray.get(_, x)) {
      Ok(CrateStart) -> {
        // find the closest edge
        let y_diff = int.min(y, height - y - 1)
        let x_diff = int.min(x, width - x - 2)
        acc + y_diff * 100 + x_diff
      }
      _ -> acc
    }
  })
}

fn sum_gps3(map: Map) {
  let width =
    glearray.get(map, 0) |> result.unwrap(glearray.new()) |> glearray.length()
  let height = glearray.length(map)
  iterator.range(0, width * height - 1)
  |> iterator.fold(0, fn(acc, idx) {
    let x = idx % width
    let y = idx / width
    case glearray.get(map, y) |> result.try(glearray.get(_, x)) {
      Ok(CrateStart) -> acc + 100 * y + x
      _ -> acc
    }
  })
}

/// List helpers
//

fn list_insert_before(l: List(a), idx: Int, value: a) -> List(a) {
  l
  |> list.take(idx)
  |> list.append([value])
  |> list.append(list.drop(l, idx))
}

fn list_delete(l: List(a), idx: Int) -> List(a) {
  l
  |> list.take(idx)
  |> list.append(list.drop(l, idx + 1))
}

// the range is inclusive
fn list_replace_range(
  l: List(a),
  range: #(Int, Int),
  values: List(a),
) -> List(a) {
  l
  |> list.take(range.0)
  |> list.append(values)
  |> list.append(list.drop(l, range.1 + 1))
}

// the range is inclusive
fn list_subrange(l: List(a), range: #(Int, Int)) -> List(a) {
  l |> list.drop(range.0) |> list.take(range.1 - range.0 + 1)
}
