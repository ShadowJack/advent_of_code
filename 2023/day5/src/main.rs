use std::collections::VecDeque;
use std::fs::File;
use std::io::{self, BufRead, BufReader, Read};
use std::ops::Range;

struct Mapping {
    ranges: Vec<MappingRange>,
}

struct MappingRange {
    src: Range<u64>,
    dest: Range<u64>,
}

impl Mapping {
    fn from(input: &str) -> Mapping {
        let lines: Vec<&str> = input.split("\n").collect();
        let mut ranges: Vec<MappingRange> = vec![];
        for line in lines[1..].iter() {
            let parts: Vec<u64> = line
                .split_whitespace()
                .map(|x| u64::from_str_radix(x, 10).unwrap())
                .collect();
            ranges.push(MappingRange {
                src: parts[1]..parts[1] + parts[2],
                dest: parts[0]..parts[0] + parts[2],
            });
        }

        return Mapping { ranges };
    }

    fn apply(&self, values: &Vec<u64>) -> Vec<u64> {
        // for each value find where it's going to be mapped
        return values
            .iter()
            .map(|val| {
                return match self
                    .ranges
                    .iter()
                    .find(|r| (**r).src.start <= *val && *val < (**r).src.end)
                {
                    Some(range) => (*range).dest.start + (*val - (*range).src.start),
                    None => *val,
                };
            })
            .collect();
    }

    fn apply_for_ranges(&self, ranges: &Vec<Range<u64>>) -> Vec<Range<u64>> {
        if ranges.is_empty() {
            return vec![];
        }
        let mut results: Vec<Range<u64>> = vec![];
        let mut queue: VecDeque<Range<u64>> = VecDeque::from_iter(ranges.to_owned());

        let mut curr_range = queue.pop_front();
        while curr_range.is_some() {
            let rng = curr_range.unwrap();
            let mut is_processed = false;
            for map in self.ranges.iter() {
                // curr range is included entirely into the mapping range
                if map.src.start <= rng.start && rng.end <= map.src.end {
                    // push mapped range into results
                    let mapped_start = rng.start - map.src.start + map.dest.start;
                    results.push(mapped_start..mapped_start + rng.end - rng.start);
                    is_processed = true;
                    break;
                }
                // curr range is intersecting with the end of mapping range
                else if rng.end > map.src.end
                    && rng.start < map.src.end
                    && rng.start > map.src.start
                {
                    // println!(
                    //     "Curr range: {:?}; mapping from: {:?}; mapping to: {:?}",
                    //     rng, map.src, map.dest
                    // );
                    // push mapped intersection into results
                    let mapped_start = rng.start - map.src.start + map.dest.start;
                    let mapped_len = map.src.end - rng.start;
                    results.push(mapped_start..mapped_start + mapped_len);
                    is_processed = true;
                    // push the rest of the current range to the queue
                    let rest = map.src.end..rng.end;
                    queue.push_back(rest);
                    break;
                }
                // curr range is intersecting with the beginning of mapping range
                else if rng.start < map.src.start
                    && rng.end > map.src.start
                    && rng.end < map.src.end
                {
                    // push mapped intersection into results
                    let mapped_start = map.dest.start;
                    let mapped_len = rng.end - map.src.start;
                    results.push(mapped_start..mapped_start + mapped_len);
                    is_processed = true;
                    // push the rest of the current range to the queue
                    let rest = rng.start..map.src.start;
                    queue.push_back(rest);
                    break;
                }
                // curr range covers entire mapping range
                else if rng.start <= map.src.start && rng.end >= map.src.end {
                    // push mapped intersection into results
                    results.push(map.dest.start..map.dest.end);
                    is_processed = true;
                    // push two parts that left from the current range to the queue
                    let starting_range = rng.start..map.src.start;
                    if !starting_range.is_empty() {
                        queue.push_back(starting_range);
                    }
                    let ending_range = map.src.end..rng.end;
                    if !ending_range.is_empty() {
                        queue.push_back(ending_range);
                    }
                    break;
                }
                // there was no intersection - continue to the next mapping range
            }
            if !is_processed {
                // curr range is outside of all mappings - push it directly into the results
                results.push(rng);
            }
            curr_range = queue.pop_front();
        }

        return results;
    }
}

fn values_to_ranges(values: &Vec<u64>) -> Vec<Range<u64>> {
    return values.chunks(2).map(|s| s[0]..s[0] + s[1]).collect();
}

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day5/src/input.txt";

    // Part1
    // open the file
    let file = File::open(input_path)?;
    let mut reader = BufReader::new(file);

    // read input seeds
    let mut seeds_str = String::from("");
    let _ = reader.read_line(&mut seeds_str);
    let mut values: Vec<u64> = seeds_str
        .trim_start_matches("seeds: ")
        .split_whitespace()
        .map(|x| u64::from_str_radix(x, 10).unwrap())
        .collect();
    let seeds = values.to_owned();

    // read mappings info
    let mut rest = String::from("");
    let _ = reader.read_to_string(&mut rest);
    let mappings: Vec<Mapping> = rest
        .split("\n\n")
        .map(|x| Mapping::from(x.trim()))
        .collect();

    // for each mapping take input seeds and map into the next layer
    for mapping in mappings.iter() {
        values = mapping.apply(&values);
    }

    // find min location
    let part1_result = values.iter().min().unwrap();
    println!("Part1: {}", part1_result);

    // Part2
    // for each mapping transform existing ranges into the new ones
    let mut value_ranges = values_to_ranges(&seeds);
    for mapping in mappings.iter() {
        value_ranges = mapping.apply_for_ranges(&value_ranges);
    }
    // find min location
    let part2_result = value_ranges.iter().map(|x| x.start).min().unwrap();
    println!("Part2: {}", part2_result);

    return Ok(());
}
