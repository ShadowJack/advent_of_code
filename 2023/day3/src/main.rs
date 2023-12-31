use std::fs::File;
use std::io::{self, BufRead, BufReader};

fn is_near_symbol(data: &Vec<Vec<char>>, i: isize, j: isize) -> bool {
    let near_cells = [
        (-1, -1), (-1, 0), (-1, 1),
        (0, -1), (0, 0), (0, 1),
        (1, -1), (1, 0), (1, 1)
    ];
    for (i_mod, j_mod) in near_cells {
        if i as isize + i_mod >= 0
            && i + i_mod < data.len() as isize
            && j + j_mod >= 0
            && j + j_mod < data[0].len() as isize
            && !data[(i + i_mod) as usize][(j + j_mod) as usize].is_digit(10)
            && data[(i + i_mod) as usize][(j + j_mod) as usize] != '.' {
            return true;
        }
    }

    return false;
}

// Find all numbers that are adjacent to the current cell
fn get_nearby_numbers(data: &Vec<Vec<char>>, i: isize, j: isize) -> Vec<u32> {
    let near_cells = [
        (-1, -1), (-1, 0), (-1, 1),
        (0, -1), (0, 0), (0, 1),
        (1, -1), (1, 0), (1, 1)
    ];

    let mut number_starts = vec![];
    for (i_mod, j_mod) in near_cells {
        if i + i_mod >= 0
            && i + i_mod < data.len() as isize
            && j + j_mod >= 0
            && j + j_mod < data[0].len() as isize
            && data[(i + i_mod) as usize][(j + j_mod) as usize].is_digit(10) {
                // move left until we meet the first non-digit character or the beginning of string
                let mut start_j = j + j_mod;
                while start_j >= 0 && data[(i + i_mod) as usize][start_j as usize].is_digit(10) {
                    start_j -= 1;
                }
                if !number_starts.iter().any(|ns| *ns == (i + i_mod, start_j + 1)) {
                    number_starts.push((i + i_mod, start_j + 1))
                }
            }
    }

    // convert number starts to the numbers
    return number_starts.iter().map(|ns| {
        let mut j = ns.1;
        let mut str = String::from("");
        while j < data[0].len() as isize && data[ns.0 as usize][j as usize].is_digit(10) {
            str.push(data[ns.0 as usize][j as usize]);
            j += 1;
        }
        return u32::from_str_radix(&str, 10).unwrap();
    }).collect();
}


fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day3/src/input.txt";

    // Open the file
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);

    // Collect the data into two-dimensional array
    let mut data: Vec<Vec<char>> = vec![];
    for line in reader.lines() {
        data.push(line?.chars().collect());
    }

    // part 1
    // Line per line character per character collect part numbers
    let mut total_num_parts = 0;
    let mut i = 0;
    while i < data.len() {
        let mut j = 0;
        let mut curr_number = String::from("");
        let mut is_part_number = false;
        while j < data[i].len() {
            if data[i][j].is_digit(10) {
                curr_number.push(data[i][j]);
                // check if there's a symbol nearby
                if !is_part_number && is_near_symbol(&data, i as isize, j as isize) {
                    is_part_number = true;
                }
            } else {
                // finish the current number and increase the total
                // if it was a part number
                if is_part_number && !curr_number.is_empty() {
                    total_num_parts += i32::from_str_radix(&curr_number, 10).unwrap();
                }
                curr_number.clear();
                is_part_number = false;
            }
            j += 1;
        }
        // the case when the part number is in the end of line
        if is_part_number && !curr_number.is_empty() {
            total_num_parts += i32::from_str_radix(&curr_number, 10).unwrap();
        }
        i += 1;
    }

    // part 2
    // check every star character - how many part numbers are nearby?
    let mut total_gear_ratios = 0;
    let mut i = 0;
    while i < data.len() {
        let mut j = 0;
        while j < data[i].len() {
            if data[i][j] == '*' {
                let near_numbers = get_nearby_numbers(&data, i as isize, j as isize);
                if near_numbers.len() == 2 {
                    total_gear_ratios += near_numbers[0] * near_numbers[1];
                }
            }
            j += 1;
        }
        i += 1;
    }


    println!("Part1: {}, part2: {}", total_num_parts, total_gear_ratios);
    Ok(())
}
