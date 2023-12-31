use std::collections::{HashMap, VecDeque};
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day20/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);
    let mut modules: HashMap<String, Module> = HashMap::new();
    for line in reader.lines() {
        let l = line?;
        let module = Module::from_str(&l);
        modules.insert(module.id.to_owned(), module);
    }

    init_conjunction_modules(&mut modules);

    // Part1
    // let mut low_count = 0u64;
    // let mut high_count = 0u64;
    // for _ in 0..1000 {
    //     let (new_low, new_high) = push_the_button(&mut modules);
    //     low_count += new_low;
    //     high_count += new_high;
    // }
    //
    // let part1_result: u64 = low_count * high_count;
    // println!("Part1: {:?}", part1_result);

    // Part2
    let mut count = 0;

    loop {
        let (_, _, is_high) = push_the_button(&mut modules);
        count += 1;
        if is_high {
            println!("{count}");
        }
    }
    println!("Part2: {}", count);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

#[derive(Debug)]
struct Module {
    id: String,
    destinations: Vec<String>,
    state: ModuleType,
}

#[derive(Debug)]
enum ModuleType {
    FlipFlop(bool),
    Conjunction(HashMap<String, bool>),
    Broadcaster,
}

impl Module {
    fn from_str(input: &str) -> Module {
        let parts: Vec<&str> = input.split("->").map(|x| x.trim()).collect();
        let destinations: Vec<String> = parts[1].split(',').map(|x| x.trim().to_string()).collect();

        if parts[0] == "broadcaster" {
            return Module {
                id: String::from("broadcaster"),
                destinations,
                state: ModuleType::Broadcaster,
            };
        }

        let id: String = parts[0].chars().skip(1).collect();
        if parts[0].starts_with('&') {
            Module {
                id,
                destinations,
                state: ModuleType::Conjunction(HashMap::new()),
            }
        } else {
            Module {
                id,
                destinations,
                state: ModuleType::FlipFlop(false),
            }
        }
    }
}

fn init_conjunction_modules(modules: &mut HashMap<String, Module>) -> () {
    // when a conjunction is initialized
    // it must be low for all inputs
    let mut conjunction_sources: HashMap<String, Vec<String>> = HashMap::new();
    for m in modules.values() {
        for dest_id in m.destinations.iter() {
            if modules.contains_key(dest_id) {
                let dest_module = &modules[dest_id];
                match dest_module.state {
                    ModuleType::Conjunction(_) => {
                        conjunction_sources
                            .entry(dest_id.to_owned())
                            .or_insert(vec![]);
                        conjunction_sources
                            .entry(dest_id.to_owned())
                            .and_modify(|x| x.push(m.id.to_owned()));
                    }
                    _ => (),
                }
            }
        }
    }

    for (conj_id, sources) in conjunction_sources.iter() {
        modules.entry(conj_id.to_owned()).and_modify(|x| {
            if let ModuleType::Conjunction(ref mut state) = x.state {
                for src in sources {
                    state.insert(src.to_owned(), false);
                }
            }
        });
    }
}

fn push_the_button(modules: &mut HashMap<String, Module>) -> (u64, u64, bool) {
    let mut queue: VecDeque<(String, String, bool)> = VecDeque::new();
    let mut low_pulses_count = 0u64;
    let mut high_pulses_count = 0u64;
    let mut is_high_result = false;
    // send low pulse to the broadcaster
    queue.push_back((String::from("button"), String::from("broadcaster"), false));

    // process all the pulses
    while let Some((from, to, is_high_pulse)) = queue.pop_front() {
        if is_high_pulse {
            high_pulses_count += 1;
        } else {
            low_pulses_count += 1;
        }

        modules.entry(to.to_owned()).and_modify(|module| {
            match &mut module.state {
                ModuleType::Broadcaster => {
                    module.destinations.iter().for_each(|d| {
                        queue.push_back((module.id.to_owned(), d.to_owned(), is_high_pulse));
                    });
                }
                ModuleType::FlipFlop(is_on) => {
                    if !is_high_pulse {
                        *is_on = !*is_on;

                        module.destinations.iter().for_each(|d| {
                            queue.push_back((module.id.to_owned(), d.to_owned(), *is_on));
                        });
                    }
                }
                ModuleType::Conjunction(curr_state) => {
                    // update memory
                    curr_state.entry(from).and_modify(|x| *x = is_high_pulse);

                    // send new signals
                    let next_pulse = !curr_state.values().all(|v| *v == true);
                    if next_pulse == true && module.id == String::from("fc") {
                        is_high_result = true
                    }
                    module.destinations.iter().for_each(|d| {
                        queue.push_back((module.id.to_owned(), d.to_owned(), next_pulse));
                    });
                }
            }
        });
    }

    // let is_single_low_pulse = rx_low_pulses_count == 1;
    // println!("Low: {rx_low_pulses_count:?}, high: {rx_high_pulses_count}");
    return (low_pulses_count, high_pulses_count, is_high_result);
}
