use std::fs::File;
use std::io::{self, BufRead, BufReader};

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day9/src/input.txt";

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let data: Vec<Vec<i32>> = reader
        .lines()
        .map(|l| {
            let input = l.unwrap();
            let seq: Vec<i32> = input
                .split_whitespace()
                .map(|x| i32::from_str_radix(x, 10).unwrap())
                .collect();
            return seq;
        })
        .collect();

    let extrapolations: Vec<(i32, i32)> = data.iter().map(|seq| extrapolate(seq)).collect();
    let sums = extrapolations
        .iter()
        .fold((0, 0), |(acc_first, acc_last), (x_first, x_last)| {
            (acc_first + x_first, acc_last + x_last)
        });

    println!("Part1: {}", sums.1);

    // Part2
    println!("Part2: {}", sums.0);

    return Ok(());
}

fn extrapolate(seq: &Vec<i32>) -> (i32, i32) {
    // build subsequences until we got all zeroes
    let mut curr: Vec<i32> = seq.to_owned();
    let mut last_elems: Vec<i32> = vec![];
    let mut first_elems: Vec<i32> = vec![];
    loop {
        first_elems.push(*curr.first().unwrap());
        last_elems.push(*curr.last().unwrap());
        if is_all_zeroes(&curr) {
            break;
        }

        curr = build_subsequence(&curr);
    }

    // rollup subsequences to find the next value
    first_elems.reverse();
    last_elems.reverse();
    let first = first_elems.iter().fold(0, |acc, x| x - acc);
    let last = last_elems.iter().fold(0, |acc, x| x + acc);
    return (first, last);
}

fn is_all_zeroes(seq: &Vec<i32>) -> bool {
    seq.iter().all(|x| *x == 0)
}

fn build_subsequence(previous: &Vec<i32>) -> Vec<i32> {
    let mut result: Vec<i32> = vec![];
    for i in 0..(previous.len() - 1) {
        result.push(previous[i + 1] - previous[i]);
    }
    return result;
}
