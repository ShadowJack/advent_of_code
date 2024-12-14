import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import glearray
import simplifile

const day = "10"

pub fn main() {
  let input = read_input()
  io.println("Part 1")
  let _ = part1(input) |> io.debug()
  io.println("Part 2")
  let _ = part2(input) |> io.debug()
}

fn read_input() {
  simplifile.read("./src/day" <> day <> "/input.txt")
  |> result.unwrap("")
  |> string.split("\n")
  |> list.filter(fn(x) { x != "" })
  |> list.map(fn(line) {
    line
    |> string.split("")
    |> list.filter_map(int.parse)
    |> glearray.from_list()
  })
  |> glearray.from_list()
}

fn part1(input) {
  // for each trailhead find all reachable trailends via BFS
  input
  |> find_trailheads()
  |> list.fold(0, fn(acc, h) { acc + calc_paths(input, h) })
}

fn find_trailheads(input) {
  let width =
    glearray.get(input, 0) |> result.map(glearray.length) |> result.unwrap(0)
  let height = glearray.length(input)

  list.fold(list.range(0, width * height - 1), set.new(), fn(acc, idx) {
    let x = idx % width
    let y = idx / width
    case glearray.get(input, y) |> result.try(glearray.get(_, x)) {
      Ok(0) -> set.insert(acc, #(x, y))
      _ -> acc
    }
  })
  |> set.to_list()
}

fn calc_paths(input, head: #(Int, Int)) {
  do_find_paths(input, [#(head.0, head.1, 0)], set.new()) |> set.size()
}

fn do_find_paths(input, queue, ends) {
  case queue {
    [next, ..rest] -> {
      let #(x, y, height) = next
      case height {
        9 -> do_find_paths(input, rest, set.insert(ends, #(x, y)))
        _ -> {
          let next_height = height + 1
          let neighbours =
            [
              #(x + 1, y, next_height),
              #(x - 1, y, next_height),
              #(x, y + 1, next_height),
              #(x, y - 1, next_height),
            ]
            |> list.filter(fn(neib) {
              let #(x, y, h) = neib
              case glearray.get(input, y) |> result.try(glearray.get(_, x)) {
                Ok(val) if val == h -> True
                // good move
                _ -> False
              }
            })
          do_find_paths(input, list.append(rest, neighbours), ends)
        }
      }
      //do_find_paths(input, queue, ends)
    }
    [] -> ends
  }
}

// Part 2
//

fn part2(input) {
  // for each trailhead find all reachable trailends via BFS
  input
  |> find_trailheads()
  |> list.fold(0, fn(acc, h) { acc + calc_rating(input, h) })
}

fn calc_rating(input, head: #(Int, Int)) {
  do_calc_rating(input, [#(head.0, head.1, 0)], 0)
}

fn do_calc_rating(input, queue, acc) {
  case queue {
    [next, ..rest] -> {
      let #(x, y, height) = next
      case height {
        9 -> do_calc_rating(input, rest, acc + 1)
        _ -> {
          let next_height = height + 1
          let neighbours =
            [
              #(x + 1, y, next_height),
              #(x - 1, y, next_height),
              #(x, y + 1, next_height),
              #(x, y - 1, next_height),
            ]
            |> list.filter(fn(neib) {
              let #(x, y, h) = neib
              case glearray.get(input, y) |> result.try(glearray.get(_, x)) {
                Ok(val) if val == h -> True
                // good move
                _ -> False
              }
            })
          do_calc_rating(input, list.append(rest, neighbours), acc)
        }
      }
    }
    [] -> acc
  }
}
