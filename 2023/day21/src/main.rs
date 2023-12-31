use std::collections::{HashMap, HashSet};
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day21/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let mut data: Vec<Vec<char>> = vec![];
    for line in reader.lines() {
        let l = line?;
        data.push(l.chars().collect());
    }

    // Part1
    let start_pos = find_start(&data);
    let mut cache = HashMap::new();
    let positions = get_positions_after_steps(&data, vec![start_pos], 64, &mut cache);
    println!("Part1: {:?}", positions.len());

    // Part2
    let mut infinite_cache: HashMap<(i32, i32), Vec<(i32, i32)>> = HashMap::new();
    let infinite_start_pos = (start_pos.0 as i32, start_pos.1 as i32);
    let mut increments: Vec<i32> = vec![];
    get_increments_by_steps(
        &data,
        vec![infinite_start_pos],
        500,
        &mut infinite_cache,
        &mut increments,
    );
    println!("{increments:?}");
    let part2_result = find_sum(&increments, 26501365);
    println!("Part2: {}", part2_result);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

fn find_start(data: &Vec<Vec<char>>) -> (usize, usize) {
    for i in 0..data.len() {
        for j in 0..data[0].len() {
            if data[i][j] == 'S' {
                return (i, j);
            }
        }
    }
    (0, 0)
}

fn get_positions_after_steps(
    data: &Vec<Vec<char>>,
    curr_positions: Vec<(usize, usize)>,
    steps_left: i32,
    cache: &mut HashMap<(usize, usize), Vec<(usize, usize)>>,
) -> Vec<(usize, usize)> {
    if steps_left == 0 {
        return curr_positions;
    }

    let mut next_positions: HashSet<(usize, usize)> = HashSet::new();
    for curr_pos in curr_positions.iter() {
        for neib in get_neibs(data, &curr_pos, cache) {
            next_positions.insert(neib);
        }
    }

    return get_positions_after_steps(
        data,
        next_positions.iter().map(|x| (x.0, x.1)).collect(),
        steps_left - 1,
        cache,
    );
}

fn get_increments_by_steps(
    data: &Vec<Vec<char>>,
    curr_positions: Vec<(i32, i32)>,
    steps_left: i32,
    cache: &mut HashMap<(i32, i32), Vec<(i32, i32)>>,
    result: &mut Vec<i32>,
) -> () {
    if steps_left == 0 {
        return;
    }

    let mut next_positions: HashSet<(i32, i32)> = HashSet::new();
    for curr_pos in curr_positions.iter() {
        // transpose
        let transposed = transpose(*curr_pos, data.len() as i32, data[0].len() as i32);
        for neib in get_infinite_neibs(data, &transposed, cache) {
            // transpose backwards
            let retransposed_neib = (
                neib.0 + (curr_pos.0 - transposed.0),
                neib.1 + (curr_pos.1 - transposed.1),
            );
            next_positions.insert(retransposed_neib);
        }
    }

    result.push((next_positions.len() - curr_positions.len()) as i32);
    get_increments_by_steps(
        data,
        next_positions.iter().map(|x| (x.0, x.1)).collect(),
        steps_left - 1,
        cache,
        result,
    );
}

fn get_neibs(
    data: &Vec<Vec<char>>,
    pos: &(usize, usize),
    cache: &mut HashMap<(usize, usize), Vec<(usize, usize)>>,
) -> Vec<(usize, usize)> {
    if cache.contains_key(pos) {
        return cache.get(pos).unwrap().to_owned();
    }
    let mut result: Vec<(usize, usize)> = vec![];
    if pos.0 > 0 && data[pos.0 - 1][pos.1] != '#' {
        result.push((pos.0 - 1, pos.1));
    }
    if pos.0 < data.len() - 1 && data[pos.0 + 1][pos.1] != '#' {
        result.push((pos.0 + 1, pos.1));
    }
    if pos.1 > 0 && data[pos.0][pos.1 - 1] != '#' {
        result.push((pos.0, pos.1 - 1));
    }
    if pos.1 < data[0].len() - 1 && data[pos.0][pos.1 + 1] != '#' {
        result.push((pos.0, pos.1 + 1));
    }
    cache.insert(*pos, result.to_owned());
    result
}

fn get_infinite_neibs(
    data: &Vec<Vec<char>>,
    pos: &(i32, i32),
    cache: &mut HashMap<(i32, i32), Vec<(i32, i32)>>,
) -> Vec<(i32, i32)> {
    if cache.contains_key(pos) {
        return cache.get(pos).unwrap().to_owned();
    }
    let mut result: Vec<(i32, i32)> = vec![];
    if pos.0 > 0 && data[pos.0 as usize - 1][pos.1 as usize] != '#'
        || pos.0 == 0 && data[data.len() - 1][pos.1 as usize] != '#'
    {
        result.push((pos.0 - 1, pos.1));
    }
    if (pos.0 as usize) < data.len() - 1 && data[pos.0 as usize + 1][pos.1 as usize] != '#'
        || pos.0 as usize == data.len() - 1 && data[0][pos.1 as usize] != '#'
    {
        result.push((pos.0 + 1, pos.1));
    }
    if pos.1 > 0 && data[pos.0 as usize][pos.1 as usize - 1] != '#'
        || pos.1 == 0 && data[pos.0 as usize][data[0].len() - 1] != '#'
    {
        result.push((pos.0, pos.1 - 1));
    }
    if (pos.1 as usize) < data[0].len() - 1 && data[pos.0 as usize][pos.1 as usize + 1] != '#'
        || pos.1 as usize == data[0].len() - 1 && data[pos.0 as usize][0] != '#'
    {
        result.push((pos.0, pos.1 + 1));
    }
    cache.insert(*pos, result.to_owned());
    result
}

fn transpose(curr_pos: (i32, i32), height: i32, width: i32) -> (i32, i32) {
    let mut result = curr_pos.to_owned();
    while result.0 < 0 {
        result.0 += height;
    }
    while result.0 >= height {
        result.0 -= height;
    }
    while result.1 < 0 {
        result.1 += width;
    }
    while result.1 >= width {
        result.1 -= width;
    }
    return result;
}

fn find_sum(increments: &Vec<i32>, last_step: i32) -> u64 {
    // find lengh of a cycle by going from end and looking for an arithmetic progression
    let mut sum = 1u64;
    let cycle_len = find_cycle_len(increments);
    println!("Cycle len: {cycle_len}");
    // sum everything until the beginning of the cycle
    let first_cycle_idx = increments.len() - cycle_len;
    println!("Cycle start idx: {first_cycle_idx}");
    sum += increments
        .iter()
        .take(first_cycle_idx)
        .map(|x| *x as u64)
        .sum::<u64>();

    let first_hundred = increments.iter().take(100).map(|x| *x as u64).sum::<u64>() + 1;
    println!("First hundred steps: {first_hundred}");
    // for each element in the cycle find the sum of the arithmetic progression
    for i in 0..cycle_len {
        let first_idx = first_cycle_idx + i;
        let difference = increments[first_idx] - increments[first_idx - cycle_len];
        let number_of_elements =
            ((last_step - 1 - first_idx as i32) / (cycle_len as i32) + 1) as u64;
        sum += (number_of_elements as u64)
            * (2u64 * increments[first_idx] as u64 + (number_of_elements - 1) * difference as u64)
            / 2;
    }

    sum
}

fn find_cycle_len(sequence: &Vec<i32>) -> usize {
    let last_idx = sequence.len() - 1;
    for l in 1..sequence.len() / 3 {
        if sequence[last_idx] - sequence[last_idx - l]
            == sequence[last_idx - l] - sequence[last_idx - 2 * l]
            && sequence[last_idx - 1] - sequence[last_idx - 1 - l]
                == sequence[last_idx - 1 - l] - sequence[last_idx - 1 - 2 * l]
        {
            return l;
        }
    }
    return 0;
}
