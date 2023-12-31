use std::fs::File;
use std::io::{self, BufRead, BufReader};

struct Game {
    id: u32,
    sets: Vec<GameSet>
}

struct GameSet {
    red: u8,
    green: u8,
    blue: u8,
}

impl Game {
    fn is_valid(&self) -> bool {
        return self.sets.iter().all(|s| s.is_valid());
    }

    fn get_power(&self) -> u32 {
        let mut red: u8 = 0;
        let mut green: u8 = 0;
        let mut blue: u8 = 0;
        for GameSet{red: r, green: g, blue: b} in self.sets.iter() {
            if *r > red { red = *r; }
            if *g > green { green = *g; }
            if *b > blue { blue = *b; }
        }
        return u32::from(red) * u32::from(green) * u32::from(blue);
    }
}

impl GameSet {
    fn is_valid(&self) -> bool {
        // valid if it has not more than 12 red cubes, 13 green cubes, and 14 blue cubes
        return self.red <= 12 && self.green <= 13 && self.blue <= 14;
    }
}

fn parse_game(input: &str) -> Game {
    let (game_id, other) = input
        .trim_start_matches("Game ")
        .split_once(":")
        .unwrap();
    return Game {
        id: u32::from_str_radix(game_id, 10).unwrap(),
        sets: other.split(";").map(|set| parse_game_set(set)).collect()
    };
}

fn parse_game_set(input: &str) -> GameSet {
    let mut red = 0u8;
    let mut green = 0u8;
    let mut blue = 0u8;
    let parts = input.split(",").map(|x| x.trim());
    for part in parts {
        let (num, color) = part.split_once(" ").unwrap();
        match color {
            "red" => red = u8::from_str_radix(num, 10).unwrap(),
            "green" => green = u8::from_str_radix(num, 10).unwrap(),
            "blue" => blue = u8::from_str_radix(num, 10).unwrap(),
            _ => ()
        }
    }
    return GameSet { red, green, blue };
}

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day2/src/input.txt";

    // Open the file
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);

    let mut valid_sum = 0;
    let mut games_power = 0;
    for line in reader.lines() {
        let game_data = line?;
        let game = parse_game(&game_data);
        if game.is_valid() {
            valid_sum += game.id;
        }
        games_power += game.get_power();
    }
    println!("Part1: {}, Part2: {}", valid_sum, games_power);

    return Ok(());
}
