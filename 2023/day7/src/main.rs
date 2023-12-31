use core::panic;
use std::cmp::Ordering;
use std::collections::HashMap;
use std::fs::File;
use std::io::{self, BufRead, BufReader};

struct Hand {
    cards: Vec<u8>,
    combination_rank: u8,
    bid: u32,
}

impl Hand {
    fn from_part1(input: &str) -> Hand {
        let parts: Vec<&str> = input.split_whitespace().collect();
        let cards: Vec<u8> = parts[0]
            .chars()
            .map(|ch| match ch {
                'A' => 14,
                'K' => 13,
                'Q' => 12,
                'J' => 11,
                'T' => 10,
                '9' => 9,
                '8' => 8,
                '7' => 7,
                '6' => 6,
                '5' => 5,
                '4' => 4,
                '3' => 3,
                '2' => 2,
                _ => panic!("Unexpected card value"),
            })
            .collect();

        let mut card_counts: HashMap<u8, u8> = HashMap::new();
        for c in cards.iter() {
            card_counts.entry(*c).and_modify(|x| *x += 1).or_insert(1);
        }
        let combination_rank = if card_counts.len() == 5 {
            1 // high card
        } else if card_counts.len() == 4 {
            2 // one pair
        } else if card_counts.len() == 3 && card_counts.iter().any(|x| *x.1 == 3) {
            4 // three of a kind
        } else if card_counts.len() == 3 {
            3 // two pairs
        } else if card_counts.len() == 2 && card_counts.iter().any(|x| *x.1 == 4) {
            6 // four of a kind
        } else if card_counts.len() == 2 {
            5 // full house
        } else {
            7 // five of a kind
        };

        return Hand {
            cards,
            combination_rank,
            bid: u32::from_str_radix(parts[1], 10).unwrap(),
        };
    }

    fn from_part2(input: &str) -> Hand {
        let parts: Vec<&str> = input.split_whitespace().collect();
        let cards: Vec<u8> = parts[0]
            .chars()
            .map(|ch| match ch {
                'A' => 13,
                'K' => 12,
                'Q' => 11,
                'T' => 10,
                '9' => 9,
                '8' => 8,
                '7' => 7,
                '6' => 6,
                '5' => 5,
                '4' => 4,
                '3' => 3,
                '2' => 2,
                'J' => 1,
                _ => panic!("Unexpected card value"),
            })
            .collect();

        let mut card_counts: HashMap<u8, u8> = HashMap::new();
        for c in cards.iter() {
            card_counts.entry(*c).and_modify(|x| *x += 1).or_insert(1);
        }
        // print!("Cards: {:?} => ", card_counts);
        // apply jokers
        if card_counts.contains_key(&1) {
            let jokers_count = card_counts.remove_entry(&1).unwrap().1.to_owned();
            let max_pair = match card_counts.iter().max_by_key(|x| *x.1) {
                Some(pair) => pair,
                None => (&2, &5),
            }
            .to_owned();
            card_counts
                .entry(*max_pair.0)
                .and_modify(|x| *x += jokers_count)
                .or_insert(jokers_count);
        }
        // println!("{:?}", card_counts);

        let combination_rank = if card_counts.len() == 5 {
            1 // high card
        } else if card_counts.len() == 4 {
            2 // one pair
        } else if card_counts.len() == 3 && card_counts.iter().any(|x| *x.1 == 3) {
            4 // three of a kind
        } else if card_counts.len() == 3 {
            3 // two pairs
        } else if card_counts.len() == 2 && card_counts.iter().any(|x| *x.1 == 4) {
            6 // four of a kind
        } else if card_counts.len() == 2 {
            5 // full house
        } else {
            7 // five of a kind
        };

        return Hand {
            cards,
            combination_rank,
            bid: u32::from_str_radix(parts[1], 10).unwrap(),
        };
    }

    fn cmp(&self, other: &Hand) -> Ordering {
        // Compare ranks of combinations
        let combination_cmp = self.combination_rank.cmp(&other.combination_rank);
        return match combination_cmp {
            // if combinations of equal rank - compare cards one by one
            Ordering::Equal => self
                .cards
                .iter()
                .zip(other.cards.iter())
                .find_map(|x| match x.0.cmp(x.1) {
                    Ordering::Equal => None,
                    other => Some(other),
                })
                .unwrap(),
            other => other,
        };
    }
}

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day7/src/input.txt";

    // Part1
    // open the file and parse input
    let mut file = File::open(input_path)?;
    let mut reader = BufReader::new(file);
    let mut inputs: Vec<Hand> = reader
        .lines()
        .map(|l| Hand::from_part1(&l.unwrap()))
        .collect();

    // sort hands by their relative score
    inputs.sort_unstable_by(|a, b| a.cmp(b));

    // calc result
    let part1_total_winnings = inputs
        .iter()
        .enumerate()
        .fold(0u32, |acc, (i, h)| acc + h.bid * (i + 1) as u32);
    println!("Part1: {:?}", part1_total_winnings);

    // Part2
    file = File::open(input_path)?;
    reader = BufReader::new(file);
    inputs = reader
        .lines()
        .map(|l| Hand::from_part2(&l.unwrap()))
        .collect();

    // sort hands by their relative score
    inputs.sort_unstable_by(|a, b| a.cmp(b));

    // calc result
    let part2_total_winnings = inputs
        .iter()
        .enumerate()
        .fold(0u32, |acc, (i, h)| acc + h.bid * (i + 1) as u32);
    println!("Part2: {:?}", part2_total_winnings);

    return Ok(());
}
