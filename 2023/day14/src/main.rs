use memoize::memoize;
use std::fs::File;
use std::io::{self, BufRead, BufReader, Write};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day14/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let data: Vec<Vec<char>> = reader
        .lines()
        .map(|l| {
            let input = l.unwrap();
            return input.chars().collect();
        })
        .collect();

    // roll to north
    let data_after_roll = roll_to_north(&data);

    // calc total load
    let part1_result = calc_total_load(&data_after_roll);

    println!("Part1: {}", part1_result);

    // Part 2
    let mut updated_data: Vec<Vec<char>> = data.to_owned();
    let mut results: Vec<u64> = vec![];
    for _ in 0..1_000 {
        results.push(calc_total_load(&updated_data));
        updated_data = spin_cycle(updated_data);
    }
    // find cycle in the data and calculate the result based on this cycle
    // 1 2 1 2 1; cycle: 1, 2
    // result after 3 cycles has index 3
    // result value = start + (full_index - start) % len ==
    // == 1 + (3 - 1) % 2 == 1
    match find_cycle(&results) {
        Some((start, len)) => {
            let result_idx = start + (1_000_000_000 - start) % len;
            println!("Part2 result: {}", results[result_idx]);
        }
        None => println!("No cycle in the results list"),
    }

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

fn find_cycle(data: &Vec<u64>) -> Option<(usize, usize)> {
    for start in 0..data.len() {
        for len in 1..(data.len() / 2) {
            if is_cycle(data, start, len) {
                return Some((start, len));
            }
        }
    }
    return None;
}

fn is_cycle(data: &Vec<u64>, start: usize, len: usize) -> bool {
    if (data.len() - start) % len != 0 {
        return false;
    }

    let cycles_count = (data.len() - start) / len;

    for i in 0..len {
        for j in 1..cycles_count {
            if data[start + j * len + i] != data[start + i] {
                // not a cycle
                return false;
            }
        }
    }
    return true;
}

#[memoize]
fn spin_cycle(data: Vec<Vec<char>>) -> Vec<Vec<char>> {
    let north = roll_to_north(&data);
    let west = roll_to_west(&north);
    let south = roll_to_south(&west);
    let east = roll_to_east(&south);
    return east;
}

fn roll_to_north(data: &Vec<Vec<char>>) -> Vec<Vec<char>> {
    // for each column move all round stones
    // upwards untill the edge or sharp rock
    let mut result: Vec<Vec<char>> = vec![vec!['.'; data[0].len()]; data.len()];
    for j in 0..data[0].len() {
        for i in 0..data.len() {
            if data[i][j] == 'O' {
                // find the correct row for the stone
                let mut new_i = i;
                while new_i > 0 && result[new_i - 1][j] == '.' {
                    new_i -= 1;
                }
                // put the stone into result
                result[new_i][j] = 'O';
            } else {
                result[i][j] = data[i][j];
            }
        }
    }

    return result;
}
fn roll_to_west(data: &Vec<Vec<char>>) -> Vec<Vec<char>> {
    // for each row move all round stones
    // to the left untill the edge or sharp rock
    let mut result: Vec<Vec<char>> = vec![vec!['.'; data[0].len()]; data.len()];
    for i in 0..data.len() {
        for j in 0..data[0].len() {
            if data[i][j] == 'O' {
                // find the correct col for the stone
                let mut new_j = j;
                while new_j > 0 && result[i][new_j - 1] == '.' {
                    new_j -= 1;
                }
                // put the stone into result
                result[i][new_j] = 'O';
            } else {
                result[i][j] = data[i][j];
            }
        }
    }

    return result;
}
fn roll_to_south(data: &Vec<Vec<char>>) -> Vec<Vec<char>> {
    // for each column
    // move all round stones (starting from the last row)
    // downwards untill the edge or sharp rock
    let mut result: Vec<Vec<char>> = vec![vec!['.'; data[0].len()]; data.len()];
    for j in 0..data[0].len() {
        for i in (0..data.len()).rev() {
            if data[i][j] == 'O' {
                // find the correct row for the stone
                let mut new_i = i;
                while new_i < data.len() - 1 && result[new_i + 1][j] == '.' {
                    new_i += 1;
                }
                // put the stone into result
                result[new_i][j] = 'O';
            } else {
                result[i][j] = data[i][j];
            }
        }
    }

    return result;
}
fn roll_to_east(data: &Vec<Vec<char>>) -> Vec<Vec<char>> {
    // for each row move all round stones
    // to the right until the edge or sharp rock
    let mut result: Vec<Vec<char>> = vec![vec!['.'; data[0].len()]; data.len()];
    for i in 0..data.len() {
        for j in (0..data[0].len()).rev() {
            if data[i][j] == 'O' {
                // find the correct col for the stone
                let mut new_j = j;
                while new_j < data[0].len() - 1 && result[i][new_j + 1] == '.' {
                    new_j += 1;
                }
                // put the stone into result
                result[i][new_j] = 'O';
            } else {
                result[i][j] = data[i][j];
            }
        }
    }

    return result;
}

fn calc_total_load(data: &Vec<Vec<char>>) -> u64 {
    let mut result = 0;
    for i in 0..data.len() {
        let coeff = (data.len() - i) as u64;
        for j in 0..data[i].len() {
            if data[i][j] == 'O' {
                result += coeff;
            }
        }
    }
    return result;
}

fn print_state(data: &Vec<Vec<char>>) -> () {
    data.iter().for_each(|row| {
        let str: String = row.iter().collect();
        println!("{str}");
    });
    println!();
}
