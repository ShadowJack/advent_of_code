use core::panic;
use std::collections::{HashSet, VecDeque};
use std::fs::File;
use std::io::{self, BufRead, BufReader};

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day10/src/input.txt";

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let mut data: Vec<Vec<char>> = reader
        .lines()
        .map(|l| {
            let input = l.unwrap();
            let seq: Vec<char> = input.chars().collect();
            return seq;
        })
        .collect();

    // find the start and go in both directions until we meet again
    let start_pos = find_start(&data);
    let mut main_loop = find_loop(&data, start_pos);

    println!("Part1: {}", main_loop.len() / 2);

    // Part2
    // update data: replace S with actual pipe
    data = replace_start_with_pipe(&data, &main_loop);
    let part2 = count_enclosed_cells(&data, &mut main_loop);
    println!("Part2: {}", part2);

    return Ok(());
}

#[derive(PartialEq, Eq, Clone, Copy, Hash, Debug)]
struct Coordinates(usize, usize);

impl Coordinates {
    fn connected_neighbors(&self, data: &Vec<Vec<char>>) -> Vec<Coordinates> {
        let mut neibs: Vec<Coordinates> = vec![];
        // top
        if self.0 > 0 && ['|', 'F', '7'].contains(&data[self.0 - 1][self.1]) {
            neibs.push(Coordinates(self.0 - 1, self.1));
        }
        // right
        if self.1 < data[0].len() - 1 && ['-', '7', 'J'].contains(&data[self.0][self.1 + 1]) {
            neibs.push(Coordinates(self.0, self.1 + 1));
        }
        // bottom
        if self.0 < data.len() - 1 && ['|', 'J', 'L'].contains(&data[self.0 + 1][self.1]) {
            neibs.push(Coordinates(self.0 + 1, self.1));
        }
        // left
        if self.1 > 0 && ['-', 'L', 'F'].contains(&data[self.0][self.1 - 1]) {
            neibs.push(Coordinates(self.0, self.1 - 1));
        }
        return neibs;
    }

    // Find the next connected pipe taking into account the previous pipe
    fn next(&self, visited: Coordinates, data: &Vec<Vec<char>>) -> (Coordinates, Coordinates) {
        let neibs = match data[self.0][self.1] {
            '|' => [
                Coordinates(self.0 - 1, self.1),
                Coordinates(self.0 + 1, self.1),
            ],
            'F' => [
                Coordinates(self.0, self.1 + 1),
                Coordinates(self.0 + 1, self.1),
            ],
            'L' => [
                Coordinates(self.0 - 1, self.1),
                Coordinates(self.0, self.1 + 1),
            ],
            'J' => [
                Coordinates(self.0 - 1, self.1),
                Coordinates(self.0, self.1 - 1),
            ],
            '-' => [
                Coordinates(self.0, self.1 - 1),
                Coordinates(self.0, self.1 + 1),
            ],
            '7' => [
                Coordinates(self.0, self.1 - 1),
                Coordinates(self.0 + 1, self.1),
            ],
            _ => panic!("Wrong neighbor"),
        };
        if neibs[0] == visited {
            (self.to_owned(), neibs[1].to_owned())
        } else {
            (self.to_owned(), neibs[0].to_owned())
        }
    }

    // Get neighbor tiles that aren't part of the main loop
    fn neib_tiles(&self, data: &Vec<Vec<char>>, main_loop: &Vec<Coordinates>) -> Vec<Coordinates> {
        let mut result: Vec<Coordinates> = vec![];
        // top
        if self.0 > 0 && !main_loop.contains(&Coordinates(self.0 - 1, self.1)) {
            result.push(Coordinates(self.0 - 1, self.1));
        }
        // right
        if self.1 < data[0].len() - 1 && !main_loop.contains(&Coordinates(self.0, self.1 + 1)) {
            result.push(Coordinates(self.0, self.1 + 1));
        }
        // bottom
        if self.0 < data.len() - 1 && !main_loop.contains(&Coordinates(self.0 + 1, self.1)) {
            result.push(Coordinates(self.0 + 1, self.1));
        }
        // left
        if self.1 > 0 && !main_loop.contains(&Coordinates(self.0, self.1 - 1)) {
            result.push(Coordinates(self.0, self.1 - 1));
        }

        return result;
    }

    fn search_enclosed_tiles(
        &self,
        data: &Vec<Vec<char>>,
        main_loop: &Vec<Coordinates>,
        visited: &mut HashSet<Coordinates>,
    ) -> u32 {
        if visited.contains(self) {
            return 0;
        }
        let mut result: u32 = 0;
        let mut queue: VecDeque<Coordinates> = VecDeque::new();
        queue.push_back(self.to_owned());
        visited.insert(self.to_owned());
        while !queue.is_empty() {
            let curr = queue.pop_front().unwrap();
            result += 1;
            let neibs: Vec<Coordinates> = curr
                .neib_tiles(data, main_loop)
                .iter()
                .filter_map(|x| {
                    if visited.contains(x) {
                        None
                    } else {
                        Some(x.to_owned())
                    }
                })
                .collect();
            for neib in neibs.iter() {
                visited.insert(neib.to_owned());
                queue.push_back(neib.to_owned());
            }
        }
        return result;
    }
}

fn find_start(data: &Vec<Vec<char>>) -> Coordinates {
    for i in 0..data.len() {
        for j in 0..data[0].len() {
            if data[i][j] == 'S' {
                return Coordinates(i, j);
            }
        }
    }
    panic!("Start is not found")
}

fn find_loop(data: &Vec<Vec<char>>, start_pos: Coordinates) -> Vec<Coordinates> {
    let mut result: Vec<Coordinates> = vec![start_pos.to_owned()];
    let neighbors = start_pos.connected_neighbors(&data);
    let mut curr: Coordinates = neighbors[0].to_owned();
    let mut prev: Coordinates = start_pos.to_owned();
    while curr != start_pos {
        result.push(curr.to_owned());
        // Go to the next pipe
        (prev, curr) = curr.next(prev, &data);
    }
    return result;
}

fn replace_start_with_pipe(data: &Vec<Vec<char>>, main_loop: &Vec<Coordinates>) -> Vec<Vec<char>> {
    let curr = main_loop[0];
    let next = main_loop[1];
    let prev = main_loop[main_loop.len() - 1];
    let new_val = if prev.0 == next.0 {
        '-'
    } else if prev.1 == next.1 {
        '|'
    } else if (prev.1 == curr.1 && next.0 == curr.0 && next.1 > curr.1 && prev.0 > curr.0)
        || (prev.0 == curr.0 && prev.1 > curr.1 && curr.0 < next.0 && curr.1 == next.1)
    {
        'F'
    } else if (prev.0 < curr.0 && prev.1 == curr.1 && curr.0 == next.0 && curr.1 < next.1)
        || (prev.0 == curr.0 && prev.1 > curr.1 && curr.0 > next.0 && curr.1 == next.1)
    {
        'L'
    } else if (prev.0 < curr.0 && prev.1 == curr.1 && curr.0 == next.0 && curr.1 > next.1)
        || (prev.0 == curr.0 && prev.1 < curr.1 && curr.0 > next.0 && curr.1 == next.1)
    {
        'J'
    } else if (prev.0 == curr.0 && prev.1 < curr.1 && curr.0 < next.0 && curr.1 == next.1)
        || (prev.0 > curr.0 && prev.1 == curr.1 && curr.0 == next.0 && curr.1 > next.1)
    {
        '7'
    } else {
        panic!("Unknown pipe")
    };
    println!("New value instead of S: {new_val}");

    let result: Vec<Vec<char>> = data
        .iter()
        .enumerate()
        .map(|(i, row)| {
            if i == curr.0 {
                let updated_row: Vec<char> = row
                    .iter()
                    .enumerate()
                    .map(|(j, val)| {
                        if j == curr.1 {
                            new_val.to_owned()
                        } else {
                            val.to_owned()
                        }
                    })
                    .collect();
                return updated_row;
            } else {
                row.to_owned()
            }
        })
        .collect();
    return result;
}

fn count_enclosed_cells(data: &Vec<Vec<char>>, main_loop: &mut Vec<Coordinates>) -> u32 {
    reorder_clockwise(data, main_loop);

    // for each pipe go right and find enclosing tiles
    let mut visited: HashSet<Coordinates> = HashSet::new();
    let mut tiles_count: u32 = 0;

    for (idx, _) in main_loop.iter().enumerate() {
        let neibs = get_right_tiles(idx, data, main_loop);
        // println!("Pipe: {:?}, Neibs: {:?}", pipe, neibs);
        for tile in neibs.iter() {
            tiles_count += tile.search_enclosed_tiles(data, main_loop, &mut visited);
        }
    }
    return tiles_count;
}

fn reorder_clockwise(data: &Vec<Vec<char>>, main_loop: &mut Vec<Coordinates>) -> () {
    // 1. find the top-left pipe
    // it's always an 'F'-corner
    let (idx, _pipe) = main_loop
        .iter()
        .enumerate()
        .min_by_key(|(_idx, &Coordinates(i, j))| i * data[0].len() + j)
        .unwrap();
    // 2. get next pipe in the loop
    let next = if idx < main_loop.len() - 1 {
        main_loop[idx + 1]
    } else {
        main_loop[0]
    };
    // 3. detect if the upper outer node was to the left from the found pipe
    // going from the pipe to the next
    let is_clockwise = match data[next.0][next.1] {
        '7' => true,
        '-' => true,
        '|' => false,
        'L' => false,
        'J' => false,
        _ => panic!("Wrong pipe value"),
    };
    // 4. if it was on the right - reverse the loop
    if !is_clockwise {
        main_loop.reverse();
    }
}

fn get_right_tiles(
    tile_idx: usize,
    data: &Vec<Vec<char>>,
    main_loop: &Vec<Coordinates>,
) -> Vec<Coordinates> {
    // Get coordinates to the right of the current pipe (in the clockwise direction)
    let curr = main_loop[tile_idx];
    let next = if tile_idx < main_loop.len() - 1 {
        main_loop[tile_idx + 1]
    } else {
        main_loop[0]
    };

    let mut result: Vec<Coordinates> = vec![];
    match data[curr.0][curr.1] {
        '-' => {
            if next.1 > curr.1 {
                result.push(Coordinates(curr.0 + 1, curr.1))
            } else {
                result.push(Coordinates(curr.0 - 1, curr.1))
            }
        }
        '7' => {
            if next.1 < curr.1 {
                result.push(Coordinates(curr.0, curr.1 + 1));
                result.push(Coordinates(curr.0 - 1, curr.1));
            }
        }
        'F' => {
            if next.0 > curr.0 {
                result.push(Coordinates(curr.0 - 1, curr.1));
                result.push(Coordinates(curr.0, curr.1 - 1));
            }
        }
        '|' => {
            if next.0 < curr.0 {
                result.push(Coordinates(curr.0, curr.1 + 1));
            } else {
                result.push(Coordinates(curr.0, curr.1 - 1));
            }
        }
        'L' => {
            if next.1 > curr.1 {
                result.push(Coordinates(curr.0, curr.1 - 1));
                result.push(Coordinates(curr.0 + 1, curr.1));
            }
        }
        'J' => {
            if next.0 < curr.0 {
                result.push(Coordinates(curr.0, curr.1 + 1));
                result.push(Coordinates(curr.0 + 1, curr.1));
            }
        }
        _ => panic!("Wrong pipe type"),
    };

    // exclude main_loop nodes from the result
    result = result
        .iter()
        .filter_map(|c| {
            if main_loop.contains(c) {
                None
            } else {
                Some(*c)
            }
        })
        .collect();
    return result;
}
