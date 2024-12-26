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

const day = "21"

const is_test = False

pub type Dir {
  Up
  Down
  Left
  Right
  A
}

/// Numpad
// +---+---+---+
// | 7 | 8 | 9 |
// +---+---+---+
// | 4 | 5 | 6 |
// +---+---+---+
// | 1 | 2 | 3 |
// +---+---+---+
//     | 0 | A |
//     +---+---+
//
/// Directional pad
//      +---+---+
//      | ^ | A |
//  +---+---+---+
//  | < | v | > |
//  +---+---+---+

pub fn main() {
  let input = read_input()
  io.println("Part 1")
  let _ = part1(input) |> io.debug()
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
  |> list.map(fn(line) { string.split(line, "") })
}

fn part1(input: List(List(String))) {
  input
  |> list.fold(0, fn(acc, code) {
    io.println("Code: " <> string.inspect(code))
    let seq = find_sequence(code)
    //|> io.debug()
    let num_value =
      code
      |> list.filter(fn(ch) { ch != "A" })
      |> string.join("")
      |> int.parse()
      |> result.unwrap(0)
    acc + num_value * list.length(seq)
  })
}

fn find_sequence(code: List(String)) {
  do_find_num_sequence(code, "A", [])
}

fn do_find_num_sequence(queue: List(String), last_pos: String, acc) {
  case queue {
    [] -> acc |> list.reverse() |> list.flatten()
    [next_pos, ..rest] -> {
      let seq = find_dir_sequence(last_pos, next_pos)
      do_find_num_sequence(rest, next_pos, [seq, ..acc])
    }
  }
}

fn find_dir_sequence(last_pos, next_pos) {
  // Ex. 2 -> 9
  // find all options grouped by equal operations and sorted differently
  // make sure to filter out the ones that are not possible
  let #(x1, y1) = get_pos(last_pos)
  let #(x2, y2) = get_pos(next_pos)
  let dx = get_x_moves(x1, x2)
  let dy = get_y_moves(y1, y2)
  [list.flatten([dx, dy, [A]]), list.flatten([dy, dx, [A]])]
  |> list.unique()
  |> list.filter(fn(seq) {
    // check that the sequence doesn't go over the empty pad
    let #(is_valid, _) =
      list.fold(seq, #(True, #(x1, y1)), fn(acc, dir) {
        let new_pos = apply_move(acc.1, dir)
        case new_pos {
          #(0, 3) -> #(False, acc.1)
          n -> #(acc.0, n)
        }
      })
    is_valid
  })
  //|> io.debug()
  |> list.map(find_sequence_2nd(_, 24))
  |> list.sort(fn(a, b) { int.compare(list.length(a), list.length(b)) })
  |> list.first()
  |> result.unwrap([])
}

fn find_sequence_2nd(dir_seq, depth) {
  do_find_sequence_2nd(dir_seq, A, [], depth)
}

fn do_find_sequence_2nd(queue: List(Dir), last_pos: Dir, acc, depth) {
  case queue {
    [] -> acc |> list.reverse() |> list.flatten()
    [next_pos, ..rest] -> {
      let seq = find_dir_sequence_2nd(last_pos, next_pos, depth)
      do_find_sequence_2nd(rest, next_pos, [seq, ..acc], depth)
    }
  }
}

fn find_dir_sequence_2nd(last_pos, next_pos, depth) {
  // Ex. Up -> Left
  // find all options grouped by equal operations and sorted differently
  // make sure to filter out the ones that are not possible
  let #(x1, y1) = get_dir_pos(last_pos)
  let #(x2, y2) = get_dir_pos(next_pos)
  let dx = get_x_moves(x1, x2)
  let dy = get_y_moves(y1, y2)
  [list.flatten([dx, dy, [A]]), list.flatten([dy, dx, [A]])]
  |> list.unique()
  |> list.filter(fn(seq) {
    // check that the sequence doesn't go over the empty pad
    let #(is_valid, _) =
      list.fold(seq, #(True, #(x1, y1)), fn(acc, dir) {
        let new_pos = apply_move(acc.1, dir)
        case new_pos {
          #(0, 0) -> #(False, acc.1)
          n -> #(acc.0, n)
        }
      })
    is_valid
  })
  //|> io.debug()
  |> list.map(fn(candidate) {
    case depth {
      0 -> candidate
      _ -> find_sequence_2nd(candidate, depth - 1)
    }
  })
  |> list.sort(fn(a, b) { int.compare(list.length(a), list.length(b)) })
  |> list.first()
  |> result.unwrap([])
}

fn get_pos(pos) {
  case pos {
    "7" -> #(0, 0)
    "8" -> #(1, 0)
    "9" -> #(2, 0)
    "4" -> #(0, 1)
    "5" -> #(1, 1)
    "6" -> #(2, 1)
    "1" -> #(0, 2)
    "2" -> #(1, 2)
    "3" -> #(2, 2)
    "0" -> #(1, 3)
    "A" -> #(2, 3)
    _ -> #(0, 0)
  }
}

fn get_x_moves(x1, x2) {
  case x2 - x1 {
    0 -> []
    a if a > 0 -> list.repeat(Right, a)
    a -> list.repeat(Left, int.absolute_value(a))
  }
}

fn get_y_moves(y1, y2) {
  case y2 - y1 {
    0 -> []
    a if a > 0 -> list.repeat(Down, a)
    a -> list.repeat(Up, int.absolute_value(a))
  }
}

fn apply_move(pos, move) {
  let #(x, y) = pos
  case move {
    Right -> #(x + 1, y)
    Left -> #(x - 1, y)
    Down -> #(x, y + 1)
    Up -> #(x, y - 1)
    A -> pos
  }
}

fn get_dir_pos(dir) {
  case dir {
    Right -> #(2, 1)
    Left -> #(0, 1)
    Down -> #(1, 1)
    Up -> #(1, 0)
    A -> #(2, 0)
  }
}
