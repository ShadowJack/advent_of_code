use core::panic;
use std::collections::{HashMap, HashSet};
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

use vecmath::{vec3_add, vec3_cross, vec3_dot, vec3_sub};

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day24/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let mut data: Vec<Hailstone> = vec![];
    for line in reader.lines() {
        let l = line?;
        data.push(Hailstone::from_str(&l));
    }
    // println!("{data:?}");

    // Part1
    // let test_area = (7f64, 27f64);
    let test_area = (200000000000000f64, 400000000000000f64);
    let crossings = find_crossings(&data, test_area);
    // println!("{crossings:?}");
    let part1_result = crossings.len();
    println!("Part1: {:?}", part1_result);

    // Part2
    let line = find_line_crossing_all(&data.iter().map(|x| x.to_int()).collect());
    println!("Line: {line:?}");
    let part2_result = line.x + line.y + line.z;
    println!("Part2: {}", part2_result);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

#[derive(Debug, Clone, Copy, PartialEq)]
struct Hailstone {
    x: f64,
    y: f64,
    z: f64,
    vx: f64,
    vy: f64,
    vz: f64,
    k: f64,
    b: f64,
}

#[derive(Debug, Clone, Copy, PartialEq)]
struct HailstoneInt {
    x: i128,
    y: i128,
    z: i128,
    vx: i128,
    vy: i128,
    vz: i128,
}

impl HailstoneInt {
    fn adjust(&self, vx_adj: i128, vy_adj: i128, vz_adj: i128) -> HailstoneInt {
        HailstoneInt {
            x: self.x,
            y: self.y,
            z: self.z,
            vx: self.vx - vx_adj,
            vy: self.vy - vy_adj,
            vz: self.vz - vz_adj,
        }
    }

    fn is_parallel(&self, other: &HailstoneInt) -> bool {
        let vec_cross = vec3_cross([self.vx, self.vy, self.vz], [other.vx, other.vy, other.vz]);
        return vec_cross[0] == 0 && vec_cross[1] == 0 && vec_cross[2] == 0;
    }

    fn is_crossing_3d(&self, other: &HailstoneInt) -> bool {
        let vec_cross = vec3_cross([self.vx, self.vy, self.vz], [other.vx, other.vy, other.vz]);
        if vec_cross[0] == 0 && vec_cross[1] == 0 && vec_cross[2] == 0 {
            return false;
        }
        let diff = vec3_sub([other.x, other.y, other.z], [self.x, self.y, self.z]);
        vec3_dot(vec_cross, diff) == 0
    }

    fn cross_point_3d(&self, other: &HailstoneInt) -> Option<(i128, i128, i128)> {
        if !self.is_crossing_3d(other) {
            return None;
        }

        let s = (self.vy * (other.x - self.x) - self.vx * (other.y - self.y))
            / (self.vx * other.vy - self.vy * other.vx);
        let result = vec3_add(
            [other.x, other.y, other.z],
            [s * other.vx, s * other.vy, s * other.vz],
        );
        Some((result[0], result[1], result[2]))
    }
}

impl Hailstone {
    fn identity() -> Hailstone {
        Hailstone {
            x: 0.0,
            y: 0.0,
            z: 0.0,
            vx: 0.0,
            vy: 0.0,
            vz: 0.0,
            k: 0.0,
            b: 0.0,
        }
    }

    fn from_str(input: &str) -> Hailstone {
        let parts: Vec<Vec<&str>> = input
            .split('@')
            .map(|x| x.trim().split(',').map(|y| y.trim()).collect())
            .collect();
        let x = i128::from_str_radix(parts[0][0], 10).unwrap() as f64;
        let y = i128::from_str_radix(parts[0][1], 10).unwrap() as f64;
        let z = i128::from_str_radix(parts[0][2], 10).unwrap() as f64;
        let vx = i128::from_str_radix(parts[1][0], 10).unwrap() as f64;
        let vy = i128::from_str_radix(parts[1][1], 10).unwrap() as f64;
        let vz = i128::from_str_radix(parts[1][2], 10).unwrap() as f64;
        let k = vy / vx;
        let b = y - k * x;

        Hailstone {
            x,
            y,
            z,
            vx,
            vy,
            vz,
            k,
            b,
        }
    }

    fn from_pair(p1: (f64, f64, f64), p2: (f64, f64, f64)) -> Hailstone {
        Hailstone {
            x: p1.0,
            y: p1.1,
            z: p1.2,
            vx: p2.0 - p1.0,
            vy: p2.1 - p1.1,
            vz: p2.2 - p1.2,
            k: 0.0,
            b: 0.0,
        }
    }

    fn to_int(&self) -> HailstoneInt {
        HailstoneInt {
            x: self.x as i128,
            y: self.y as i128,
            z: self.z as i128,
            vx: self.vx as i128,
            vy: self.vy as i128,
            vz: self.vz as i128,
        }
    }

    fn adjust(&self, vx_adj: i32, vy_adj: i32, vz_adj: i32) -> Hailstone {
        Hailstone {
            x: self.x,
            y: self.y,
            z: self.z,
            vx: self.vx - vx_adj as f64,
            vy: self.vy - vy_adj as f64,
            vz: self.vz - vz_adj as f64,
            k: self.k,
            b: self.b,
        }
    }

    fn is_parallel(&self, other: &Hailstone) -> bool {
        let vec_cross = vec3_cross([self.vx, self.vy, self.vz], [other.vx, other.vy, other.vz]);
        return vec_cross[0] < f64::EPSILON
            && vec_cross[1] < f64::EPSILON
            && vec_cross[2] < f64::EPSILON;
    }

    fn is_crossing_3d(&self, other: &Hailstone) -> bool {
        let vec_cross = vec3_cross([self.vx, self.vy, self.vz], [other.vx, other.vy, other.vz]);
        if vec_cross[0] < f64::EPSILON && vec_cross[1] < f64::EPSILON && vec_cross[2] < f64::EPSILON
        {
            return false;
        }
        let diff = vec3_sub([other.x, other.y, other.z], [self.x, self.y, self.z]);
        vec3_dot(vec_cross, diff) < f64::EPSILON
    }

    fn cross_point_3d(&self, other: &Hailstone) -> Option<(f64, f64, f64)> {
        if !self.is_crossing_3d(other) {
            return None;
        }

        let s = (self.vy * (other.x - self.x) - self.vx * (other.y - self.y))
            / (self.vx * other.vy - self.vy * other.vx);
        let result = vec3_add(
            [other.x, other.y, other.z],
            [s * other.vx, s * other.vy, s * other.vz],
        );
        Some((result[0], result[1], result[2]))
    }

    fn is_crossing_3d_all(&self, data: &Vec<Hailstone>) -> bool {
        for i in 0..data.len() {
            if !self.is_crossing_3d(&data[i]) {
                return false;
            }
        }
        return true;
    }
}

fn find_crossings(data: &Vec<Hailstone>, test_area: (f64, f64)) -> Vec<(f64, f64)> {
    let mut result: Vec<(f64, f64)> = vec![];
    for i in 0..data.len() {
        for j in (i + 1)..data.len() {
            match get_crossing(&data[i], &data[j], test_area) {
                Some(value) => result.push(value),
                None => (),
            }
        }
    }

    result
}

fn get_crossing(
    first: &Hailstone,
    second: &Hailstone,
    test_area: (f64, f64),
) -> Option<(f64, f64)> {
    if first.k == second.k {
        // lines are parallel
        return None;
    }
    let candidate_x = (second.b - first.b) / (first.k - second.k);
    let candidate_y = (first.k * second.b - first.b * second.k) / (first.k - second.k);

    if candidate_x < test_area.0
        || candidate_x > test_area.1
        || candidate_y < test_area.0
        || candidate_y > test_area.1
    {
        return None;
    }

    // check that the point is in positive direction
    // from the start of each trace
    if (candidate_x - first.x) / first.vx <= 0f64 {
        return None;
    }
    if (candidate_y - first.y) / first.vy <= 0f64 {
        return None;
    }
    if (candidate_x - second.x) / second.vx <= 0f64 {
        return None;
    }
    if (candidate_y - second.y) / second.vy <= 0f64 {
        return None;
    }

    return Some((candidate_x, candidate_y));
}

fn find_line_crossing_all(data: &Vec<HailstoneInt>) -> HailstoneInt {
    //let adjusted = find_adjusted_hailstone(data);
    let adjusted = HailstoneInt {
        x: 159153037374407i128,
        y: 228139153674672i128,
        z: 170451316297300i128,
        vx: 245,
        vy: 75,
        vz: 221,
    };
    let time = (adjusted.x - data[0].x) / (data[0].vx - adjusted.vx);
    println!("Time: {time}");
    HailstoneInt {
        x: data[0].x + (data[0].vx - adjusted.vx) * time,
        y: data[0].y + (data[0].vy - adjusted.vy) * time,
        z: data[0].z + (data[0].vz - adjusted.vz) * time,
        vx: adjusted.vx,
        vy: adjusted.vy,
        vz: adjusted.vz,
    }
}

fn find_adjusted_hailstone(data: &Vec<HailstoneInt>) -> HailstoneInt {
    for vx in -1000..1000 {
        for vy in -1000..1000 {
            for vz in -1000..1000 {
                let adjusted_hailstones: Vec<HailstoneInt> =
                    data.iter().map(|h| h.adjust(vx, vy, vz)).collect();
                if let Some(point) = all_intersecting_in_one_point_int(&adjusted_hailstones) {
                    println!("Found velocity: {vx}, {vy}, {vz}");
                    println!("Cross point: {point:?}");
                    return HailstoneInt {
                        x: point.0,
                        y: point.1,
                        z: point.2,
                        vx,
                        vy,
                        vz,
                    };
                }
            }
        }
    }
    HailstoneInt {
        x: 0,
        y: 0,
        z: 0,
        vx: 0,
        vy: 0,
        vz: 0,
    }
}

fn find_line_crossing_all_backup(data: &Vec<Hailstone>) -> Hailstone {
    let mut crosses: Vec<(f64, f64, f64)> = vec![];
    for i in 0..data.len() {
        for j in (i + 1)..data.len() {
            if let Some(cross) = data[i].cross_point_3d(&data[j]) {
                crosses.push(cross);
            }
        }
    }
    println!("{} crosses found", crosses.len());
    println!("{crosses:?}");

    let mut lines: Vec<Hailstone> = vec![];
    for i in 0..crosses.len() {
        for j in (i + 1)..crosses.len() {
            lines.push(Hailstone::from_pair(crosses[i], crosses[j]));
        }
    }
    for line in lines {
        if line.is_crossing_3d_all(data) {
            println!("We found the line: {line:?}");
            return line;
        }
    }
    panic!("No line is found!");
}

fn get_candidates(
    data: &Vec<Hailstone>,
    excluded: HashSet<usize>,
) -> ((usize, usize, usize), (f64, f64, f64), (f64, f64, f64)) {
    // find three lines so that one of them crosses two others,
    // but others aren't crossing each other
    for i in 0..data.len() {
        if excluded.contains(&i) {
            continue;
        }
        for j in 0..data.len() {
            if excluded.contains(&j) {
                continue;
            }
            if let Some(cross1) = data[i].cross_point_3d(&data[j]) {
                // i and j are crossing - look for the line
                // that crosses exactly one of them
                for k in 0..data.len() {
                    if k == i || k == j || excluded.contains(&k) {
                        continue;
                    }
                    if data[i].is_crossing_3d(&data[k])
                        && !data[j].is_crossing_3d(&data[k])
                        && !data[j].is_parallel(&data[k])
                    {
                        let cross2 = data[i].cross_point_3d(&data[k]).unwrap();
                        return ((i, j, k), cross1, cross2);
                    }
                    if data[j].is_crossing_3d(&data[k])
                        && !data[i].is_crossing_3d(&data[k])
                        && !data[i].is_parallel(&data[k])
                    {
                        let cross2 = data[j].cross_point_3d(&data[k]).unwrap();
                        return ((j, i, k), cross1, cross2);
                    }
                }
            }
        }
    }

    panic!("No such lines");
}

fn all_intersecting_in_one_point_int(data: &Vec<HailstoneInt>) -> Option<(i128, i128, i128)> {
    for i in 0..data.len() {
        for j in (i + 1)..data.len() {
            if !data[i].is_crossing_3d(&data[j]) {
                return None;
            }
        }
    }
    println!("Found all crossing");
    return data[0].cross_point_3d(&data[1]);
}

fn all_insecting_in_one_point(data: &Vec<Hailstone>) -> Option<(f64, f64, f64)> {
    for i in 0..data.len() {
        for j in (i + 1)..data.len() {
            if !data[i].is_crossing_3d(&data[j]) {
                return None;
            }
        }
    }
    return data[0].cross_point_3d(&data[1]);
}
