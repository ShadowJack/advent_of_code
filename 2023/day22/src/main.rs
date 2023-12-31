use std::cmp::min;
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day22/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let mut data: Vec<Brick> = vec![];
    for (id, line) in reader.lines().enumerate() {
        let l = line?;
        data.push(Brick::from_str(&l, id as u32));
    }

    // Part1
    let fallen = fall(&data);
    let map = fallen
        .iter()
        .map(|x| (x.id, x.to_owned()))
        .collect::<HashMap<u32, Brick>>();
    let bricks_to_desintegrate = fallen
        .iter()
        .filter(|&b| b.is_safe_to_remove(&map))
        .map(|b| b.to_owned())
        .collect::<Vec<Brick>>();
    let part1_result = bricks_to_desintegrate.iter().count();
    println!("Part1: {:?}", part1_result);

    // Part2
    let mut cache: HashMap<u32, u32> = HashMap::new();
    for b in fallen.iter() {
        b.count_cascading_bricks_count(&map, &mut cache);
    }
    let part2_result: u32 = cache.values().sum();
    println!("Part2: {}", part2_result);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct Brick {
    start: XYZ,
    end: XYZ,
    id: u32,
    supports: HashSet<u32>,
    supporters: HashSet<u32>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
struct XYZ {
    x: usize,
    y: usize,
    z: usize,
}

impl Brick {
    fn from_str(input: &String, id: u32) -> Brick {
        let parts = input.split('~').collect::<Vec<&str>>();
        let start = XYZ::from_str(parts[0]);
        let end = XYZ::from_str(parts[1]);
        Brick {
            start,
            end,
            id,
            supports: HashSet::new(),
            supporters: HashSet::new(),
        }
    }

    fn lowest_z(&self) -> usize {
        min(self.start.z, self.end.z)
    }

    fn is_vertical(&self) -> bool {
        self.start.z != self.end.z
    }

    fn is_falling(&mut self, bricks: &mut Vec<Brick>) -> (bool, HashSet<u32>) {
        if self.lowest_z() == 1 {
            return (false, HashSet::new());
        }

        // check if there's any crossing if we move down
        let mut next_pos = Brick {
            start: self.start,
            end: self.end,
            id: self.id,
            supports: HashSet::new(),
            supporters: HashSet::new(),
        };
        next_pos.start.z -= 1;
        next_pos.end.z -= 1;
        let mut supporters = HashSet::new();
        for b in bricks.iter_mut().filter(|b| b.id != self.id) {
            if next_pos.is_crossing(b) {
                b.supports.insert(self.id);
                supporters.insert(b.id);
            }
        }

        return (supporters.is_empty(), supporters);
    }

    fn is_crossing(&self, other: &Brick) -> bool {
        if self.is_vertical() && other.is_vertical() {
            let self_range = (self.lowest_z(), self.start.z.max(self.end.z));
            let other_range = (other.lowest_z(), other.start.z.max(other.end.z));
            return self.start.x == other.start.x
                && self.start.y == other.start.y
                && ranges_are_intersecting(self_range, other_range);
        }

        if !self.is_vertical() && !other.is_vertical() {
            if self.lowest_z() != other.lowest_z() {
                return false;
            }
            // check intersections on X and Y axes
            let self_x_range = (self.start.x.min(self.end.x), self.start.x.max(self.end.x));
            let other_x_range = (
                other.start.x.min(other.end.x),
                other.start.x.max(other.end.x),
            );
            let self_y_range = (self.start.y.min(self.end.y), self.start.y.max(self.end.y));
            let other_y_range = (
                other.start.y.min(other.end.y),
                other.start.y.max(other.end.y),
            );
            return ranges_are_intersecting(self_x_range, other_x_range)
                && ranges_are_intersecting(self_y_range, other_y_range);
        }

        if self.is_vertical() && !other.is_vertical() {
            if self.lowest_z() > other.lowest_z() || self.start.z.max(self.end.z) < other.lowest_z()
            {
                return false;
            }
            if self.start.x < other.start.x.min(other.end.x)
                || self.start.x > other.start.x.max(other.end.x)
            {
                return false; // no intersection on X axis
            }
            if self.start.y < other.start.y.min(other.end.y)
                || self.start.y > other.start.y.max(other.end.y)
            {
                return false; // no intersection on X axis
            }
            return true;
        } else {
            return other.is_crossing(self);
        }
    }

    fn is_safe_to_remove(&self, bricks: &HashMap<u32, Brick>) -> bool {
        // Check if any brick that we support would fall without us
        for sup_id in self.supports.iter() {
            let other = bricks.get(sup_id).unwrap();
            if other.supporters.iter().all(|s_id| *s_id == self.id) {
                return false;
            }
        }
        return true;
    }

    fn count_cascading_bricks_count(
        &self,
        bricks: &HashMap<u32, Brick>,
        cache: &mut HashMap<u32, u32>,
    ) -> u32 {
        if cache.contains_key(&self.id) {
            return cache.get(&self.id).unwrap().to_owned();
        }

        let mut result = 0;
        let mut bricks_temp = bricks.to_owned();
        let mut falling_bricks: VecDeque<u32> = VecDeque::new();
        falling_bricks.push_back(self.id);
        while let Some(brick_id) = falling_bricks.pop_front() {
            let falling_brick = bricks_temp.remove(&brick_id).unwrap();
            // find which supports are going to fall
            for sup_id in falling_brick.supports.iter() {
                bricks_temp.entry(*sup_id).and_modify(|upper| {
                    upper.supporters.remove(&brick_id);
                    if upper.supporters.is_empty() {
                        result += 1;
                        falling_bricks.push_back(upper.id);
                    }
                });
            }
        }
        cache
            .entry(self.id)
            .and_modify(|x| *x = result)
            .or_insert(result);
        return result;
    }
}

impl XYZ {
    fn from_str(input: &str) -> XYZ {
        let parts = input.split(',').collect::<Vec<&str>>();
        XYZ {
            x: usize::from_str_radix(parts[0], 10).unwrap(),
            y: usize::from_str_radix(parts[1], 10).unwrap(),
            z: usize::from_str_radix(parts[2], 10).unwrap(),
        }
    }
}

fn fall(initial_bricks: &Vec<Brick>) -> Vec<Brick> {
    let mut result: Vec<Brick> = initial_bricks.to_vec();

    // sort by Z asc
    result.sort_unstable_by(|a, b| a.lowest_z().cmp(&b.lowest_z()));

    // one by one move bricks down
    for i in 0..result.len() {
        loop {
            let (is_falling, supporters) = result[i].to_owned().is_falling(&mut result);
            if is_falling {
                result[i].start.z -= 1;
                result[i].end.z -= 1;
            } else {
                result[i].supporters = supporters;
                break;
            }
        }
    }

    return result;
}

fn ranges_are_intersecting(a: (usize, usize), b: (usize, usize)) -> bool {
    a.0 <= b.1 && b.0 <= a.1
}
