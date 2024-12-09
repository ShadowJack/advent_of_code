import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

const day = "7"

type Operator {
  Add
  Mul
  Concat
}

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
  |> string.trim()
  |> string.split("\n")
  |> list.map(fn(line) {
    case line |> string.split(":") {
      [a, b] -> {
        let test_val = a |> int.parse() |> result.unwrap(0)
        let operands =
          b
          |> string.trim()
          |> string.split(" ")
          |> list.map(fn(x) { int.parse(x) |> result.unwrap(0) })
        #(test_val, operands)
      }
      _ -> #(1, [])
    }
  })
}

fn part1(input) {
  input
  |> list.filter(is_passing)
  |> list.fold(0, fn(acc, data: #(Int, List(Int))) { acc + data.0 })
}

fn is_passing(data: #(Int, List(Int))) {
  // for every possible place where the operator can be
  // try to put an operator and check if the result is the test value
  do_is_passing(data.0, data.1 |> list.reverse())
}

fn do_is_passing(test_val, operands) {
  case test_val, operands {
    val, [operand] if val == operand -> True
    val, [last, ..rest] -> {
      // try to delete val by last
      // try to subtract last from val
      let deleted = case { val % last } {
        0 -> do_is_passing(val / last, rest)
        _ -> False
      }
      deleted || do_is_passing(val - last, rest)
    }
    _, _ -> False
  }
}

fn part2(input) {
  input
  |> list.filter(is_passing_2)
  |> list.fold(0, fn(acc, data: #(Int, List(Int))) { acc + data.0 })
}

fn is_passing_2(data: #(Int, List(Int))) {
  // for every possible place where the operator can be
  // try to put an operator and check if the result is the test value
  do_is_passing_2(data.0, data.1)
}

fn do_is_passing_2(test_val, operands) {
  // get all possible permutations of the operators
  let operatos_count = list.length(operands) - 1
  let all_permutations = get_operators_permutations(operatos_count)
  // for each permutation check if it is passing
  list.any(all_permutations, fn(operators) {
    is_passing_with_operators(test_val, operands, operators)
  })
}

fn get_operators_permutations(operators_count) -> List(List(Operator)) {
  case operators_count {
    0 -> [[]]
    _ -> {
      let other = get_operators_permutations(operators_count - 1)
      let with_add = list.map(other, fn(x) { [Add, ..x] })
      let with_mul = list.map(other, fn(x) { [Mul, ..x] })
      let with_concat = list.map(other, fn(x) { [Concat, ..x] })
      list.flatten([with_add, with_mul, with_concat])
    }
  }
}

fn is_passing_with_operators(test_val, operands, operators) {
  list.fold(operators, operands, fn(acc, operator) {
    let assert [a, b, ..rest] = acc
    case operator {
      Add -> [a + b, ..rest]
      Mul -> [a * b, ..rest]
      Concat -> [concat(a, b), ..rest]
    }
  })
  == [test_val]
}

fn concat(a, b) {
  let digits = b |> int.to_string() |> string.length() |> int.to_float()
  let tens = int.power(10, digits) |> result.unwrap(0.0) |> float.round()
  a * tens + b
}
