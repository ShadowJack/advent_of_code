import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/set
import gleam/string
import simplifile

const day = "5"

pub fn main() {
  let input = read_input()
  //io.println("Part 1")
  //let _ = part1(input.0, input.1) |> io.debug()
  io.println("Part 2")
  let #(result1, _fixed1) = part2(input.0, input.1)
  io.debug(result1)
  //io.println("Part 2 option 2")
  //let #(result2, fixed2) = part2_2(input.0, input.1)
  //io.debug(result2)

  //io.println("Comparing fixed updates")
  //list.zip(fixed1, fixed2)
  //|> list.filter(fn(tup) { tup.0 != tup.1 })
  //|> list.each(fn(tup) {
  // io.println("")
  //io.debug(tup.0)
  //io.debug(tup.1)
  //})
}

fn read_input() {
  case
    simplifile.read("./src/day" <> day <> "/input.txt")
    |> result.unwrap("")
    |> string.trim()
    |> string.split("\n\n")
  {
    [rules_str, updates_str] -> #(
      rules_str
        |> string.trim()
        |> string.split("\n")
        |> list.map(fn(l) {
          case
            string.split(l, "|")
            |> list.map(fn(str) { int.parse(str) |> result.unwrap(0) })
          {
            [a, b] -> #(a, b)
            _ -> #(0, 0)
          }
        }),
      updates_str
        |> string.trim()
        |> string.split("\n")
        |> list.map(fn(l) {
          string.split(l, ",")
          |> list.map(fn(str) { int.parse(str) |> result.unwrap(0) })
        }),
    )
    _ -> #([], [])
  }
}

fn part1(rules, updates) {
  list.fold(updates, 0, fn(acc, update) {
    case is_valid(update, rules) {
      True -> acc + get_middle_elem(update)
      False -> acc
    }
  })
}

fn part2(rules, updates) {
  let rules_dict = get_rules_dict(rules)
  list.fold(updates, #(0, []), fn(acc, update) {
    case is_valid(update, rules) {
      True -> acc
      False -> {
        let fixed = fix_update(update, rules_dict)
        #(acc.0 + get_middle_elem(fixed), [fixed, ..acc.1])
      }
    }
  })
}

fn get_rules_dict(rules) {
  list.fold(rules, dict.new(), fn(acc, rule) {
    let #(a, b) = rule
    acc
    |> dict.upsert(a, fn(x) {
      case x {
        None -> set.new() |> set.insert(b)
        Some(set) -> set.insert(set, b)
      }
    })
  })
}

fn is_valid(update, rules) {
  list.all(rules, fn(rule) {
    let #(a, b) = rule
    case get_pos(update, a), get_pos(update, b) {
      Some(a_pos), Some(b_pos) -> a_pos < b_pos
      _, _ -> True
    }
  })
}

fn get_pos(update, elem) {
  list.index_fold(update, None, fn(acc, e, idx) {
    case acc, e == elem {
      Some(_), _ -> acc
      _, True -> Some(idx)
      _, False -> None
    }
  })
}

fn get_middle_elem(update) {
  let len = list.length(update)
  list.drop(update, len / 2) |> list.first() |> result.unwrap(0)
}

fn expand_rules(rules) {
  list.fold(rules, dict.new(), fn(acc, rule) {
    let #(a, b) = rule
    acc
    |> dict.upsert(a, fn(x) {
      case x {
        None -> set.new() |> set.insert(b)
        Some(set) -> set.insert(set, b)
      }
    })
    |> dict.map_values(fn(_key, val) {
      // if set has a, add b to it
      case set.contains(val, a) {
        True -> set.insert(val, b)
        _ -> val
      }
    })
  })
}

fn fix_update(update, rules) {
  io.println("")
  io.println("Fixing update:")
  io.debug(update)
  // reorder items in the update to make it valid
  list.sort(update, fn(a, b) {
    let a_lt_b =
      dict.get(rules, a)
      |> result.map(set.contains(_, b))
      |> result.unwrap(False)
    let b_lt_a =
      dict.get(rules, b)
      |> result.map(set.contains(_, a))
      |> result.unwrap(False)

    io.print(
      int.to_string(a)
      <> " vs "
      <> int.to_string(b)
      <> ": a<b="
      <> bool.to_string(a_lt_b)
      <> ", b<a="
      <> bool.to_string(b_lt_a)
      <> ", result: ",
    )
    case a_lt_b, b_lt_a {
      True, _ -> {
        io.println(int.to_string(a) <> " < " <> int.to_string(b))
        order.Lt
      }
      _, True -> {
        io.println(int.to_string(a) <> " > " <> int.to_string(b))
        order.Gt
      }
      _, _ -> {
        io.println("No order")
        order.Eq
      }
    }
  })
  |> io.debug()
}

fn find_bigger(target, rules, next_vals, visited) {
  io.println(
    set.to_list(visited) |> list.map(int.to_string) |> string.join(", "),
  )
  case set.contains(next_vals, target) {
    True -> True
    False -> {
      // for each next val run the function iteratively
      set.to_list(next_vals)
      |> list.filter(fn(val) { !set.contains(visited, val) })
      |> list.any(fn(val) {
        find_bigger(
          target,
          rules,
          dict.get(rules, val) |> result.unwrap(set.new()),
          set.insert(visited, val),
        )
      })
    }
  }
}

// Second take on part 2
fn part2_2(rules, updates) {
  let all_ordered_numbers =
    order_numbers_by_rules(rules)
    |> io.debug()
  list.fold(updates, #(0, []), fn(acc, update) {
    case is_valid(update, rules) {
      True -> acc
      False -> {
        let fixed = fix_update_2(update, all_ordered_numbers)
        #(acc.0 + get_middle_elem(fixed), [fixed, ..acc.1])
      }
    }
  })
}

fn order_numbers_by_rules(rules) {
  let expanded_rules = expand_rules(rules)
  io.println("Expanded rules for 91:")
  let _ =
    io.debug(
      dict.get(expanded_rules, 91) |> result.unwrap(set.new()) |> set.to_list(),
    )
  list.fold(rules, set.new(), fn(acc, rule) {
    let #(a, b) = rule
    acc |> set.insert(a) |> set.insert(b)
  })
  |> set.to_list()
  |> list.sort(fn(a, b) {
    let a_lt_b = dict.get(expanded_rules, a) |> result.map(set.contains(_, b))
    let b_lt_a = dict.get(expanded_rules, b) |> result.map(set.contains(_, a))
    case a, b {
      91, 99 -> {
        io.print("/// 91 <  99:")
        let _ = io.debug(a_lt_b)
        Nil
      }
      99, 91 -> {
        io.print("/// 91 < 99:")
        let _ = io.debug(b_lt_a)
        Nil
      }
      _, _ -> Nil
    }
    case a_lt_b, b_lt_a {
      Ok(True), _ -> order.Lt
      _, Ok(True) -> order.Gt
      _, _ -> order.Eq
    }
  })
}

fn fix_update_2(update, all_nums_ordered) {
  all_nums_ordered |> list.filter(fn(num) { list.contains(update, num) })
}
