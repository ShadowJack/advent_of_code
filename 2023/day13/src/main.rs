use std::fs::File;
use std::io::{self, Read};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day13/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let mut file = File::open(input_path)?;
    let mut input = String::from("");
    let _ = file.read_to_string(&mut input);
    let patterns: Vec<Vec<&str>> = input
        .split("\n\n")
        .map(|x| {
            let rows: Vec<&str> = x.trim().split("\n").collect();
            return rows;
        })
        .collect();

    let mirrors: Vec<(u64, u64)> = patterns
        .iter()
        .map(|pattern| calc_mirror(pattern))
        .collect();
    let part1_result: u64 = mirrors.iter().map(|x| x.0).sum();

    println!("Part1: {}", part1_result);

    // Part 2
    let part2_result: u64 = mirrors.iter().map(|x| x.1).sum();

    // 300 + 100 + 400 + 300 + 0
    println!("Part2: {}", part2_result);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

fn calc_mirror(pattern: &Vec<&str>) -> (u64, u64) {
    // check rows - find two rows that are equal
    let mut row1_indices: Vec<usize> = vec![];
    for i in 0..pattern.len() - 1 {
        if pattern[i] == pattern[i + 1] {
            row1_indices.push(i);
        }
    }
    // then go backwords from the potential mirrors and check if relative mirrored rows are equal
    let part1_row_mirror = row1_indices.iter().find(|x| is_mirror_row(**x, pattern));

    // find part2 mirror indice
    let mut row2_indices: Vec<usize> = vec![];
    for i in 0..pattern.len() - 1 {
        if are_almost_equal_rows(i, i + 1, pattern) != AlmostEqual::NotEqual
            && (part1_row_mirror.is_none() || *part1_row_mirror.unwrap() != i)
        {
            row2_indices.push(i);
        }
    }
    let part2_row_mirror = row2_indices.iter().find(|x| is_mirror_row_2(**x, pattern));

    // find columns where necessary
    let mut part1_col_mirror: Option<&usize> = None;
    let mut col1_indices: Vec<usize> = vec![];
    if part1_row_mirror.is_none() {
        for j in 0..pattern[0].len() - 1 {
            if pattern
                .iter()
                .all(|row| row.as_bytes()[j] == row.as_bytes()[j + 1])
            {
                col1_indices.push(j);
            }
        }
        part1_col_mirror = col1_indices.iter().find(|x| is_mirror_col(**x, pattern));
    }

    let mut part2_col_mirror: Option<&usize> = None;
    let mut col2_indices: Vec<usize> = vec![];
    if part2_row_mirror.is_none() {
        for j in 0..pattern[0].len() - 1 {
            if are_almost_equal_cols(j, j + 1, pattern) != AlmostEqual::NotEqual
                && (part1_col_mirror.is_none() || *part1_col_mirror.unwrap() != j)
            {
                col2_indices.push(j);
            }
        }
        part2_col_mirror = col2_indices.iter().find(|x| is_mirror_col_2(**x, pattern));
    }

    let part1 = if part1_row_mirror.is_some() {
        (*part1_row_mirror.unwrap() + 1) * 100
    } else if part1_col_mirror.is_some() {
        *part1_col_mirror.unwrap() + 1
    } else {
        0
    };
    let part2 = if part2_row_mirror.is_some() {
        (*part2_row_mirror.unwrap() + 1) * 100
    } else if part2_col_mirror.is_some() {
        *part2_col_mirror.unwrap() + 1
    } else {
        0
    };
    return (part1 as u64, part2 as u64);
}

fn is_mirror_row(idx: usize, pattern: &Vec<&str>) -> bool {
    // check that all rows above and below are mirrored
    let mut upper = idx as i32;
    let mut lower = idx + 1;
    while upper >= 0 && lower < pattern.len() {
        if pattern[upper as usize] != pattern[lower] {
            return false;
        }
        upper -= 1;
        lower += 1;
    }
    return true;
}

fn is_mirror_col(idx: usize, pattern: &Vec<&str>) -> bool {
    // check that all columns to the left and right are mirrored
    let mut left = idx as i32;
    let mut right = idx + 1;
    while left >= 0 && right < pattern[0].len() {
        if pattern
            .iter()
            .any(|row| row.as_bytes()[left as usize] != row.as_bytes()[right])
        {
            return false;
        }
        left -= 1;
        right += 1;
    }
    return true;
}

// Part 2
#[derive(PartialEq, Eq)]
enum AlmostEqual {
    Equal,
    Almost,
    NotEqual,
}
fn calc_mirror_2(pattern: &Vec<&str>) -> u64 {
    // check rows - find two rows that are equal or have one smudge
    let mut mirror_indices: Vec<usize> = vec![];
    for i in 0..pattern.len() - 1 {
        if are_almost_equal_rows(i, i + 1, pattern) != AlmostEqual::NotEqual {
            mirror_indices.push(i);
        }
    }
    // then go backwords from the potential mirrors and check if relative mirrored rows are equal
    let mirror = mirror_indices
        .iter()
        .find(|x| is_mirror_row_2(**x, pattern));
    if mirror.is_some() {
        return ((mirror.unwrap() + 1) * 100) as u64;
    }

    // repeat for columns if no row-mirror is found
    mirror_indices = vec![];
    for j in 0..pattern[0].len() - 1 {
        if are_almost_equal_cols(j, j + 1, pattern) != AlmostEqual::NotEqual {
            mirror_indices.push(j);
        }
    }
    let mirror = mirror_indices
        .iter()
        .find(|x| is_mirror_col_2(**x, pattern));
    if mirror.is_some() {
        return (mirror.unwrap() + 1) as u64;
    }
    return 0;
}

fn are_almost_equal_rows(idx1: usize, idx2: usize, pattern: &Vec<&str>) -> AlmostEqual {
    if pattern[idx1] == pattern[idx2] {
        return AlmostEqual::Equal;
    }

    let mut smudge_found = false;
    for j in 0..pattern[0].len() {
        if pattern[idx1].as_bytes()[j] != pattern[idx2].as_bytes()[j] {
            if smudge_found {
                return AlmostEqual::NotEqual;
            }
            smudge_found = true;
        }
    }

    return AlmostEqual::Almost;
}

fn is_mirror_row_2(idx: usize, pattern: &Vec<&str>) -> bool {
    // check that all rows above and below are mirrored
    let mut upper = idx as i32;
    let mut lower = idx + 1;
    let mut has_smudge = false;
    while upper >= 0 && lower < pattern.len() {
        match are_almost_equal_rows(upper as usize, lower, pattern) {
            AlmostEqual::NotEqual => {
                return false;
            }
            AlmostEqual::Almost => {
                if has_smudge {
                    return false;
                } else {
                    has_smudge = true;
                }
            }
            AlmostEqual::Equal => (),
        }
        upper -= 1;
        lower += 1;
    }
    return true;
}

fn are_almost_equal_cols(idx1: usize, idx2: usize, pattern: &Vec<&str>) -> AlmostEqual {
    let mut smudge_found = false;
    for i in 0..pattern.len() {
        if pattern[i].as_bytes()[idx1] != pattern[i].as_bytes()[idx2] {
            if smudge_found {
                return AlmostEqual::NotEqual;
            }
            smudge_found = true;
        }
    }

    return if smudge_found {
        AlmostEqual::Almost
    } else {
        AlmostEqual::Equal
    };
}

fn is_mirror_col_2(idx: usize, pattern: &Vec<&str>) -> bool {
    // check that all cols are mirrored
    let mut left = idx as i32;
    let mut right = idx + 1;
    let mut has_smudge = false;
    while left >= 0 && right < pattern[0].len() {
        match are_almost_equal_cols(left as usize, right, pattern) {
            AlmostEqual::NotEqual => {
                return false;
            }
            AlmostEqual::Almost => {
                if has_smudge {
                    return false;
                } else {
                    has_smudge = true;
                }
            }
            AlmostEqual::Equal => (),
        }
        left -= 1;
        right += 1;
    }
    return true;
}
