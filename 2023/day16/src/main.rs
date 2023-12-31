use core::panic;
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day16/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let data: Vec<Vec<char>> = reader
        .lines()
        .map(|l| {
            let input = l.unwrap();
            let seq: Vec<char> = input.chars().collect();
            return seq;
        })
        .collect();

    let energized = energize(&data, (0, 0), BeamDirection::FromLeft);

    let part1_result = calc_energized(&energized);
    println!("Part1: {}", part1_result);

    // Part 2
    let mut part2_result = 0;
    for i in 0..data.len() {
        let left = calc_energized(&energize(&data, (i, 0), BeamDirection::FromLeft));
        let right = calc_energized(&energize(
            &data,
            (i, data.len() - 1),
            BeamDirection::FromRight,
        ));
        if left > part2_result {
            part2_result = left;
        }
        if right > part2_result {
            part2_result = right;
        }
    }
    for j in 0..data[0].len() {
        let top = calc_energized(&energize(&data, (0, j), BeamDirection::FromTop));
        let bottom = calc_energized(&energize(
            &data,
            (data.len() - 1, j),
            BeamDirection::FromBottom,
        ));
        if top > part2_result {
            part2_result = top;
        }
        if bottom > part2_result {
            part2_result = bottom;
        }
    }
    println!("Part2: {}", part2_result);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

#[derive(Clone, Copy, Debug, PartialEq)]
enum BeamDirection {
    FromLeft, // beam is moving from left to right
    FromTop,
    FromRight,
    FromBottom,
}

#[derive(Clone, Debug)]
struct EnergizedTile {
    kind: char,
    incoming_beams: Vec<BeamDirection>,
}

fn energize(
    data: &Vec<Vec<char>>,
    start: (usize, usize),
    direction: BeamDirection,
) -> Vec<Vec<EnergizedTile>> {
    let mut result: Vec<Vec<EnergizedTile>> = data
        .iter()
        .map(|row| {
            row.iter()
                .map(|ch| EnergizedTile {
                    kind: *ch,
                    incoming_beams: vec![],
                })
                .collect()
        })
        .collect();

    result[start.0][start.1].incoming_beams.push(direction);
    do_energize(&mut result, start);

    return result;
}

fn do_energize(data: &mut Vec<Vec<EnergizedTile>>, coords: (usize, usize)) -> () {
    let tile = &data[coords.0][coords.1];
    let last_beam = *tile.incoming_beams.last().unwrap();
    let dimensions = (data.len(), data[0].len());
    let next_directions = get_next_directions(tile.kind, last_beam);
    for next_dir in next_directions.iter() {
        match get_next_coords(coords, *next_dir, dimensions) {
            Some(c) => {
                if !data[c.0][c.1].incoming_beams.contains(next_dir) {
                    data[c.0][c.1].incoming_beams.push(*next_dir);
                    do_energize(data, c);
                }
            }
            None => (),
        }
    }
}

fn get_next_directions(tile_kind: char, curr_direction: BeamDirection) -> Vec<BeamDirection> {
    match tile_kind {
        '.' => vec![curr_direction],
        '\\' => match curr_direction {
            BeamDirection::FromLeft => vec![BeamDirection::FromTop],
            BeamDirection::FromTop => vec![BeamDirection::FromLeft],
            BeamDirection::FromRight => vec![BeamDirection::FromBottom],
            BeamDirection::FromBottom => vec![BeamDirection::FromRight],
        },
        '/' => match curr_direction {
            BeamDirection::FromLeft => vec![BeamDirection::FromBottom],
            BeamDirection::FromTop => vec![BeamDirection::FromRight],
            BeamDirection::FromRight => vec![BeamDirection::FromTop],
            BeamDirection::FromBottom => vec![BeamDirection::FromLeft],
        },
        '|' => match curr_direction {
            BeamDirection::FromLeft => vec![BeamDirection::FromBottom, BeamDirection::FromTop],
            BeamDirection::FromTop => vec![BeamDirection::FromTop],
            BeamDirection::FromRight => vec![BeamDirection::FromBottom, BeamDirection::FromTop],
            BeamDirection::FromBottom => vec![BeamDirection::FromBottom],
        },
        '-' => match curr_direction {
            BeamDirection::FromLeft => vec![BeamDirection::FromLeft],
            BeamDirection::FromTop => vec![BeamDirection::FromLeft, BeamDirection::FromRight],
            BeamDirection::FromRight => vec![BeamDirection::FromRight],
            BeamDirection::FromBottom => vec![BeamDirection::FromLeft, BeamDirection::FromRight],
        },
        _ => panic!("Unknown tile"),
    }
}

fn get_next_coords(
    curr: (usize, usize),
    direction: BeamDirection,
    dimensions: (usize, usize),
) -> Option<(usize, usize)> {
    let next_coords: (i32, i32) = match direction {
        BeamDirection::FromLeft => (curr.0 as i32, curr.1 as i32 + 1),
        BeamDirection::FromTop => (curr.0 as i32 + 1, curr.1 as i32),
        BeamDirection::FromRight => (curr.0 as i32, curr.1 as i32 - 1),
        BeamDirection::FromBottom => (curr.0 as i32 - 1, curr.1 as i32),
    };
    // verify that we're in bounds
    if next_coords.0 >= 0
        && next_coords.0 < dimensions.0 as i32
        && next_coords.1 >= 0
        && next_coords.1 < dimensions.1 as i32
    {
        Some((next_coords.0 as usize, next_coords.1 as usize))
    } else {
        None
    }
}

fn calc_energized(data: &Vec<Vec<EnergizedTile>>) -> u64 {
    let result: u64 = data
        .iter()
        .map(|row| {
            row.iter()
                .fold(0, |acc, t| if t.incoming_beams.is_empty() {acc} else {acc + 1} as u64)
        })
        .sum();
    result
}
