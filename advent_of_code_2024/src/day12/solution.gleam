import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import glearray
import simplifile

const day = "12"

type Coord {
  Coord(x: Int, y: Int)
}

type Edge {
  Horizontal(x: Int, above_y: Int, is_facing_up: Bool)
  Vertical(left_to_x: Int, y: Int, is_facing_right: Bool)
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
  |> string.split("\n")
  |> list.filter(fn(x) { x != "" })
  |> list.map(fn(line) {
    line
    |> string.split("")
    |> glearray.from_list()
  })
  |> glearray.from_list()
}

fn part1(input) {
  input
  |> find_regions()
  |> list.fold(0, fn(acc, region) {
    get_area(region) * get_perimeter(region) + acc
  })
}

fn find_regions(input) {
  let #(width, height) = get_dimensions(input)

  let #(_, regions) =
    iterator.range(0, width * height - 1)
    |> iterator.fold(#(set.new(), []), fn(acc, idx) {
      let coord = Coord(idx % width, idx / width)
      case set.contains(acc.0, coord) {
        True -> acc
        False -> {
          let letter =
            glearray.get(input, coord.y)
            |> result.unwrap(glearray.new())
            |> glearray.get(coord.x)
            |> result.unwrap("")
          let region =
            find_region(input, letter, [coord], set.from_list([coord]))
          let updated_cache =
            list.fold(set.to_list(region), acc.0, fn(acc, coord) {
              set.insert(acc, coord)
            })
          #(updated_cache, [region, ..acc.1])
        }
      }
    })

  regions
}

fn find_region(input, letter, queue, region) {
  case queue {
    [] -> region
    [coord, ..rest] -> {
      let Coord(x, y) = coord
      let neighbors =
        [Coord(x + 1, y), Coord(x - 1, y), Coord(x, y + 1), Coord(x, y - 1)]
        |> list.filter(fn(coord) {
          glearray.get(input, coord.y)
          |> result.unwrap(glearray.new())
          |> glearray.get(coord.x)
          |> result.unwrap("")
          == letter
          && !set.contains(region, coord)
        })
      let updated_region =
        list.fold(neighbors, region, fn(acc, coord) { set.insert(acc, coord) })
      find_region(input, letter, list.append(rest, neighbors), updated_region)
    }
  }
}

fn get_dimensions(input) {
  let width =
    glearray.get(input, 0) |> result.unwrap(glearray.new()) |> glearray.length()
  let height = glearray.length(input)
  #(width, height)
}

fn get_area(region) {
  set.size(region)
}

fn get_perimeter(region) {
  region
  |> set.fold(0, fn(acc, coord) {
    let Coord(x, y) = coord
    [Coord(x + 1, y), Coord(x - 1, y), Coord(x, y + 1), Coord(x, y - 1)]
    |> list.fold(acc, fn(acc, coord) {
      case set.contains(region, coord) {
        True -> acc
        False -> acc + 1
      }
    })
  })
}

fn part2(input) {
  input
  |> find_regions()
  |> list.fold(0, fn(acc, region) { get_area(region) * get_sides(region) + acc })
}

fn get_sides(region) {
  let edges =
    set.fold(region, set.new(), fn(edges, coord) {
      let Coord(x, y) = coord
      [Coord(x + 1, y), Coord(x - 1, y), Coord(x, y + 1), Coord(x, y - 1)]
      |> list.fold(edges, fn(acc, neib) {
        case set.contains(region, neib) {
          True -> acc
          False -> {
            set.insert(acc, build_edge(coord, neib))
          }
        }
      })
    })
  //  group neighboring edges into a single side
  let #(_, sides) =
    set.fold(edges, #(edges, []), fn(acc, edge) {
      let #(edges, sides) = acc
      case set.contains(edges, edge) {
        False -> acc
        True -> {
          // find all neighboring edges and add them to the side
          let side = get_side(edges, [edge], set.from_list([edge]))
          #(set.drop(edges, side), [side, ..sides])
        }
      }
      // if there's a neighboring edge in the acc
      // remove current edge from the acc
    })
  list.length(sides)
}

fn build_edge(coord1, coord2) {
  let Coord(x1, y1) = coord1
  let Coord(x2, y2) = coord2
  case x1 == x2 {
    True -> Horizontal(x1, int.max(y1, y2), y1 > y2)
    False -> Vertical(int.max(x1, x2), y1, x1 < x2)
  }
}

fn get_side(edges, queue, side) {
  // go up/right and down/left until there's no more edges
  case queue {
    [] -> set.to_list(side)
    [edge, ..rest] -> {
      let neibs =
        get_edge_neibs(edge)
        |> list.filter(fn(neib) {
          !set.contains(side, neib) && set.contains(edges, neib)
        })
      let updated_side = set.union(side, set.from_list(neibs))
      get_side(edges, list.append(rest, neibs), updated_side)
    }
  }
}

fn get_edge_neibs(edge) {
  // make sure the edges are oriented the same way
  case edge {
    Vertical(x, y, is_facing_right) -> [
      Vertical(x, y - 1, is_facing_right),
      Vertical(x, y + 1, is_facing_right),
    ]
    Horizontal(x, y, is_facing_up) -> [
      Horizontal(x - 1, y, is_facing_up),
      Horizontal(x + 1, y, is_facing_up),
    ]
  }
}
