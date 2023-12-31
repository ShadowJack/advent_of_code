use std::collections::{HashMap, HashSet, VecDeque};
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

use petgraph::stable_graph::{EdgeIndex, NodeIndex, StableUnGraph};
use petgraph::visit::Bfs;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day25/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let mut graph: StableUnGraph<String, ()> = StableUnGraph::default();
    let mut nodes: HashMap<String, NodeIndex> = HashMap::new();
    let mut edges: HashMap<(NodeIndex, NodeIndex), EdgeIndex> = HashMap::new();
    for line in reader.lines() {
        let l = line?;
        let curr_nodes: Vec<NodeIndex> = l
            .split_whitespace()
            .map(|x| {
                let trimmed = x.trim_matches(':');
                match nodes.get(trimmed) {
                    Some(idx) => *idx,
                    None => {
                        let idx = graph.add_node(trimmed.to_string());
                        nodes.insert(trimmed.to_string(), idx);
                        idx
                    }
                }
            })
            .collect();
        for i in 1..curr_nodes.len() {
            let edge_index = graph.add_edge(curr_nodes[0], curr_nodes[i], ());
            edges.insert((curr_nodes[0], curr_nodes[i]), edge_index);
            edges.insert((curr_nodes[i], curr_nodes[0]), edge_index);
        }
    }

    // Part1
    let top_3_edges = get_top_3_edges(&graph);
    println!(
        "Top 3 edges: {:?}",
        top_3_edges
            .iter()
            .map(|id| {
                let (n1, n2) = graph.edge_endpoints(*id).unwrap();
                (
                    graph.node_weight(n1).unwrap(),
                    graph.node_weight(n2).unwrap(),
                )
            })
            .collect::<Vec<(&String, &String)>>()
    );
    let (part1, part2) = get_splitted_graph(&graph, &top_3_edges);
    // println!("Part1: {part1:?}, part2: {part2:?}");
    let part1_result = part1.len() * part2.len();
    println!("Part1: {:?}", part1_result);

    // Part2
    let part2_result = 0;
    println!("Part2: {}", part2_result);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

fn get_top_3_edges(graph: &StableUnGraph<String, ()>) -> Vec<EdgeIndex> {
    let mut edge_paths: HashMap<EdgeIndex, u32> =
        HashMap::from_iter(graph.edge_indices().map(|i| (i, 0)));
    for node_id in graph.node_indices() {
        // Start BFS and increase the counter for each visited edge
        let mut visited: HashSet<NodeIndex> = HashSet::new();
        let mut queue: VecDeque<NodeIndex> = VecDeque::new();
        queue.push_back(node_id);
        visited.insert(node_id);

        while let Some(curr_idx) = queue.pop_front() {
            let neibs = graph
                .neighbors(curr_idx)
                .filter(|n| !visited.contains(n))
                .collect::<Vec<NodeIndex>>();
            for neib in neibs {
                queue.push_back(neib);
                visited.insert(neib);
                let edge = graph.find_edge(curr_idx, neib).unwrap();
                edge_paths.entry(edge).and_modify(|x| *x += 1);
            }
        }
    }

    let mut ordered_edges = edge_paths
        .iter()
        .map(|x| (*x.0, *x.1))
        .collect::<Vec<(EdgeIndex, u32)>>();
    ordered_edges.sort_by_key(|x| x.1);
    ordered_edges.reverse();
    ordered_edges
        .iter()
        .take(3)
        .map(|x| x.0)
        .collect::<Vec<EdgeIndex>>()
}

fn get_splitted_graph(
    graph: &StableUnGraph<String, ()>,
    top_3_edges: &Vec<EdgeIndex>,
) -> (HashSet<NodeIndex>, HashSet<NodeIndex>) {
    let mut splitted_graph = graph.clone();
    for edge_id in top_3_edges {
        let _ = splitted_graph.remove_edge(*edge_id);
    }

    let (start1, start2) = graph.edge_endpoints(top_3_edges[0]).unwrap();

    let mut part1: HashSet<NodeIndex> = HashSet::new();
    let mut part2: HashSet<NodeIndex> = HashSet::new();

    let mut bfs = Bfs::new(&splitted_graph, start1);
    while let Some(id) = bfs.next(&splitted_graph) {
        part1.insert(id);
    }
    bfs = Bfs::new(&splitted_graph, start2);
    while let Some(id) = bfs.next(&splitted_graph) {
        part2.insert(id);
    }

    (part1, part2)
}
