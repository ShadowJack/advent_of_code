use core::panic;
use std::collections::{HashMap, VecDeque};
use std::fs::File;
use std::io::{self, BufRead, BufReader};

#[derive(Copy, Clone)]
enum Instruction {
    Left,
    Right,
}

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day8/src/input.txt";

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let mut reader = BufReader::new(file);
    let mut buf = String::from("");
    let _ = reader.read_line(&mut buf);
    let input_instructions: Vec<Instruction> = buf
        .trim()
        .chars()
        .map(|ch| match ch {
            'L' => Instruction::Left,
            'R' => Instruction::Right,
            _ => panic!("Wrong instruction"),
        })
        .collect();
    let _ = reader.read_line(&mut buf); // skip one line
    let mut network: HashMap<String, (String, String)> = HashMap::new();
    for line in reader.lines() {
        let data = line?;
        let parts: Vec<&str> = data.split('=').map(|s| s.trim()).collect();
        let rest: Vec<&str> = parts[1]
            .trim_matches(|c| c == '(' || c == ')')
            .split(',')
            .map(|s| s.trim())
            .collect();
        network.insert(
            parts[0].to_owned(),
            (rest[0].to_owned(), rest[1].to_owned()),
        );
    }

    // go from start to finish
    let part1_result = get_steps_to_finish("AAA", &|x| x == "ZZZ", &input_instructions, &network);
    println!("Part1: {part1_result}");

    // Part2
    let individual_steps: Vec<u64> = network
        .keys()
        .filter_map(|s| {
            if s.ends_with('A') {
                Some(get_steps_to_finish(
                    &s.as_str(),
                    &|x| x.ends_with('Z'),
                    &input_instructions,
                    &network,
                ))
            } else {
                None
            }
        })
        .collect();

    let part2_result = individual_steps.iter().fold(1, |acc, x| lcm(acc, *x));
    println!("Part2: {part2_result}");

    return Ok(());
}

fn get_steps_to_finish(
    start: &str,
    is_end: &dyn Fn(&str) -> bool,
    input_instructions: &Vec<Instruction>,
    network: &HashMap<String, (String, String)>,
) -> u64 {
    let mut curr = start;
    let mut result = 0u64;
    let mut instructions: VecDeque<Instruction> = VecDeque::new();
    instructions.extend(input_instructions.iter().copied());
    while !is_end(curr) {
        result += 1;
        let op = instructions.pop_front().unwrap();

        let choises = match network.get(curr) {
            Some(value) => value,
            None => break,
        };
        curr = match op {
            Instruction::Left => &choises.0,
            Instruction::Right => &choises.1,
        };

        instructions.push_back(op);
    }
    return result;
}

fn gcd(a: u64, b: u64) -> u64 {
    let mut a = a;
    let mut b = b;
    while b != 0 {
        let temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

fn lcm(a: u64, b: u64) -> u64 {
    if a == 0 || b == 0 {
        0
    } else {
        (a / gcd(a, b)) * b
    }
}
