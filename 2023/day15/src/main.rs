use core::panic;
use regex::Regex;
use std::collections::VecDeque;
use std::fs::File;
use std::io::{self, BufReader, Read};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day15/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let mut reader = BufReader::new(file);
    let mut input: String = String::from("");
    let _ = reader.read_to_string(&mut input);
    let data: Vec<&str> = input.trim().split(',').collect();

    let part1_result = data.iter().fold(0, |acc, x| acc + calc_hash(*x));
    println!("Part1: {}", part1_result);

    // Part 2
    let init_seq = parse_initialization_sequence(&data);
    let boxes = initialize(&init_seq);
    let part2_result = calc_focusing_power(&boxes);
    println!("Part2: {}", part2_result);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

fn calc_hash(str: &str) -> u32 {
    str.chars()
        .fold(0, |acc, x| ((acc + (x as u32)) * 17) % 256)
}

fn parse_initialization_sequence(data: &Vec<&str>) -> Vec<Command> {
    let re = Regex::new(r"([a-z]+)([\=|\-])([0-9]*)").unwrap();
    data.iter()
        .map(|x| {
            let captures = re.captures(*x).unwrap();
            let label = captures.get(1).unwrap().as_str();
            let operation = captures.get(2).unwrap().as_str();
            let focal_length = captures.get(3);
            match operation {
                "=" => Command::Set(Lense {
                    label: String::from(label),
                    focal_length: u32::from_str_radix(focal_length.unwrap().as_str(), 10).unwrap(),
                }),
                "-" => Command::Remove(String::from(label)),
                _ => panic!("Unknown command"),
            }
        })
        .collect()
}

fn initialize(initialization_sequence: &Vec<Command>) -> Vec<VecDeque<Lense>> {
    let mut result: Vec<VecDeque<Lense>> = vec![VecDeque::new(); 256];
    for command in initialization_sequence.iter() {
        apply_command(command, &mut result);
    }
    return result;
}

fn apply_command(command: &Command, boxes: &mut Vec<VecDeque<Lense>>) -> () {
    match command {
        Command::Set(Lense {
            label,
            focal_length,
        }) => {
            let hash = calc_hash(&label);
            let b = boxes.get_mut(hash as usize).unwrap();
            match b.iter().position(|l| *l.label == *label) {
                // lense already present - update with new focal length
                Some(idx) => {
                    b[idx].focal_length = *focal_length;
                }
                // otherwise - add it to the end
                None => b.push_back(Lense {
                    label: label.to_owned(),
                    focal_length: *focal_length,
                }),
            }
        }
        Command::Remove(label) => {
            let hash = calc_hash(label);
            let b = boxes.get_mut(hash as usize).unwrap();
            match b.iter().position(|l| *l.label == *label) {
                // lense is present - remove it
                Some(idx) => {
                    b.remove(idx);
                }
                // otherwise - do nothing
                None => (),
            }
        }
    }
}

fn calc_focusing_power(boxes: &Vec<VecDeque<Lense>>) -> u32 {
    boxes.iter().enumerate().fold(0, |acc, (idx, b)| {
        acc + (idx as u32 + 1)
            * b.iter().enumerate().fold(0, |box_acc, (l_idx, l)| {
                box_acc + (l_idx as u32 + 1) * l.focal_length
            })
    })
}

#[derive(Clone)]
struct Lense {
    label: String,
    focal_length: u32,
}

#[derive(Clone)]
enum Command {
    Set(Lense),
    Remove(String),
}
