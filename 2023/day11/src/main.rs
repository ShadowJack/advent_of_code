use std::fs::File;
use std::io::{self, BufRead, BufReader};

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day11/src/input.txt";

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let data: Vec<Vec<bool>> = reader
        .lines()
        .map(|l| {
            let input = l.unwrap();
            let seq: Vec<bool> = input.chars().map(|ch| ch == '#').collect();
            return seq;
        })
        .collect();

    // expand the universe
    let part1_data = expand_universe(&data);

    // find galaxies's coordinates
    let galaxies = get_galaxies(&part1_data);
    // calc the shortest distances for each pair of galaxies
    let part1_result = calc_sum_of_distances(&galaxies);

    println!("Part1: {}", part1_result);

    // Part2
    let mut part2_galaxies = get_galaxies(&data);
    update_galaxies_after_expasion(&data, &mut part2_galaxies);
    let part2_result = calc_sum_of_distances(&part2_galaxies);

    println!("Part2: {}", part2_result);

    return Ok(());
}

fn expand_universe(data: &Vec<Vec<bool>>) -> Vec<Vec<bool>> {
    let mut tmp: Vec<Vec<bool>> = vec![];
    // double empty rows
    for row in data.iter() {
        tmp.push(row.to_owned());
        if row.iter().all(|x| *x == false) {
            tmp.push(row.to_owned());
        }
    }

    // double empty columns
    let mut result: Vec<Vec<bool>> = tmp.iter().map(|_| vec![]).collect();

    for j in 0..tmp[0].len() {
        let mut is_empty = true;
        for i in 0..tmp.len() {
            result[i].push(tmp[i][j]);
            if tmp[i][j] == true {
                is_empty = false;
            }
        }

        if is_empty {
            // insert another column
            for i in 0..tmp.len() {
                result[i].push(false);
            }
        }
    }

    return result;
}

#[derive(Clone, Copy)]
struct Coords(usize, usize);

fn get_galaxies(data: &Vec<Vec<bool>>) -> Vec<Coords> {
    let mut result: Vec<Coords> = vec![];
    for (i, row) in data.iter().enumerate() {
        for (j, val) in row.iter().enumerate() {
            if *val == true {
                result.push(Coords(i, j));
            }
        }
    }
    return result;
}

fn calc_sum_of_distances(galaxies: &Vec<Coords>) -> u64 {
    // get all pairs
    let mut pairs: Vec<(Coords, Coords)> = vec![];
    for (i, g1) in galaxies.iter().enumerate() {
        for g2 in galaxies[i + 1..].iter() {
            pairs.push((g1.to_owned(), g2.to_owned()));
        }
    }

    // for each pair calc the distance
    return pairs.iter().fold(0, |acc, &(g1, g2)| {
        let distance = g2.0.abs_diff(g1.0) + g2.1.abs_diff(g1.1);

        return acc + distance as u64;
    });
}

// Apply 1000000 expansion to the coordinates of the galaxies
fn update_galaxies_after_expasion(universe: &Vec<Vec<bool>>, galaxies: &mut Vec<Coords>) -> () {
    // find empty rows
    let mut empty_rows: Vec<usize> = vec![];
    for (i, row) in universe.iter().enumerate() {
        if row.iter().all(|x| *x == false) {
            empty_rows.push(i);
        }
    }
    // find empty columns
    let mut empty_columns: Vec<usize> = vec![];
    for j in 0..universe[0].len() {
        let mut is_empty = true;
        for i in 0..universe.len() {
            if universe[i][j] == true {
                is_empty = false;
                break;
            }
        }

        if is_empty {
            // insert another column
            empty_columns.push(j);
        }
    }

    // update coordinates of the galaxies according
    // to the number of empty rows and columns before them
    galaxies.iter_mut().for_each(|g| {
        let empty_rows_before = empty_rows.iter().filter(|i| **i < g.0).count();
        let empty_cols_before = empty_columns.iter().filter(|j| **j < g.1).count();

        g.0 += 999999 * empty_rows_before;
        g.1 += 999999 * empty_cols_before;
    });
}
