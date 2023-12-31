use std::fs::File;
use std::collections::{HashSet, HashMap};
use std::io::{self, BufRead, BufReader};

fn str_to_set(input: &str) -> HashSet<i32> {
    return input.split_whitespace()
        .map(|s| i32::from_str_radix(s, 10).unwrap())
        .collect();
}

fn calc_points(winning: &HashSet<i32>, owned: &HashSet<i32>) -> i32 {
    // find equal numbers in both parts and calc the result
    let intersected = winning.intersection(owned).count() as u32;

    return if intersected > 0 { 2i32.pow(intersected - 1) } else { 0 };
}

fn find_cards_to_copy(card_id: u32, winning: &HashSet<i32>, owned: &HashSet<i32>) -> HashSet<u32> {
    // find intersection
    let intersected = winning.intersection(owned).count() as u32;

    let mut i = 0;
    let mut result: HashSet<u32> = HashSet::new();
    while i < intersected {
        result.insert(card_id + i + 1);
        i += 1;
    }

    return result;
}

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day4/src/input.txt";

    // Open the file
    let mut file = File::open(input_path)?;
    let mut reader = BufReader::new(file);

    // part1
    let mut part1_result = 0;
    for line in reader.lines() {
        let data = line?;
        let parts: Vec<&str> = data.trim_start_matches("Card ").split(&[':', '|'][..]).map(|x| x.trim()).collect();
        let winning = str_to_set(parts[1]) ;
        let owned = str_to_set(parts[2]);
        let points = calc_points(&winning, &owned);
        part1_result += points;
    }
    println!("{}", part1_result);

    // part2
    let mut card_ids: HashMap<u32, u32> = HashMap::new();
    file = File::open(input_path)?;
    reader = BufReader::new(file);
    for line in reader.lines() {
        let data = line?;
        let parts: Vec<&str> = data.trim_start_matches("Card ").split(&[':', '|'][..]).map(|x| x.trim()).collect();
        let card_id = u32::from_str_radix(parts[0], 10).unwrap();
        let winning = str_to_set(parts[1]);
        let owned = str_to_set(parts[2]);
        // add the original card to the card_ids
        card_ids.entry(card_id).and_modify(|val| *val += 1).or_insert(1);
        // find what cards will be copied
        let cards_to_copy = find_cards_to_copy(card_id, &winning, &owned);
        // multiply by the number of instances of the current card
        let curr_number = card_ids[&card_id];
        // insert new copies into card_ids
        for id in cards_to_copy {
            card_ids.entry(id).and_modify(|val| *val += curr_number).or_insert(curr_number);
        }
    }
    let cards_total = card_ids.iter().fold(0, |acc, (_k, v)| acc + v);
    println!("{}", cards_total);

    return Ok(());
}
