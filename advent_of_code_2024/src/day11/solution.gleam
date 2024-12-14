import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

const day = "11"

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
  |> string.split(" ")
  |> list.filter_map(int.parse)
}

fn part1(input) {
  let result =
    list.fold(list.range(1, 25), input, fn(acc, _) {
      io.print(list.length(acc) |> int.to_string() <> " ")
      let result = apply_rules(acc)
      result
    })
    |> list.length()

  io.println("")
  io.print("0 ")
  list.fold(list.range(1, 25), input, fn(acc, _) {
    let result = apply_rules(acc)
    let diff = list.length(result) - list.length(acc)
    io.print(int.to_string(diff) <> " ")
    result
  })

  result
}

fn part2(input) {
  let #(result, _) =
    list.fold(input, #(0, dict.new()), fn(acc, num) {
      let #(count, cache) = calc(num, 75, acc.1)
      #(acc.0 + count, cache)
    })

  result
}

fn apply_rules(stones) {
  // If the stone is engraved with the number 0, it is replaced by a stone engraved with the number 1.
  // If the stone is engraved with a number that has an even number of digits, it is replaced by two stones. The left half of the digits are engraved on the new left stone, and the right half of the digits are engraved on the new right stone. (The new numbers don't keep extra leading zeroes: 1000 would become stones 10 and 0.)
  //If none of the other rules apply, the stone is replaced by a new stone; the old stone's number multiplied by 2024 is engraved on the new stone.
  stones
  |> list.flat_map(fn(stone) {
    let is_even_digits =
      int.to_string(stone) |> string.length() |> int.is_even()
    case stone, is_even_digits {
      0, _ -> [1]
      num, True -> split(num)
      num, False -> [num * 2024]
    }
  })
}

fn split(number) {
  let str = int.to_string(number)
  let left =
    string.drop_end(str, string.length(str) / 2)
    |> int.parse()
    |> result.unwrap(0)
  let right =
    string.drop_start(str, string.length(str) / 2)
    |> int.parse()
    |> result.unwrap(0)
  [left, right]
}

fn calc(number, steps, cache) {
  case steps {
    0 -> #(1, cache)
    _ ->
      case dict.get(cache, #(number, steps)) {
        Ok(count) -> #(count, cache)
        Error(_) -> {
          let new_numbers = apply_rules([number])
          let #(count, new_cache) =
            list.fold(new_numbers, #(0, cache), fn(acc, num) {
              let #(count, cache) = calc(num, steps - 1, acc.1)
              #(acc.0 + count, cache)
            })
          #(count, dict.insert(new_cache, #(number, steps), count))
        }
      }
  }
}
