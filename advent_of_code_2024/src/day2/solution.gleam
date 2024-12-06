import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

const day = "2"

pub fn main() {
  let input_result = read_input()
  io.println("Part 1")
  let _ =
    result.map(input_result, fn(reports) { count_safe_reports(reports) })
    |> io.debug()

  io.println("Part 2")
  let _ =
    result.map(input_result, fn(reports) { count_safe_reports2(reports) })
    |> io.debug()
}

fn read_input() {
  simplifile.read("./src/day" <> day <> "/input.txt")
  |> result.map(fn(content) { content |> string.trim() |> string.split("\n") })
  |> result.map(fn(lines) {
    list.map(lines, fn(line) {
      line
      |> string.split(" ")
      |> list.map(fn(x) { int.parse(x) |> result.unwrap(0) })
    })
  })
}

fn count_safe_reports(reports: List(List(Int))) {
  list.count(reports, is_safe)
}

fn is_safe(report: List(Int)) -> Bool {
  case report {
    [first, second, ..] if first > second -> is_safe_ordered(report, asc: False)
    [_first, _second, ..] -> is_safe_ordered(report, asc: True)
    _ -> True
  }
}

fn is_safe_ordered(report: List(Int), asc is_asc: Bool) -> Bool {
  case is_asc, report {
    _, [] -> True
    _, [_] -> True
    True, [first, second, ..rest] if first < second && second - first <= 3 ->
      is_safe_ordered([second, ..rest], is_asc)
    False, [first, second, ..rest] if first > second && first - second <= 3 ->
      is_safe_ordered([second, ..rest], is_asc)
    _, _ -> False
  }
}

fn count_safe_reports2(reports: List(List(Int))) {
  list.count(reports, is_safe2)
}

fn is_safe2(report: List(Int)) -> Bool {
  case report {
    [_, ..] ->
      is_safe_ordered2(report, had_error: False, prev: None)
      || is_safe_ordered2(list.reverse(report), had_error: False, prev: None)
      || is_safe_ordered2(list.drop(report, 1), had_error: True, prev: None)
      || is_safe_ordered2(
        list.reverse(report) |> list.drop(1),
        had_error: True,
        prev: None,
      )
    _ -> True
  }
}

fn is_safe_ordered2(
  report: List(Int),
  had_error had_error: Bool,
  prev prev: Option(Int),
) -> Bool {
  case report, had_error {
    [], _ -> True
    [_], _ -> True
    [first, second, ..rest], _ if first < second && second - first <= 3 ->
      is_safe_ordered2([second, ..rest], had_error, Some(first))
    [first, second, ..rest], False ->
      // skip this error once if possible
      is_safe_ordered2([first, ..rest], had_error: True, prev: None)
      || is_safe_ordered2(
        remove_first(prev, second, rest),
        had_error: True,
        prev: None,
      )
    _, _ -> False
  }
}

fn remove_first(prev, second, rest) {
  case prev {
    Some(p) -> [p, second, ..rest]
    None -> [second, ..rest]
  }
}
