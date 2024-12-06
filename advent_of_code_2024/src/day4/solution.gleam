import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glearray
import simplifile

const day = "4"

type Direction {
  Up
  UpRight
  Right
  DownRight
  Down
  DownLeft
  Left
  UpLeft
}

pub fn main() {
  let input = read_input()
  io.println("Part 1")
  let _ = part1(input) |> io.debug()
  let _ = part2(input) |> io.debug()
}

fn read_input() {
  simplifile.read("./src/day" <> day <> "/input.txt")
  |> result.unwrap("")
  //|> string.trim()
  |> string.split("\n")
  |> list.map(fn(line) { line |> string.split("") |> glearray.from_list() })
  |> glearray.from_list()
}

fn part1(input) {
  let lines_count = glearray.length(input)
  let line_width =
    glearray.length(glearray.get(input, 0) |> result.unwrap(glearray.new()))
  let all_chars_count = lines_count * line_width
  list.range(0, all_chars_count - 1)
  |> list.fold(0, fn(acc, idx) {
    let x = idx % line_width
    let y = idx / line_width
    let char = get_char_at(input, x, y)

    case char {
      Ok("X") ->
        acc
        + {
          [Up, UpRight, Right, DownRight, Down, DownLeft, Left, UpLeft]
          |> list.count(fn(dir) { is_xmas(input, x, y, dir) })
        }
      _ -> acc
    }
  })
}

fn get_char_at(input, x, y) {
  glearray.get(input, y)
  |> result.try(fn(line) { glearray.get(line, x) })
}

fn is_xmas(input, curr_x, curr_y, direction) {
  let curr_char = get_char_at(input, curr_x, curr_y) |> result.unwrap("")
  let expected_char = get_next_expected_char(curr_char)
  case expected_char {
    "" -> True
    _ -> {
      let #(next_x, next_y) = case direction {
        Up -> #(curr_x, curr_y - 1)
        UpRight -> #(curr_x + 1, curr_y - 1)
        Right -> #(curr_x + 1, curr_y)
        DownRight -> #(curr_x + 1, curr_y + 1)
        Down -> #(curr_x, curr_y + 1)
        DownLeft -> #(curr_x - 1, curr_y + 1)
        Left -> #(curr_x - 1, curr_y)
        UpLeft -> #(curr_x - 1, curr_y - 1)
      }

      case get_char_at(input, next_x, next_y) {
        Ok(char) if char == expected_char ->
          is_xmas(input, next_x, next_y, direction)
        _ -> False
      }
    }
  }
}

fn get_next_expected_char(curr_char) {
  case curr_char {
    "X" -> "M"
    "M" -> "A"
    "A" -> "S"
    _ -> ""
  }
}

// Part 2

fn part2(input) {
  let lines_count = glearray.length(input)
  let line_width =
    glearray.length(glearray.get(input, 0) |> result.unwrap(glearray.new()))
  let all_chars_count = lines_count * line_width
  list.range(0, all_chars_count - 1)
  |> list.count(fn(idx) {
    let x = idx % line_width
    let y = idx / line_width

    is_x_mas(input, x, y)
  })
}

fn is_x_mas(input, curr_x, curr_y) {
  case get_char_at(input, curr_x, curr_y) {
    Ok("A") -> {
      [UpRight, DownRight, DownLeft, UpLeft]
      |> list.count(is_mas(input, curr_x, curr_y, _))
      == 2
    }
    _ -> False
  }
}

fn is_mas(input, curr_x, curr_y, direction) {
  let #(prev_x, prev_y, next_x, next_y) = case direction {
    UpRight -> #(curr_x - 1, curr_y + 1, curr_x + 1, curr_y - 1)
    DownRight -> #(curr_x - 1, curr_y - 1, curr_x + 1, curr_y + 1)
    DownLeft -> #(curr_x + 1, curr_y - 1, curr_x - 1, curr_y + 1)
    UpLeft -> #(curr_x + 1, curr_y + 1, curr_x - 1, curr_y - 1)
    _ -> #(0, 0, 0, 0)
  }

  case get_char_at(input, prev_x, prev_y), get_char_at(input, next_x, next_y) {
    Ok("M"), Ok("S") -> True
    _, _ -> False
  }
}
