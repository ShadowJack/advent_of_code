use std::fs::File;
use std::io::{self, BufRead, BufReader};

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day6/src/input.txt";

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let mut reader = BufReader::new(file);
    let mut buf = String::from("");
    let _ = reader.read_line(&mut buf);
    let times: Vec<u64> = buf
        .trim_start_matches("Time:")
        .trim()
        .split_whitespace()
        .map(|x| u64::from_str_radix(x, 10).unwrap())
        .collect();
    let part2_time =
        u64::from_str_radix(&buf.trim_start_matches("Time:").trim().replace(" ", ""), 10).unwrap();

    buf.clear();
    let _ = reader.read_line(&mut buf);
    let distances: Vec<u64> = buf
        .trim_start_matches("Distance:")
        .trim()
        .split_whitespace()
        .map(|x| u64::from_str_radix(x, 10).unwrap())
        .collect();
    let part2_distance = u64::from_str_radix(
        &buf.trim_start_matches("Distance:").trim().replace(" ", ""),
        10,
    )
    .unwrap();

    let part1_result = times
        .iter()
        .zip(distances.iter())
        .map(|x| calc_win_conditions(*x.0, *x.1))
        .reduce(|acc, x| acc * x);
    println!("Part1: {:?}", part1_result);

    let part2_result = calc_win_conditions(part2_time, part2_distance);
    println!("Part2: {:?}", part2_result);

    return Ok(());
}

fn calc_win_conditions(race_time: u64, record: u64) -> u64 {
    let mut hold_time = record / race_time;
    // find starting win condition
    while calc_distance(hold_time, race_time) <= record && hold_time < race_time {
        hold_time += 1;
    }
    let start = hold_time;

    hold_time += 1;
    // find ending win condition
    while calc_distance(hold_time, race_time) > record && hold_time < race_time {
        hold_time += 1;
    }
    let end = hold_time;

    // println!("Start: {}, end: {}", start, end);

    return if start <= end { end - start } else { 0 };
}

fn calc_distance(hold_time: u64, race_time: u64) -> u64 {
    return hold_time * (race_time - hold_time);
}
