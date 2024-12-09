import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
import glearray
import simplifile

const day = "6"

type Cell {
  Obstacle
  Empty
  Guard
}

type Direction {
  Up
  Down
  Left
  Right
}

pub fn main() {
  let input = read_input()
  io.println("Part 1")
  let #(guard_pos, visited) = part1(input)
  let _ = visited |> set.size() |> io.debug()
  io.println("Part 2")
  let _ = part2(input, guard_pos, visited) |> io.debug()
}

fn read_input() {
  simplifile.read("./src/day" <> day <> "/input.txt")
  |> result.unwrap("")
  |> string.split("\n")
  |> list.map(fn(line) {
    line
    |> string.split("")
    |> list.map(fn(ch) {
      case ch {
        "#" -> Obstacle
        "^" -> Guard
        _ -> Empty
      }
    })
    |> glearray.from_list()
  })
  |> glearray.from_list()
}

fn part1(input) {
  let guard_pos = find_guard(input)
  let visited =
    count_visited_cells(input, guard_pos.0, guard_pos.1, Up, set.new())
  #(guard_pos, visited)
}

fn find_guard(input) {
  let lines_count = glearray.length(input)
  let line_width =
    glearray.length(glearray.get(input, 0) |> result.unwrap(glearray.new()))
  let guard_idx =
    list.find(list.range(0, lines_count * line_width - 1), fn(idx) {
      let x = idx % line_width
      let y = idx / line_width
      case get_cell(input, x, y) {
        Ok(Guard) -> True
        _ -> False
      }
    })
    |> result.unwrap(0)

  #(guard_idx % line_width, guard_idx / line_width)
}

fn count_visited_cells(input, x, y, dir, visited) {
  let new_visited = set.insert(visited, #(x, y))

  // get next cell - if it's out of range, return count of visited cells
  // othwerwise, check if it's an obstacle, if it is, turn right
  // if not - move forward and increment count if the cell wasn't visited before
  let #(next_x, next_y) = case dir {
    Up -> #(x, y - 1)
    Down -> #(x, y + 1)
    Left -> #(x - 1, y)
    Right -> #(x + 1, y)
  }
  case get_cell(input, next_x, next_y) {
    Error(_) -> new_visited
    // finish
    Ok(Obstacle) -> {
      // just turn right
      let next_dir = case dir {
        Up -> Right
        Right -> Down
        Down -> Left
        Left -> Up
      }
      count_visited_cells(input, x, y, next_dir, new_visited)
    }
    _ -> {
      // move forward
      count_visited_cells(input, next_x, next_y, dir, new_visited)
    }
  }
}

fn get_cell(input, x, y) {
  input
  |> glearray.get(y)
  |> result.unwrap(glearray.new())
  |> glearray.get(x)
}

fn part2(input, guard_pos, visited) {
  // for each visited cell except the guard cell,
  // check if putting an obstacle there would
  // make the guard to loop around
  set.drop(visited, [guard_pos])
  |> set.to_list()
  |> list.count(fn(pos: #(Int, Int)) {
    // update the map with the obstacle
    let updated_line =
      glearray.copy_set(
        glearray.get(input, pos.1) |> result.unwrap(glearray.new()),
        pos.0,
        Obstacle,
      )
      |> result.unwrap(glearray.new())
    let updated_input =
      glearray.copy_set(input, pos.1, updated_line)
      |> result.unwrap(glearray.new())

    // check if the guard is looping now
    is_looping(updated_input, guard_pos.0, guard_pos.1, Up, set.new())
  })
}

fn is_looping(input, x, y, dir, visited) {
  case set.contains(visited, #(x, y, dir)) {
    True -> True
    False -> {
      let new_visited = set.insert(visited, #(x, y, dir))

      // get next cell - if it's out of range, return false
      // othwerwise, check if it's an obstacle, if it is, turn right
      // if not - move forward
      let #(next_x, next_y) = case dir {
        Up -> #(x, y - 1)
        Down -> #(x, y + 1)
        Left -> #(x - 1, y)
        Right -> #(x + 1, y)
      }
      case get_cell(input, next_x, next_y) {
        // guard is out of the map
        Error(_) -> False
        Ok(Obstacle) -> {
          // just turn right
          let next_dir = case dir {
            Up -> Right
            Right -> Down
            Down -> Left
            Left -> Up
          }
          is_looping(input, x, y, next_dir, new_visited)
        }
        _ -> {
          // move forward
          is_looping(input, next_x, next_y, dir, new_visited)
        }
      }
    }
  }
}
