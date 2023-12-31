use core::panic;
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

use petgraph::dot::Dot;
use petgraph::stable_graph::{NodeIndex, StableUnGraph};

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day23/src/input.txt";

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
    let (start_j, _) = data[0]
        .iter()
        .enumerate()
        .find(|&(_, ch)| *ch == '.')
        .unwrap();
    let (end_j, _) = data[data.len() - 1]
        .iter()
        .enumerate()
        .find(|&(_, ch)| *ch == '.')
        .unwrap();
    println!(
        "Start: ({},{}), end: ({},{})",
        0,
        start_j,
        data.len() - 1,
        end_j
    );
    let max_path_len = find_max_path(
        (0, start_j),
        (data.len() - 1, end_j),
        &HashSet::new(),
        &data,
    );
    let part1_result = max_path_len - 1; // do not count starting position
    println!("Part1: {:?}", part1_result);

    // Part2
    let graph = build_graph(&data);

    // println!("{:?}", Dot::new(&graph));

    let part2_result = find_max_path_ignoring_slopes(
        graph.node_indices().next().unwrap(),
        graph.node_indices().last().unwrap(),
        &HashSet::new(),
        &graph,
    )
    .unwrap();
    println!("Part2: {}", part2_result);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

fn find_max_path(
    start: (usize, usize),
    end: (usize, usize),
    visited: &HashSet<(usize, usize)>,
    data: &Vec<Vec<char>>,
) -> u32 {
    if start == end {
        return 1;
    }

    let mut new_visited = visited.to_owned();
    new_visited.insert(start);

    // get not visited neighbors
    let neibs = get_neighbors(start, &new_visited, data);

    // calc longest path for each of them
    match neibs
        .iter()
        .map(|x| find_max_path(*x, end, &new_visited, data))
        .max()
    {
        Some(value) => 1 + value,
        None => 0,
    }
    // choose max and return the result
}

fn get_neighbors(
    node: (usize, usize),
    visited: &HashSet<(usize, usize)>,
    data: &Vec<Vec<char>>,
) -> Vec<(usize, usize)> {
    let mut candidates: Vec<(i32, i32)> = vec![];
    match data[node.0][node.1] {
        '.' => {
            candidates.push((node.0 as i32 - 1, node.1 as i32));
            candidates.push((node.0 as i32, node.1 as i32 + 1));
            candidates.push((node.0 as i32 + 1, node.1 as i32));
            candidates.push((node.0 as i32, node.1 as i32 - 1));
        }
        '^' => candidates.push((node.0 as i32 - 1, node.1 as i32)),
        '>' => candidates.push((node.0 as i32, node.1 as i32 + 1)),
        'v' => candidates.push((node.0 as i32 + 1, node.1 as i32)),
        '<' => candidates.push((node.0 as i32, node.1 as i32 - 1)),
        _ => panic!("Wrong tile"),
    }

    // filter candidates by coordinate values, visited and cell type
    return candidates
        .iter()
        .filter(|x| x.0 >= 0 && x.1 < data.len() as i32 && x.1 >= 0 && x.1 < data[0].len() as i32)
        .map(|&x| (x.0 as usize, x.1 as usize))
        .filter(|x| !visited.contains(x) && data[x.0][x.1] != '#')
        .collect();
}

fn find_max_path_ignoring_slopes(
    curr: NodeIndex,
    end: NodeIndex,
    visited: &HashSet<NodeIndex>,
    graph: &StableUnGraph<(usize, usize), u32>,
) -> Option<u32> {
    if curr == end {
        return Some(0);
    }

    let mut new_visited = visited.to_owned();
    new_visited.insert(curr);

    // get not visited neighbors
    let neibs = graph
        .neighbors_undirected(curr)
        .filter(|n| !visited.contains(n))
        .collect::<Vec<NodeIndex>>();

    // calc longest path for each of them
    neibs
        .iter()
        .map(|x| {
            let (edge, _) = graph.find_edge_undirected(curr, *x).unwrap();
            let dist_to_neib = graph.edge_weight(edge).unwrap().to_owned();

            match find_max_path_ignoring_slopes(*x, end, &new_visited, graph) {
                Some(value) => Some(dist_to_neib + value),
                None => None,
            }
        })
        .filter_map(|x| x)
        .max()
}

fn get_neighbors_ignoring_slopes(
    node: (usize, usize),
    visited: &HashSet<(usize, usize)>,
    data: &Vec<Vec<char>>,
) -> Vec<(usize, usize)> {
    let candidates: Vec<(i32, i32)> = vec![
        (node.0 as i32 - 1, node.1 as i32),
        (node.0 as i32, node.1 as i32 + 1),
        (node.0 as i32 + 1, node.1 as i32),
        (node.0 as i32, node.1 as i32 - 1),
    ];

    // filter candidates by coordinate values, visited and cell type
    return candidates
        .iter()
        .filter(|x| x.0 >= 0 && x.1 < data.len() as i32 && x.1 >= 0 && x.1 < data[0].len() as i32)
        .map(|&x| (x.0 as usize, x.1 as usize))
        .filter(|x| !visited.contains(x) && data[x.0][x.1] != '#')
        .collect();
}

fn print_path(data: &Vec<Vec<char>>, path: &Vec<(usize, usize)>) {
    for i in 0..data.len() {
        for j in 0..data[0].len() {
            if path.contains(&(i, j)) {
                print!("0");
            } else {
                print!("{}", data[i][j]);
            }
        }
        println!();
    }
}

fn build_graph(data: &Vec<Vec<char>>) -> StableUnGraph<(usize, usize), u32> {
    let mut g: StableUnGraph<(usize, usize), u32> = StableUnGraph::default();
    // Add noodes
    let mut nodes: HashMap<(usize, usize), NodeIndex> = HashMap::new();
    for i in 0..data.len() {
        for j in 0..data[0].len() {
            if data[i][j] != '#' {
                let n = g.add_node((i, j));
                nodes.insert((i, j), n);
            }
        }
    }

    // Add edges
    for i in 0..data.len() {
        for j in 0..data[0].len() {
            if data[i][j] != '#' {
                let node = nodes.get(&(i, j)).unwrap();
                if i > 0 && data[i - 1][j] != '#' {
                    let other = nodes.get(&(i - 1, j)).unwrap();
                    g.add_edge(*node, *other, 1);
                }
                if j > 0 && data[i][j - 1] != '#' {
                    let other = nodes.get(&(i, j - 1)).unwrap();
                    g.add_edge(*node, *other, 1);
                }
            }
        }
    }

    // Simplify the graph - remove connecting nodes
    // For every node that has only two neighbors
    // remove it and connect the neighbors
    let mut queue: VecDeque<(NodeIndex, NodeIndex)> = VecDeque::new();
    let mut visited: HashSet<NodeIndex> = HashSet::new();
    let start_node = g.node_indices().next().unwrap();
    for start_neib in g.neighbors(start_node) {
        queue.push_back((start_node, start_neib));
    }
    visited.insert(start_node);

    while let Some((prev, curr)) = queue.pop_front() {
        let next_nodes: Vec<NodeIndex> = g.neighbors(curr).filter(|n| *n != prev).collect();
        if next_nodes.len() == 1 {
            // If only two neibs (prev and next) - remove current and attach next to prev
            let (edge_to_prev, _) = g.find_edge_undirected(curr, prev).unwrap();
            let prev_weight = g.edge_weight(edge_to_prev).unwrap().to_owned();
            let next = next_nodes.iter().next().unwrap();
            let (edge_to_next, _) = g.find_edge_undirected(curr, *next).unwrap();
            let next_weight = g.edge_weight(edge_to_next).unwrap().to_owned();
            g.remove_node(curr);
            g.add_edge(prev, *next, prev_weight + next_weight);

            if !visited.contains(next) {
                visited.insert(*next);
                queue.push_back((prev, *next));
            }
        } else {
            for next in next_nodes.iter().filter(|n| !visited.contains(n)) {
                // push all neibs, with prev = current
                queue.push_back((curr, *next));
            }
        }
    }

    return g;
}
