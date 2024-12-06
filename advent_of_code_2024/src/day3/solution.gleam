import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import simplifile

const day = "3"

pub fn main() {
  let input_result = read_input()
  io.println("Part 1")
  let _ =
    result.map(input_result, fn(input) { run_instructions(input) })
    |> io.debug()

  io.println("Part 2")
  let _ =
    result.map(input_result, fn(input) { run_instructions2(input) })
    |> io.debug()
}

fn read_input() {
  simplifile.read("./src/day" <> day <> "/input.txt")
}

fn run_instructions(input: String) {
  input
  |> get_instructions()
  |> list.fold(0, fn(acc, instruction) { acc + instruction.0 * instruction.1 })
}

fn get_instructions(input: String) -> List(#(Int, Int)) {
  regexp.from_string("mul\\((\\d{1,3}),(\\d{1,3})\\)")
  |> result.map(fn(r) { regexp.scan(r, input) })
  |> result.unwrap([])
  |> list.map(fn(m) {
    case m.submatches {
      [Some(a), Some(b)] -> {
        let x = a |> int.parse() |> result.unwrap(0)
        let y = b |> int.parse() |> result.unwrap(0)
        #(x, y)
      }
      _ -> #(0, 0)
    }
  })
}

// Part 2

type Instruction {
  Do
  Dont
  Mul(Int, Int)
}

fn run_instructions2(input: String) {
  input
  |> get_instructions2()
  |> process_instructions()
}

fn get_instructions2(input: String) -> List(Instruction) {
  regexp.from_string("do\\(\\)|don't\\(\\)|mul\\((\\d{1,3}),(\\d{1,3})\\)")
  |> result.map(fn(r) { regexp.scan(r, input) })
  |> result.unwrap([])
  |> list.map(fn(m) {
    case m.content {
      "do()" -> Do
      "don't()" -> Dont
      _ -> {
        case m.submatches {
          [Some(a), Some(b)] -> {
            let x = a |> int.parse() |> result.unwrap(0)
            let y = b |> int.parse() |> result.unwrap(0)
            Mul(x, y)
          }
          _ -> Mul(0, 0)
        }
      }
    }
  })
}

fn process_instructions(instructions: List(Instruction)) -> Int {
  list.fold(instructions, #(0, True), fn(acc, instruction) {
    case instruction, acc {
      Do, #(curr, _) -> #(curr, True)
      Dont, #(curr, _) -> #(curr, False)
      Mul(a, b), #(curr, True) -> #(curr + a * b, True)
      _, #(curr, False) -> #(curr, False)
    }
  }).0
}
