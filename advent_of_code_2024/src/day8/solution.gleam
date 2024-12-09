import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
import glearray
import simplifile

const day = "8"

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
  |> list.map(fn(line) { line |> string.split("") |> glearray.from_list() })
  |> list.filter(fn(line) { glearray.length(line) > 0 })
  |> glearray.from_list()
}

fn part1(input) {
  // for each pair of antennas find their focus points
  let #(width, height) = get_dimensions(input)
  find_antennas(input)
  |> dict.fold(set.new(), fn(acc, _key, val) {
    get_pairs(val)
    |> list.fold(acc, fn(acc, pair) {
      case get_focal_point(pair, width, height) {
        Some(point) -> set.insert(acc, point)
        None -> acc
      }
    })
  })
  |> set.size()
}

fn find_antennas(input) {
  let #(line_width, lines) = get_dimensions(input)

  // find all antennas and group them by their frequency
  list.fold(list.range(0, lines * line_width - 1), dict.new(), fn(acc, idx) {
    let x = idx % line_width
    let y = idx / line_width
    case
      glearray.get(input, y) |> result.unwrap(glearray.new()) |> glearray.get(x)
    {
      Ok(".") -> acc
      Error(_) -> acc
      Ok(char) -> {
        dict.upsert(acc, char, fn(value) {
          case value {
            Some(l) -> [#(x, y), ..l]
            None -> [#(x, y)]
          }
        })
      }
    }
  })
}

fn get_dimensions(input) {
  let line_width =
    glearray.get(input, 0) |> result.unwrap(glearray.new()) |> glearray.length()
  let lines = glearray.length(input)
  #(line_width, lines)
}

fn get_pairs(points) {
  list.fold(points, list.new(), fn(acc, point) {
    list.fold(points, acc, fn(acc, point2) {
      case point == point2 {
        True -> acc
        False -> [#(point, point2), ..acc]
      }
    })
  })
}

fn get_focal_point(pair, width, height) {
  let #(p1, p2) = pair
  let #(x1, y1) = p1
  let #(x2, y2) = p2
  let dx = x2 - x1
  let dy = y2 - y1
  let x = x2 + dx
  let y = y2 + dy
  case x >= 0 && x < width && y >= 0 && y < height {
    True -> Some(#(x, y))
    False -> None
  }
}

fn part2(input) {
  let #(width, height) = get_dimensions(input)
  find_antennas(input)
  |> dict.fold(set.new(), fn(acc, _key, val) {
    get_pairs(val)
    |> list.fold(acc, fn(acc, pair) {
      get_focal_points(pair, width, height)
      |> list.fold(acc, fn(acc, point) { set.insert(acc, point) })
    })
  })
  |> set.size()
}

fn get_focal_points(pair, width, height) {
  // get the focal points of the pair of antennas
  let #(p1, p2) = pair
  let #(x1, y1) = p1
  let #(x2, y2) = p2
  let dx = x2 - x1
  let dy = y2 - y1
  get_points_on_line(x2, y2, dx, dy, width, height, [])
}

/// find all points in the line between the two antennas
/// until the end of the bounding rectangle
///
fn get_points_on_line(x, y, dx, dy, width, height, acc) {
  case x >= 0 && x < width && y >= 0 && y < height {
    False -> acc
    True ->
      get_points_on_line(x + dx, y + dy, dx, dy, width, height, [#(x, y), ..acc])
  }
}
