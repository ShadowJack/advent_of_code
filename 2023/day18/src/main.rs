use core::panic;
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day18/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let data: Vec<Command> = reader
        .lines()
        .map(|l| {
            let input = l.unwrap();
            Command::from_string(&input)
        })
        .collect();

    let trench = build_trench(&data);
    let volume = get_volume(&trench);

    println!("Part1: {:?}", volume);

    let new_data = decode_data(&data);
    let new_trench = build_trench(&new_data);
    let new_volume = get_volume(&new_trench);
    println!("Part2: {}", new_volume);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

#[derive(Debug)]
struct Command {
    direction: Direction,
    count: i64,
    code: String,
}

#[derive(Debug)]
struct Point {
    x: i64,
    y: i64,
}

#[derive(Debug)]
enum Direction {
    Up,
    Right,
    Down,
    Left,
}

impl Command {
    fn from_string(input: &str) -> Command {
        let parts: Vec<&str> = input.split_whitespace().collect();
        let direction = match parts[0].chars().next().unwrap() {
            'U' => Direction::Up,
            'R' => Direction::Right,
            'D' => Direction::Down,
            'L' => Direction::Left,
            _ => panic!("Wrong direction"),
        };
        let count = i64::from_str_radix(parts[1], 10).unwrap();
        let code = parts[2].trim_matches(|x| x == '(' || x == ')');
        Command {
            direction,
            count,
            code: String::from(code),
        }
    }
}

fn build_trench(commands: &Vec<Command>) -> Vec<Point> {
    let mut result: Vec<Point> = vec![Point { x: 0, y: 0 }];

    for command in commands.iter() {
        let prev_point = result.last().unwrap();
        let next_point = match command.direction {
            Direction::Up => Point {
                x: prev_point.x,
                y: prev_point.y + command.count,
            },
            Direction::Down => Point {
                x: prev_point.x,
                y: prev_point.y - command.count,
            },
            Direction::Right => Point {
                x: prev_point.x + command.count,
                y: prev_point.y,
            },
            Direction::Left => Point {
                x: prev_point.x - command.count,
                y: prev_point.y,
            },
        };
        result.push(next_point);
    }

    if result.last().unwrap().x == 0 && result.last().unwrap().y == 0 {
        result.pop();
    }

    return result;
}

fn get_volume(trench: &Vec<Point>) -> u64 {
    // Use Gauss's area formula
    // and also count the number of points on the boundary
    let mut surface: i64 = 0;
    let mut boundary_len: i64 = 0;
    for i in 0..trench.len() {
        let curr_point = &trench[i];
        let next_point = if i < trench.len() - 1 {
            &trench[i + 1]
        } else {
            &trench[0]
        };
        surface += curr_point.x * next_point.y - curr_point.y * next_point.x;
        boundary_len += (next_point.y - curr_point.y).abs() + (next_point.x - curr_point.x).abs();
    }
    if surface < 0 {
        surface = -surface;
    }
    surface = surface / 2;

    // find the number of points inside the boundary using Pick's theorem
    let inside_count = surface - boundary_len / 2 + 1;

    return boundary_len as u64 + inside_count as u64;
}

fn decode_data(data: &Vec<Command>) -> Vec<Command> {
    data.iter()
        .map(|old| {
            let code_chars = old.code.trim_matches('#').chars();
            let new_count_str: String = code_chars.to_owned().take(5).collect();
            let new_count = i64::from_str_radix(&new_count_str, 16).unwrap();
            let new_dir = match code_chars.skip(5).next().unwrap() {
                '0' => Direction::Right,
                '1' => Direction::Down,
                '2' => Direction::Left,
                '3' => Direction::Up,
                _ => panic!("Unknown direction code"),
            };
            Command {
                direction: new_dir,
                count: new_count,
                code: String::from(""),
            }
        })
        .collect()
}
