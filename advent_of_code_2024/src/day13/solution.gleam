import gleam/int
import gleam/io
import gleam/list.{Continue, Stop}
import gleam/option.{None, Some}
import gleam/regexp
import gleam/result
import gleam/set
import gleam/string
import glearray
import simplifile

const day = "13"

pub type Coords {
  Coords(x: Int, y: Int)
}

pub type MachineInfo {
  MachineInfo(a: Coords, b: Coords, prize: Coords)
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
  |> string.split("\n\n")
  |> list.filter(fn(x) { x != "" })
  |> list.map(fn(block) {
    let assert [a, b, prize] =
      block
      |> string.split("\n")
      |> list.filter(fn(x) { x != "" })

    MachineInfo(parse_button(a), parse_button(b), parse_prize(prize))
  })
}

fn parse_button(line) {
  parse_coords_from_line(line, "Button [A|B]: X\\+(\\d+), Y\\+(\\d+)")
}

fn parse_prize(line) {
  parse_coords_from_line(line, "Prize: X=(\\d+), Y=(\\d+)")
}

fn parse_coords_from_line(line, regex) {
  regexp.from_string(regex)
  |> result.map(fn(r) { regexp.scan(r, line) })
  |> result.unwrap([])
  |> list.map(fn(m) {
    case m.submatches {
      [Some(x), Some(y)] -> {
        Coords(
          int.parse(x) |> result.unwrap(0),
          int.parse(y) |> result.unwrap(0),
        )
      }
      _ -> Coords(0, 0)
    }
  })
  |> list.first()
  |> result.unwrap(Coords(0, 0))
}

fn part1(input) {
  input
  |> list.fold(0, fn(acc, machine) { acc + tokens_spent(machine) })
}

fn part2(input) {
  input
  |> update_prizes()
  |> list.fold(0, fn(acc, machine) { acc + tokens_spent2(machine) })
}

fn tokens_spent(machine: MachineInfo) {
  // System:
  // a * A + b * B = Prize
  // (a * 3 + 1) -> minimize
  let MachineInfo(a_coords, b_coords, prize) = machine
  let max_a = int.min(prize.x / a_coords.x, prize.y / a_coords.y)
  list.fold(list.range(0, max_a), 0, fn(acc, a) {
    let left_to_prize =
      Coords(prize.x - a * a_coords.x, prize.y - a * a_coords.y)
    case
      left_to_prize.x % b_coords.x,
      left_to_prize.y % b_coords.y,
      left_to_prize.x / b_coords.x,
      left_to_prize.y / b_coords.y
    {
      0, 0, b_x, b_y if b_x == b_y -> {
        // update acc if we have a better solution
        case a * 3 + b_x * 1 < acc || acc == 0 {
          True -> a * 3 + b_x * 1
          False -> acc
        }
      }
      _, _, _, _ -> acc
    }
  })
}

fn update_prizes(input) {
  list.map(input, fn(machine) {
    MachineInfo(
      ..machine,
      prize: Coords(
        machine.prize.x + 10_000_000_000_000,
        machine.prize.y + 10_000_000_000_000,
      ),
    )
  })
}

fn tokens_spent2(machine: MachineInfo) {
  // check if vectors are not collinear, then just calc the coefficients
  case is_collinear(machine.a, machine.b) {
    True -> tokens_spent(machine)
    False -> {
      let up = machine.prize.y * machine.a.x - machine.prize.x * machine.a.y
      let down = machine.b.y * machine.a.x - machine.b.x * machine.a.y
      case up % down {
        0 -> {
          let b = up / down
          let a = { machine.prize.x - b * machine.b.x } / machine.a.x
          case { machine.prize.x - b * machine.b.x } % machine.a.x {
            0 -> a * 3 + b * 1
            _ -> 0
          }
        }
        _ -> 0
      }
    }
  }
}

fn is_collinear(a: Coords, b: Coords) {
  a.x * b.y == a.y * b.x
}
