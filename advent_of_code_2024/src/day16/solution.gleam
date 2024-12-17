import gleam/dict
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import gleamy/priority_queue
import glearray
import simplifile

const day = "16"

const is_test = True

const max_int = 99_999_999_999_999_999

pub type Cell {
  Empty
  Wall
}

pub type Coords {
  Coords(x: Int, y: Int)
}

pub type Direction {
  Up
  Right
  Down
  Left
}

pub fn main() {
  let input = read_input()
  io.println("Part 1")
  let _ = part1(input) |> io.debug()
}

fn read_input() {
  let field_str =
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

  let field =
    field_str
    |> string.split("\n")
    |> list.filter(fn(s) { s != "" })
    |> list.map(fn(line) {
      line
      |> string.split("")
      |> list.map(fn(c) {
        case c {
          "#" -> Wall
          _ -> Empty
        }
      })
      |> glearray.from_list()
    })
    |> glearray.from_list()

  let width =
    field
    |> glearray.get(0)
    |> result.unwrap(glearray.new())
    |> glearray.length()
  let start = find_start(field_str, width)
  let end = find_end(field_str, width)
  #(field, start, end)
}

fn find_start(field, width) {
  find_char(field, width, "S")
}

fn find_end(field, width) {
  find_char(field, width, "E")
}

fn find_char(field, width, char) {
  let idx =
    field
    |> string.replace("\n", "")
    |> string.to_graphemes()
    |> list.index_map(fn(x, idx) { #(x, idx) })
    |> list.key_find(char)
    |> result.unwrap(0)
  let x = idx % width
  let y = idx / width
  Coords(x, y)
}

fn part1(input) {
  let #(field, start, end) = input
  case a_star(field, start, end, Right) {
    Ok(#(score, visited)) -> {
      print_visited(field, visited)
      score
    }
    Error(_) -> 0
  }
}

fn a_star(field, start, end, direction) {
  let g_score = dict.new() |> dict.insert(start, 0)
  let f_score =
    dict.new() |> dict.insert(start, heuristic_cost_estimate(start, end))
  let closed_set = set.new()
  let open_set =
    priority_queue.from_list([#(start, direction)], build_comparator(f_score))

  do_a_star(field, end, open_set, closed_set, g_score, f_score)
}

fn do_a_star(field, end, open_set, closed_set, g_score, f_score) {
  let reordered = priority_queue.reorder(open_set, build_comparator(f_score))
  case priority_queue.pop(reordered) {
    Error(_) -> Error(Nil)
    Ok(#(#(current, _dir), _open_set)) if current == end -> {
      dict.get(g_score, current)
      |> result.map(fn(score) { #(score, closed_set) })
    }
    Ok(#(#(current, dir), open_set)) -> {
      let closed_set = set.insert(closed_set, current)

      let #(upd_open_set, upd_g_score, upd_f_score) =
        get_neighbors(field, current, closed_set)
        |> list.fold(#(open_set, g_score, f_score), fn(state, neighbor) {
          let #(open_set, g_score, f_score) = state
          let tentative_g_score =
            { dict.get(g_score, current) |> result.unwrap(max_int) }
            + calc_cost(current, neighbor, dir)
          let neib_is_in_open_set =
            priority_queue.to_list(open_set)
            |> list.any(fn(x) { x.0 == neighbor })
          case neib_is_in_open_set {
            False -> {
              let upd_open_set =
                priority_queue.push(open_set, #(
                  neighbor,
                  dir_to_neib(current, neighbor),
                ))
              let upd_g_score =
                dict.insert(g_score, neighbor, tentative_g_score)
              let upd_f_score =
                dict.insert(
                  f_score,
                  neighbor,
                  tentative_g_score + heuristic_cost_estimate(neighbor, end),
                )
              #(upd_open_set, upd_g_score, upd_f_score)
            }
            True -> {
              case
                tentative_g_score
                >= { dict.get(g_score, neighbor) |> result.unwrap(max_int) }
              {
                True -> {
                  state
                }
                False -> {
                  let upd_g_score =
                    dict.insert(g_score, neighbor, tentative_g_score)
                  let upd_f_score =
                    dict.insert(
                      f_score,
                      neighbor,
                      tentative_g_score + heuristic_cost_estimate(neighbor, end),
                    )
                  #(open_set, upd_g_score, upd_f_score)
                }
              }
            }
          }
        })

      do_a_star(field, end, upd_open_set, closed_set, upd_g_score, upd_f_score)
    }
  }
}

fn build_comparator(f_score: dict.Dict(Coords, Int)) {
  fn(a: #(Coords, Direction), b: #(Coords, Direction)) {
    let a_f_score = dict.get(f_score, a.0) |> result.unwrap(max_int)
    let b_f_score = dict.get(f_score, b.0) |> result.unwrap(max_int)
    int.compare(a_f_score, b_f_score)
  }
}

fn heuristic_cost_estimate(start, end) {
  let Coords(x1, y1) = start
  let Coords(x2, y2) = end
  int.absolute_value(x1 - x2) + int.absolute_value(y1 - y2)
}

/// Returns a list of neighbors that are not walls
// and are not in the closed set

fn get_neighbors(field, current, closed_set) {
  let Coords(x, y) = current
  [Coords(x - 1, y), Coords(x + 1, y), Coords(x, y - 1), Coords(x, y + 1)]
  |> list.filter(fn(neighbor) {
    case
      glearray.get(field, neighbor.y) |> result.try(glearray.get(_, neighbor.x))
    {
      Ok(Wall) -> False
      Error(_) -> False
      Ok(_) -> !set.contains(closed_set, neighbor)
    }
  })
}

fn dir_to_neib(current: Coords, neighbor: Coords) {
  case neighbor.x - current.x, neighbor.y - current.y {
    0, 1 -> Down
    0, -1 -> Up
    1, 0 -> Right
    -1, 0 -> Left
    _, _ -> Left
  }
}

fn calc_cost(current: Coords, neighbor: Coords, direction: Direction) {
  let dir_to_neib = dir_to_neib(current, neighbor)
  case dir_to_neib, direction {
    a, b if a == b -> 1
    Up, Down -> 2001
    Down, Up -> 2001
    Left, Right -> 2001
    Right, Left -> 2001
    _, _ -> 1001
  }
}

fn print_visited(field, visited) {
  glearray.iterate(field)
  |> iterator.index()
  |> iterator.each(fn(row_with_index) {
    let #(row, y) = row_with_index
    row
    |> glearray.iterate()
    |> iterator.index()
    |> iterator.map(fn(cell_with_index) {
      let #(cell, x) = cell_with_index
      case cell {
        Empty -> {
          case set.contains(visited, Coords(x, y)) {
            True -> "O"
            False -> "."
          }
        }
        Wall -> "#"
      }
    })
    |> iterator.to_list()
    |> string.join("")
    |> io.println()
  })
}
