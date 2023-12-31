use core::panic;
use pathfinding::prelude::dijkstra;
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day17/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let data: Vec<Vec<u32>> = reader
        .lines()
        .map(|l| {
            let input = l.unwrap();
            let seq: Vec<u32> = input
                .chars()
                .map(|ch| u32::from_str_radix(&ch.to_string(), 10).unwrap())
                .collect();
            return seq;
        })
        .collect();

    let part1_result = dijkstra(
        &State {
            position: (0, 0),
            direction: (Direction::None, 0),
        },
        |x| x.successors(&data, |_curr_dir, next_dir| next_dir.1 <= 3),
        |x| x.position == (data.len() - 1, data[0].len() - 1),
    )
    .unwrap();
    println!("Part1: {:?}", part1_result.1);

    let part2_result = dijkstra(
        &State {
            position: (0, 0),
            direction: (Direction::None, 0),
        },
        |x| {
            x.successors(&data, |curr_dir, next_dir| {
                if curr_dir.0 == next_dir.0 {
                    next_dir.1 <= 10
                } else if curr_dir.0 == Direction::None {
                    true
                } else {
                    // we can turn only if we have moved 4 cells in the current direction
                    curr_dir.1 >= 4
                }
            })
        },
        |x| x.position == (data.len() - 1, data[0].len() - 1) && x.direction.1 >= 4,
    )
    .unwrap();
    println!("Part2: {}", part2_result.1);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Hash, Debug)]
enum Direction {
    None,
    Up,
    Right,
    Down,
    Left,
}

#[derive(Clone, PartialEq, Eq, Hash, Debug)]
struct State {
    position: (usize, usize),
    direction: (Direction, u8),
}

impl State {
    fn successors(
        &self,
        data: &Vec<Vec<u32>>,
        is_valid_direction: fn((Direction, u8), (Direction, u8)) -> bool,
    ) -> Vec<(State, u32)> {
        let dirs = [
            Direction::Up,
            Direction::Right,
            Direction::Down,
            Direction::Left,
        ];
        dirs.iter()
            .map(|dir| {
                let pos = match dir {
                    Direction::Up => (self.position.0 as i32 - 1, self.position.1 as i32),
                    Direction::Down => (self.position.0 as i32 + 1, self.position.1 as i32),
                    Direction::Right => (self.position.0 as i32, self.position.1 as i32 + 1),
                    Direction::Left => (self.position.0 as i32, self.position.1 as i32 - 1),
                    Direction::None => panic!("Wrong direction"),
                };
                (
                    pos,
                    (
                        *dir,
                        if *dir == self.direction.0 {
                            self.direction.1 + 1
                        } else {
                            1
                        },
                    ),
                )
            })
            .filter_map(|(pos, dir)| {
                if is_valid_direction(self.direction, dir)
                    && !is_opposite_direction(dir.0, self.direction.0)
                    && pos.0 >= 0
                    && pos.1 >= 0
                    && pos.0 < data.len() as i32
                    && pos.1 < data[0].len() as i32
                {
                    let neib_state = State {
                        position: (pos.0 as usize, pos.1 as usize),
                        direction: dir,
                    };
                    Some((neib_state, data[pos.0 as usize][pos.1 as usize]))
                } else {
                    None
                }
            })
            .collect()
    }
}

fn is_opposite_direction(dir1: Direction, dir2: Direction) -> bool {
    match dir1 {
        Direction::Right => dir2 == Direction::Left,
        Direction::Left => dir2 == Direction::Right,
        Direction::Down => dir2 == Direction::Up,
        Direction::Up => dir2 == Direction::Down,
        Direction::None => false,
    }
}
