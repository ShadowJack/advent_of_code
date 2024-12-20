import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile
import trie

const day = "19"

const is_test = False

pub fn main() {
  let input = read_input()
  io.println("Part 1")
  let _ = part1(input) |> io.debug()
  io.println("Part 2")
  let _ = part2(input) |> io.debug()
}

fn read_input() {
  let assert [towels, designs] =
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
    |> string.split("\n\n")

  let towels =
    towels
    |> string.trim()
    |> string.split(", ")

  let designs =
    designs
    |> string.trim()
    |> string.split("\n")

  #(towels, designs)
}

fn part1(input: #(List(String), List(String))) {
  let #(towels, designs) = input
  let towels = build_trie(towels)
  list.fold(designs, 0, fn(acc, design) {
    case is_valid(towels, design) {
      True -> acc + 1
      False -> acc
    }
  })
}

fn part2(input: #(List(String), List(String))) {
  let #(towels, designs) = input
  let towels = build_trie(towels)
  list.fold(designs, 0, fn(acc, design) {
    acc + count_combinations(towels, design)
  })
}

fn build_trie(towels) {
  list.fold(towels, trie.new(), fn(trie, towel) {
    trie.insert(trie, towel |> string.split(""), True)
  })
}

fn is_valid(towels, design) {
  case string.is_empty(design) {
    True -> True
    False -> {
      list.range(string.length(design), 1)
      |> list.any(fn(i) {
        let prefix = string.slice(design, 0, i)
        let suffix = string.slice(design, i, string.length(design) - i)
        case trie.has_path(towels, prefix |> string.split("")) {
          True -> is_valid(towels, suffix)
          False -> False
        }
      })
    }
  }
}

fn count_combinations(towels, design) {
  case string.is_empty(design) {
    True -> 1
    False -> {
      list.range(string.length(design), 1)
      |> list.fold(0, fn(sum, i) {
        let prefix = string.slice(design, 0, i)
        let suffix = string.slice(design, i, string.length(design) - i)
        case trie.has_path(towels, prefix |> string.split("")) {
          True -> sum + count_combinations(towels, suffix)
          False -> sum
        }
      })
    }
  }
}
