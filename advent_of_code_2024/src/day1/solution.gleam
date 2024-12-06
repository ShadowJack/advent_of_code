import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let input_result = read_input()
  io.println("Part 1")
  let _ =
    result.map(input_result, fn(input) { find_distance(input.0, input.1) })
    |> io.debug()

  io.println("Part 2")
  let _ =
    result.map(input_result, fn(input) { find_similarity(input.0, input.1) })
    |> io.debug()
}

fn read_input() {
  simplifile.read("./src/day1/input.txt")
  |> result.map(fn(content) { string.split(content, "\n") })
  |> result.map(fn(lines) {
    list.map(lines, fn(line) {
      line
      |> string.split("   ")
      |> list.map(int.parse)
      |> list.filter(result.is_ok)
    })
  })
  |> result.map(fn(lines) {
    list.fold(lines, #([], []), fn(acc, line) {
      case line {
        [Ok(a), Ok(b)] -> #([a, ..acc.0], [b, ..acc.1])
        _ -> acc
      }
    })
  })
}

fn find_distance(first: List(Int), second: List(Int)) {
  let sorted_first = list.sort(first, int.compare)
  let sorted_second = list.sort(second, int.compare)

  list.zip(sorted_first, sorted_second)
  |> list.fold(0, fn(acc, pair) { acc + int.absolute_value(pair.0 - pair.1) })
}

fn find_similarity(first: List(Int), second: List(Int)) {
  let second_freq_dictionary =
    list.fold(second, dict.new(), fn(acc, value) {
      dict.upsert(acc, value, fn(count) {
        case count {
          None -> 1
          Some(num) -> num + 1
        }
      })
    })

  list.fold(first, 0, fn(acc, value) {
    case dict.get(second_freq_dictionary, value) {
      Error(Nil) -> acc
      Ok(count) -> acc + value * count
    }
  })
}
