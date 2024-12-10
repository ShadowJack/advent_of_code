import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/string
import glearray
import simplifile

const day = "9"

pub type Block {
  File(id: Int, len: Int)
  Empty(len: Int)
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
  |> string.split("")
  |> list.filter_map(fn(char) { char |> int.parse() })
}

fn part1(input) {
  // do the compact thing while calculating the checksum
  //build_blocks_list(input) |> glearray.from_list() |> compact(0) |> checksum()
  let blocks =
    build_blocks_list(input)
    |> list.map(fn(x) { [x] })
    |> glearray.from_list()
  let #(compacted, _, _) = compact(blocks, 1, glearray.length(blocks) - 1)
  checksum(compacted)
}

fn build_blocks_list(input) {
  let #(_, list) =
    input
    |> list.map_fold(#(True, 0), fn(file_id, num) {
      case file_id {
        #(True, id) -> #(#(False, id + 1), File(id, num))
        #(False, id) -> #(#(True, id), Empty(num))
      }
    })
  list
}

fn compact(blocks, curr_idx, file_idx) {
  case curr_idx >= file_idx {
    True -> #(
      blocks |> glearray.to_list() |> list.flatten(),
      curr_idx,
      file_idx,
    )
    False -> {
      let curr_subblocks =
        glearray.get(blocks, curr_idx)
        |> result.unwrap([])
      let empty_len =
        curr_subblocks
        |> list.find_map(fn(b) {
          case b {
            Empty(l) -> Ok(l)
            _ -> Error(Nil)
          }
        })
        |> result.unwrap(0)
      let assert Ok([File(file_id, file_len)]) = glearray.get(blocks, file_idx)
      case file_len, empty_len {
        _fl, 0 -> {
          // remove the empty block
          let new_curr_idx = curr_idx + 2
          let new_file_idx = file_idx
          let new_subblocks =
            curr_subblocks |> list.reverse() |> list.drop(1) |> list.reverse()
          let new_blocks =
            glearray.copy_set(blocks, curr_idx, new_subblocks)
            |> result.unwrap(glearray.new())
          compact(new_blocks, new_curr_idx, new_file_idx)
        }
        fl, el if fl > el -> {
          // split the file block in two as it's too big
          let new_curr_idx = curr_idx + 2
          let new_file_idx = file_idx
          let new_subblocks =
            curr_subblocks
            |> list.reverse()
            |> list.drop(1)
            |> list.prepend(File(file_id, el))
            |> list.reverse()
          let new_blocks =
            glearray.copy_set(blocks, curr_idx, new_subblocks)
            |> result.unwrap(glearray.new())
            |> glearray.copy_set(file_idx, [File(file_id, fl - el)])
            |> result.unwrap(glearray.new())
          compact(new_blocks, new_curr_idx, new_file_idx)
        }
        fl, el if fl == el -> {
          // replace the empty block with the file block
          let new_curr_idx = curr_idx + 2
          let new_file_idx = file_idx - 2
          let new_subblocks =
            curr_subblocks
            |> list.reverse()
            |> list.drop(1)
            |> list.prepend(File(file_id, el))
            |> list.reverse()
          let new_blocks =
            glearray.copy_set(blocks, curr_idx, new_subblocks)
            |> result.unwrap(glearray.new())
            |> glearray.copy_set(file_idx, [])
            |> result.unwrap(glearray.new())
          compact(new_blocks, new_curr_idx, new_file_idx)
        }
        fl, el -> {
          // move the file block to the empty block
          let new_curr_idx = curr_idx
          let new_file_idx = file_idx - 2
          let new_subblocks =
            curr_subblocks
            |> list.reverse()
            |> list.drop(1)
            |> list.prepend(File(file_id, fl))
            |> list.prepend(Empty(el - fl))
            |> list.reverse()
          let new_blocks =
            glearray.copy_set(blocks, curr_idx, new_subblocks)
            |> result.unwrap(glearray.new())
            |> glearray.copy_set(file_idx, [])
            |> result.unwrap(glearray.new())
          compact(new_blocks, new_curr_idx, new_file_idx)
        }
      }
    }
  }
}

fn checksum(blocks) {
  let #(_, result) =
    list.fold(blocks, #(0, 0), fn(acc, block) {
      case block {
        File(id, len) -> {
          let new_idx = acc.0 + len
          let addition = id * { acc.0 + acc.0 + len - 1 } * len / 2
          #(new_idx, acc.1 + addition)
        }
        Empty(len) -> #(acc.0 + len, acc.1)
      }
    })
  result
}

fn part2(input) {
  let blocks =
    build_blocks_list(input)
    |> list.map(fn(x) { [x] })
    |> glearray.from_list()

  let #(compacted, _) = compact2(blocks, glearray.length(blocks) - 1)
  checksum(compacted)
}

fn compact2(blocks, file_idx) {
  case file_idx > 0 {
    False -> #(blocks |> glearray.to_list() |> list.flatten(), file_idx)
    True -> {
      let assert Ok([File(file_id, file_len)]) = glearray.get(blocks, file_idx)
      case find_fitting_empty_block(blocks, file_idx, file_len) {
        Ok(#(subblocks, idx)) -> {
          // put the file into the empty block that fits this file
          let assert Ok(Empty(el)) = list.last(subblocks)
          let new_subblocks = case el > file_len {
            True ->
              subblocks
              |> list.reverse()
              |> list.drop(1)
              |> list.prepend(File(file_id, file_len))
              |> list.prepend(Empty(el - file_len))
              |> list.reverse()
            False ->
              subblocks
              |> list.reverse()
              |> list.drop(1)
              |> list.prepend(File(file_id, file_len))
              |> list.reverse()
          }
          let new_blocks =
            glearray.copy_set(blocks, idx, new_subblocks)
            |> result.unwrap(glearray.new())
            |> glearray.copy_set(file_idx, [Empty(file_len)])
            |> result.unwrap(glearray.new())
          compact2(new_blocks, file_idx - 2)
          // can't move the file to any empty block
        }
        _ -> compact2(blocks, file_idx - 2)
        // can't move the file to any empty block
      }
    }
  }
}

fn find_fitting_empty_block(blocks, file_idx, file_len) {
  blocks
  |> glearray.iterate()
  |> iterator.index()
  |> iterator.take(file_idx)
  //|> iterator.drop()
  |> iterator.find(fn(val) {
    let #(subblocks, _idx) = val
    list.any(subblocks, fn(b) {
      case b {
        Empty(l) -> l >= file_len
        _ -> False
      }
    })
  })
}
