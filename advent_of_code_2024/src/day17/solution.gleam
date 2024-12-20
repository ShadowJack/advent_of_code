import gleam/float
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/string

const is_test = False

pub fn main() {
  let input = read_input()
  io.println("Part 1")
  let _ = part1(input) |> io.debug()
  io.println("Part 2")
  let _ = part2(input) |> io.debug()
}

fn read_input() {
  case is_test {
    True -> #(729, 0, 0, split_instructions("0,3,5,4,3,0"))
    False -> #(
      53_437_164,
      0,
      0,
      split_instructions("2,4,1,7,7,5,4,1,1,4,5,5,0,3,3,0"),
    )
  }
}

fn split_instructions(str) {
  str
  |> string.split(",")
  |> list.map(int.parse)
  |> list.filter_map(fn(x) { x })
}

fn part1(input) {
  let #(a, b, c, sequence) = input
  run_program(a, b, c, sequence, 0, [])
  |> list.map(int.to_string)
  |> string.join(",")
}

fn run_program(a, b, c, sequence, pointer, output) {
  let operation = iterator.from_list(sequence) |> iterator.at(pointer)
  let operand = iterator.from_list(sequence) |> iterator.at(pointer + 1)
  case operation, operand {
    Ok(0), Ok(operand) -> {
      // The adv instruction (opcode 0) performs division.
      // The numerator is the value in the A register. The denominator is found by raising 2 to the power of the instruction's combo operand. The result of the division operation is truncated to an integer and then written to the A register.
      let raised =
        float.power(2.0, int.to_float(read_combo(operand, a, b, c)))
        |> result.unwrap(1.0)
      let result = { int.to_float(a) /. raised } |> float.truncate()
      run_program(result, b, c, sequence, pointer + 2, output)
    }
    Ok(1), Ok(operand) -> {
      // The bxl instruction (opcode 1) calculates the bitwise XOR of register B and the instruction's literal operand, then stores the result in register B.
      let result = int.bitwise_exclusive_or(b, operand)
      run_program(a, result, c, sequence, pointer + 2, output)
    }
    Ok(2), Ok(operand) -> {
      // The bst instruction (opcode 2) calculates the value of its combo operand modulo 8 (thereby keeping only its lowest 3 bits), then writes that value to the B register.
      let result = read_combo(operand, a, b, c) % 8
      run_program(a, result, c, sequence, pointer + 2, output)
    }
    Ok(3), Ok(operand) -> {
      // The jnz instruction (opcode 3) does nothing if the A register is 0.
      // However, if the A register is not zero, it jumps by setting the instruction pointer to the value of its literal operand.
      let result = case a {
        0 -> pointer + 2
        _ -> operand
      }
      run_program(a, b, c, sequence, result, output)
    }
    Ok(4), _operand -> {
      // The bxc instruction (opcode 4) calculates the bitwise XOR of register B and register C, then stores the result in register B. (For legacy reasons, this instruction reads an operand but ignores it.)
      let result = int.bitwise_exclusive_or(b, c)
      run_program(a, result, c, sequence, pointer + 2, output)
    }
    Ok(5), Ok(operand) -> {
      // The out instruction (opcode 5) calculates the value of its combo operand modulo 8, then outputs that value.
      let result = read_combo(operand, a, b, c) % 8
      run_program(a, b, c, sequence, pointer + 2, [result, ..output])
      // we have not found the required output
    }
    Ok(6), Ok(operand) -> {
      // The bdv instruction (opcode 6) works exactly like the adv instruction except that the result is stored in the B register. (The numerator is still read from the A register.)
      let raised =
        float.power(2.0, int.to_float(read_combo(operand, a, b, c)))
        |> result.unwrap(1.0)
      let result = { int.to_float(a) /. raised } |> float.truncate()
      run_program(a, result, c, sequence, pointer + 2, output)
    }
    Ok(7), Ok(operand) -> {
      // The cdv instruction (opcode 7) works exactly like the adv instruction except that the result is stored in the C register. (The numerator is still read from the A register.)
      let raised =
        float.power(2.0, int.to_float(read_combo(operand, a, b, c)))
        |> result.unwrap(1.0)
      let result = { int.to_float(a) /. raised } |> float.truncate()
      run_program(a, b, result, sequence, pointer + 2, output)
    }
    _, _ -> list.reverse(output)
  }
}

fn read_combo(operand, a, b, c) {
  case operand {
    4 -> a
    5 -> b
    6 -> c
    literal -> literal
  }
}

/// Part 2
//

fn part2(input) {
  let #(_a, b, c, sequence) = input
  let a_start = int.power(8, 13.0) |> result.unwrap(0.0) |> float.truncate()
  find_a(a_start * 2, b, c, sequence)
}

fn find_a(a, b, c, sequence) {
  case run_program(a, b, c, sequence, 0, []) {
    output if output == sequence -> a
    other -> {
      case a % 1_000_000 {
        0 -> io.println(int.to_string(a) <> " " <> string.inspect(other))
        _ -> Nil
      }
      //io.debug(other)
      find_a(a + 1, b, c, sequence)
    }
  }
}
