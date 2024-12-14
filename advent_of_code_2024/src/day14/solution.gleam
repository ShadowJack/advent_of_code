import gleam/bit_array
import gleam/float
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/string
import glearray
import pngleam
import simplifile

const day = "14"

const is_test = False

pub type Coords {
  Coords(x: Int, y: Int)
}

pub type Robot {
  Robot(p: Coords, v: Coords)
}

pub fn main() {
  let input = read_input()
  io.println("Part 1")
  let _ = part1(input) |> io.debug()
  let _ = part2(input)
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
  |> list.map(parse_robot)
}

fn parse_robot(line) {
  regexp.from_string("p=(-?\\d+),(-?\\d+) v=(-?\\d+),(-?\\d+)")
  |> result.map(fn(r) { regexp.scan(r, line) })
  |> result.unwrap([])
  |> list.map(fn(m) {
    case m.submatches {
      [Some(p_x), Some(p_y), Some(v_x), Some(v_y)] -> {
        Robot(
          Coords(
            int.parse(p_x) |> result.unwrap(0),
            int.parse(p_y) |> result.unwrap(0),
          ),
          Coords(
            int.parse(v_x) |> result.unwrap(0),
            int.parse(v_y) |> result.unwrap(0),
          ),
        )
      }
      _ -> Robot(Coords(0, 0), Coords(0, 0))
    }
  })
  |> list.first()
  |> result.unwrap(Robot(Coords(0, 0), Coords(0, 0)))
}

fn part1(input) {
  let dimensions = case is_test {
    True -> #(11, 7)
    False -> #(101, 103)
  }
  input
  |> simulate(dimensions, steps: 100, print: False)
  |> calc_safety_factor(dimensions)
}

fn part2(input) {
  let dimensions = case is_test {
    True -> #(11, 7)
    False -> #(101, 103)
  }
  input
  |> simulate(dimensions, steps: 10_000, print: True)
}

fn simulate(
  input: List(Robot),
  dimensions: #(Int, Int),
  steps steps: Int,
  print print: Bool,
) {
  // for each step
  // update the position of each robot
  iterator.range(1, steps)
  |> iterator.fold(input, fn(state, step) {
    let upd_state =
      list.map(state, fn(robot) {
        let new_x = wrap(robot.p.x + robot.v.x, dimensions.0)
        let new_y = wrap(robot.p.y + robot.v.y, dimensions.1)
        Robot(Coords(new_x, new_y), robot.v)
      })

    let #(var_x, var_y) = get_variance(upd_state)
    case float.min(var_x, var_y) <. 500.0 && print {
      True -> print_map(upd_state, dimensions, step)
      False -> Nil
    }

    upd_state
  })
}

fn wrap(value, dimension) {
  case value {
    val if val < 0 -> val + dimension
    val if val >= dimension -> val - dimension
    _ -> value
  }
}

fn calc_safety_factor(robots: List(Robot), dimensions: #(Int, Int)) {
  // for each quadrant count the number of robots in it
  // and multiply the results
  let #(q0, q1, q2, q3) =
    list.fold(robots, #(0, 0, 0, 0), fn(acc, robot) {
      case get_quadrant(robot.p, dimensions) {
        Ok(0) -> #(acc.0 + 1, acc.1, acc.2, acc.3)
        Ok(1) -> #(acc.0, acc.1 + 1, acc.2, acc.3)
        Ok(2) -> #(acc.0, acc.1, acc.2 + 1, acc.3)
        Ok(3) -> #(acc.0, acc.1, acc.2, acc.3 + 1)
        _ -> acc
      }
    })
  q0 * q1 * q2 * q3
}

fn get_quadrant(coords: Coords, dimensions: #(Int, Int)) {
  let x_center = dimensions.0 / 2
  let y_center = dimensions.1 / 2
  case coords {
    Coords(x, y) if x < x_center && y < y_center -> Ok(0)
    Coords(x, y) if x > x_center && y < y_center -> Ok(1)
    Coords(x, y) if x < x_center && y > y_center -> Ok(2)
    Coords(x, y) if x > x_center && y > y_center -> Ok(3)
    _ -> Error(Nil)
  }
}

fn print_map(robots: List(Robot), dimensions: #(Int, Int), step: Int) -> Nil {
  let _ =
    list.fold(
      robots,
      list.repeat(
        list.repeat(False, dimensions.0) |> glearray.from_list(),
        dimensions.1,
      )
        |> glearray.from_list(),
      fn(map, robot) {
        let row = glearray.get(map, robot.p.y) |> result.unwrap(glearray.new())
        glearray.copy_set(
          map,
          robot.p.y,
          glearray.copy_set(row, robot.p.x, True)
            |> result.unwrap(glearray.new()),
        )
        |> result.unwrap(glearray.new())
      },
    )
    |> glearray.to_list()
    |> list.map(fn(row) {
      row
      |> glearray.to_list()
      |> list.map(fn(x) {
        case x {
          False -> <<0x00, 0x00, 0x00>>
          True -> <<0x00, 0xFF, 0x00>>
        }
      })
      |> bit_array.concat()
    })
    |> pngleam.from_packed(
      width: dimensions.0,
      height: dimensions.1,
      color_info: pngleam.rgb_8bit,
      compression_level: pngleam.default_compression,
    )
    |> simplifile.write_bits(
      "src/day14/tree/" <> int.to_string(step) <> ".png",
      _,
    )
  Nil
}

fn get_variance(robots: List(Robot)) {
  let mean_x =
    list.fold(robots, 0.0, fn(acc, robot) { acc +. int.to_float(robot.p.x) })
    /. int.to_float(list.length(robots))
  let mean_y =
    list.fold(robots, 0.0, fn(acc, robot) { acc +. int.to_float(robot.p.y) })
    /. int.to_float(list.length(robots))

  let variance_x =
    list.fold(robots, 0.0, fn(acc, robot) {
      acc
      +. {
        float.power(int.to_float(robot.p.x) -. mean_x, 2.0)
        |> result.unwrap(0.0)
      }
    })
    /. int.to_float(list.length(robots))
  let variance_y =
    list.fold(robots, 0.0, fn(acc, robot) {
      acc
      +. {
        float.power(int.to_float(robot.p.y) -. mean_y, 2.0)
        |> result.unwrap(0.0)
      }
    })
    /. int.to_float(list.length(robots))

  #(variance_x, variance_y)
}
