use memoize::memoize;
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day12/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let data: Vec<(Vec<char>, Vec<u16>)> = reader
        .lines()
        .map(|l| {
            let input = l.unwrap();
            let parts: Vec<&str> = input.split_whitespace().collect();
            let row: Vec<char> = parts[0].chars().collect();
            let condition_records: Vec<u16> = parts[1]
                .split(',')
                .map(|x| u16::from_str_radix(x, 10).unwrap())
                .collect();
            return (row, condition_records);
        })
        .collect();

    let part1_result: u64 = data
        .iter()
        .map(|(row, condition_records)| {
            calc_arrangements(row.to_owned(), condition_records.to_owned())
        })
        .sum();

    println!("Part1: {}", part1_result);

    let part2_result: u64 = data
        .iter()
        .map(|(row, condition_records)| {
            let mut unfolded_row: Vec<char> = vec![];
            const CYCLES: usize = 5;
            for i in 0..CYCLES {
                unfolded_row.extend(row);
                if i < CYCLES - 1 {
                    unfolded_row.push('?');
                }
            }
            let unfolded_condition_records = condition_records.repeat(CYCLES);
            calc_arrangements(unfolded_row, unfolded_condition_records)
        })
        .sum();

    println!("Part2: {}", part2_result);
    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

#[memoize]
fn calc_arrangements(row: Vec<char>, condition_records: Vec<u16>) -> u64 {
    // println!("Row: {row:?}, conditions: {condition_records:?}");
    match condition_records.split_first() {
        Some((first_condition, rest_conditions)) => {
            // try different ways to fulfill the first condition
            // for each variant calc different ways to
            // make an arrangement with the rest of the row
            // and the rest of the condition records
            let variants = get_arrangement_variants(row.to_owned(), *first_condition);
            // println!("Variants: {variants:?}");
            return variants
                .iter()
                .map(|rest_of_row| {
                    calc_arrangements(rest_of_row.to_owned(), rest_conditions.to_vec())
                })
                .sum();
        }
        None => {
            return if has_broken(&row) { 0 } else { 1 };
        }
    }
}

// find different options to make a row that contains
// exactly `condition` broken springs in the beginning
#[memoize]
fn get_arrangement_variants(row: Vec<char>, condition: u16) -> Vec<Vec<char>> {
    let mut result: Vec<Vec<char>> = vec![];
    if row.len() == 0 {
        return result;
    }
    // 1. skip all normal springs
    let trimmed_row: Vec<char> = row
        .iter()
        .skip_while(|ch| **ch == '.')
        .map(|x| *x)
        .collect();
    if trimmed_row.is_empty() {
        return result;
    }
    if trimmed_row.starts_with(&['#']) {
        // println!("Trimmed row: {trimmed_row:?}, condition: {condition}");
        // we found the broken group - check if we can fulfill the condition
        if trimmed_row.len() == 1 {
            if condition == 1 {
                // we have the last broken spring and
                // it's fulfilling the condition
                // push the empty row as we have nothing left
                result.push(vec![]);
            }
            return result;
        }
        let mut broken_count = 0;
        for i in 0..trimmed_row.len() {
            match trimmed_row[i] {
                '.' => return vec![],
                '#' | '?' => {
                    broken_count += 1;
                    if broken_count == condition {
                        if i == trimmed_row.len() - 1 {
                            // it's the end + condition is fulfilled
                            result.push(vec![]);
                        } else if trimmed_row[i + 1] == '#' {
                            // next is # - the condition isn't fulfilled
                            // we have no variants
                        } else {
                            // next is either . or ? - treat them as .
                            result.push(trimmed_row[i + 2..].to_vec());
                        }
                        // c. else - return the only option - rest of the row
                        return result;
                    }
                }
                _ => panic!("Wrong char"),
            }
        }
        // we don't have enough broken chars
        return result;
    }

    // TODO: check the edge cases here
    // we start with ? => we have to consider two options:
    // a. it's a normal spring
    let variants_if_normal = get_arrangement_variants(trimmed_row[1..].to_vec(), condition);
    // b. it's a broken spring
    let mut modified_row = vec!['#'];
    modified_row.extend(trimmed_row[1..].to_vec());
    let variants_if_broken = get_arrangement_variants(modified_row.to_owned(), condition);
    // println!("If ok: {variants_if_normal:?}, if broken: {variants_if_broken:?}");
    result.extend(variants_if_normal);
    result.extend(variants_if_broken);

    return result;
}

fn has_broken(row: &Vec<char>) -> bool {
    row.iter().any(|ch| *ch == '#')
}

fn find_broken_groups(row: &Vec<char>) -> Vec<u16> {
    let mut result: Vec<u16> = vec![];
    let mut curr_count = 0u16;
    for ch in row.iter() {
        match ch {
            '.' | '?' => {
                if curr_count > 0 {
                    result.push(curr_count);
                }
                curr_count = 0;
            }
            '#' => curr_count += 1,
            _ => panic!("Unknown character"),
        }
    }

    return result;
}
