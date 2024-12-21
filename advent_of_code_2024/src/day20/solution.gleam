import gleam/dict
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
import gleamy/priority_queue
import glearray
import simplifile

const day = "20"

const is_test = False

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
  io.println("Part 2")
  let _ = part2(input) |> io.debug()
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
  // build a cache of distances from any point to the end
  let distances = build_distances(field, end)
  // starting from the start check each cheat and find how profitable it is
  find_best_cheats(field, start, distances, 100, get_cheats)
}

fn part2(input) {
  let #(field, start, end) = input
  // build a cache of distances from any point to the end
  let distances = build_distances(field, end)
  // starting from the start check each cheat and find how profitable it is
  find_best_cheats(field, start, distances, 100, get_cheats2)
}

fn build_distances(field, end) {
  // start from the end and go to each cell
  do_build_distances(field, [#(end, 0)], dict.from_list([#(end, 0)]))
}

fn do_build_distances(field, queue, results) {
  case queue {
    [] -> results
    [#(curr, dist), ..rest] -> {
      let neibs = get_neighbors(field, curr, dist, results)
      let upd_results =
        list.fold(neibs, results, fn(res, neib) {
          dict.insert(res, neib.0, neib.1)
        })

      do_build_distances(field, list.append(rest, neibs), upd_results)
    }
  }
}

/// Returns a list of neighbors that are not walls
// and are not in the closed set

fn get_neighbors(field, current, curr_dist, visited) {
  let Coords(x, y) = current
  [Coords(x - 1, y), Coords(x + 1, y), Coords(x, y - 1), Coords(x, y + 1)]
  |> list.filter(fn(neighbor) {
    case
      glearray.get(field, neighbor.y) |> result.try(glearray.get(_, neighbor.x))
    {
      Ok(Wall) -> False
      Error(_) -> False
      Ok(_) -> !dict.has_key(visited, neighbor)
    }
  })
  |> list.map(fn(neib) { #(neib, curr_dist + 1) })
}

fn find_best_cheats(field, curr, distances, limit, get_cheats_fn) {
  do_find_best_cheats(field, curr, distances, limit, None, get_cheats_fn, 0)
}

fn do_find_best_cheats(
  field,
  curr,
  distances,
  limit,
  prev,
  get_cheats_fn: fn(glearray.Array(glearray.Array(Cell)), Coords) ->
    List(#(Coords, Int)),
  counter,
) {
  let curr_dist = dict.get(distances, curr) |> result.unwrap(0)
  case curr_dist <= limit {
    False -> {
      // get possible cheats at the current cell and check if they are good enough
      let cheats =
        get_cheats_fn(field, curr)
        |> list.filter(fn(cheat) {
          let cheat_dist = dict.get(distances, cheat.0) |> result.unwrap(0)
          curr_dist - cheat_dist - cheat.1 >= limit
        })
      // go to the next
      let visited = case prev {
        Some(prev) -> dict.from_list([#(prev, 0)])
        None -> dict.new()
      }
      let next =
        get_neighbors(field, curr, 0, visited)
        |> list.map(fn(n) { n.0 })
        |> list.first()
        |> result.unwrap(curr)
      do_find_best_cheats(
        field,
        next,
        distances,
        limit,
        Some(curr),
        get_cheats_fn,
        counter + list.length(cheats),
      )
    }
    True -> counter
  }
}

fn get_cheats(field, curr) {
  // find all nearby walls then for each wall find a non-wall neighbor
  // return the end cell that is reachable from the wall
  let Coords(x, y) = curr
  [Coords(x - 1, y), Coords(x + 1, y), Coords(x, y - 1), Coords(x, y + 1)]
  |> list.filter(fn(n) {
    case glearray.get(field, n.y) |> result.try(glearray.get(_, n.x)) {
      Ok(Wall) -> True
      _ -> False
    }
  })
  |> list.flat_map(fn(wall) {
    let Coords(wx, wy) = wall
    [
      Coords(wx - 1, wy),
      Coords(wx + 1, wy),
      Coords(wx, wy - 1),
      Coords(wx, wy + 1),
    ]
    |> list.filter(fn(n) {
      case glearray.get(field, n.y) |> result.try(glearray.get(_, n.x)) {
        Ok(Empty) -> True
        _ -> False
      }
    })
    |> list.map(fn(n) { #(n, 2) })
  })
}

fn get_cheats2(field, curr: Coords) {
  // find all empty cells in the 20 steps radius around the current
  list.range(-20, 20)
  |> list.flat_map(fn(dy) {
    let x_diff = 20 - int.absolute_value(dy)
    list.range(-x_diff, x_diff)
    |> list.filter_map(fn(dx) {
      let coords = Coords(curr.x + dx, curr.y + dy)
      case
        glearray.get(field, coords.y) |> result.try(glearray.get(_, coords.x))
      {
        Ok(Empty) ->
          Ok(#(coords, int.absolute_value(dx) + int.absolute_value(dy)))
        _ -> Error(Nil)
      }
    })
  })
}
