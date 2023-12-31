use core::panic;
use std::fs::File;
use std::io::{self, BufReader, Read};
use std::time::Instant;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day19/src/input.txt";

    let now = Instant::now();

    // Part1
    // open the file and parse input
    let file = File::open(input_path)?;
    let mut reader = BufReader::new(file);
    let mut buf = String::from("");
    let _ = reader.read_to_string(&mut buf);
    let (workflows, details) = process_input(&buf);

    let part1_result: u64 = details
        .iter()
        .filter(|d| d.is_accepted(&workflows, String::from("in")))
        .map(|d| d.x + d.m + d.a + d.s)
        .sum();
    println!("Part1: {:?}", part1_result);

    let accepted_details: Vec<DetailRange> = find_accepted_details(&workflows);
    println!("{accepted_details:?}");
    let part2_result = accepted_details.iter().fold(0u64, |acc, r| {
        acc + (r.x.1 - r.x.0) * (r.m.1 - r.m.0) * (r.a.1 - r.a.0) * (r.s.1 - r.s.0)
    });
    println!("Part2: {}", part2_result);

    println!("Elapsed: {:?}", now.elapsed());
    return Ok(());
}

#[derive(Debug)]
struct Workflow {
    name: String,
    rules: Vec<Rule>,
}

#[derive(Debug)]
struct Rule {
    condition: Option<RuleCondition>,
    dest: RuleDestination,
}

#[derive(Debug)]
struct RuleCondition {
    prop: char,
    comparison: char,
    value: u64,
}

#[derive(Debug, Clone)]
enum RuleDestination {
    Accept,
    Reject,
    Workflow(String),
}

#[derive(Debug)]
struct Detail {
    x: u64,
    m: u64,
    a: u64,
    s: u64,
}

#[derive(Debug, Clone, Copy)]
struct DetailRange {
    x: (u64, u64),
    m: (u64, u64),
    a: (u64, u64),
    s: (u64, u64),
}

impl Workflow {
    fn from_str(input: &str) -> Workflow {
        let mut workflow = Workflow {
            name: input.chars().take_while(|ch| *ch != '{').collect(),
            rules: vec![],
        };
        let tmp: String = input.chars().skip_while(|ch| *ch != '{').collect();
        workflow.rules = tmp
            .trim_matches(|ch| ch == '{' || ch == '}')
            .split(',')
            .map(|x| Rule::from_str(x))
            .collect();

        workflow
    }
}

impl Rule {
    fn from_str(input: &str) -> Rule {
        let parts: Vec<&str> = input.split(':').collect();
        if parts.len() == 1 {
            // has no condition
            Rule {
                condition: None,
                dest: RuleDestination::from_str(parts[0]),
            }
        } else {
            // has condition
            let dest = RuleDestination::from_str(parts[1]);
            let prop = parts[0].chars().next().unwrap();
            let comparison = parts[0].chars().skip(1).next().unwrap();
            let value = u64::from_str_radix(parts[0].trim_matches(|ch: char| !ch.is_digit(10)), 10)
                .unwrap();

            Rule {
                condition: Some(RuleCondition {
                    prop,
                    comparison,
                    value,
                }),
                dest,
            }
        }
    }
}

impl RuleDestination {
    fn from_str(input: &str) -> RuleDestination {
        match input {
            "R" => RuleDestination::Reject,
            "A" => RuleDestination::Accept,
            name => RuleDestination::Workflow(String::from(name)),
        }
    }
}

impl RuleCondition {
    fn is_matching(&self, detail: &Detail) -> bool {
        match (self.prop, self.comparison) {
            ('x', '>') => detail.x > self.value,
            ('x', '<') => detail.x < self.value,
            ('m', '>') => detail.m > self.value,
            ('m', '<') => detail.m < self.value,
            ('a', '>') => detail.a > self.value,
            ('a', '<') => detail.a < self.value,
            ('s', '>') => detail.s > self.value,
            ('s', '<') => detail.s < self.value,
            _ => panic!("Wrong comparison rule"),
        }
    }

    fn get_matching_range(&self, curr_range: &DetailRange) -> Option<DetailRange> {
        match (self.prop, self.comparison) {
            ('x', '>') => {
                if curr_range.x.1 <= self.value {
                    None
                } else {
                    Some(DetailRange {
                        x: (self.value + 1, curr_range.x.1),
                        m: curr_range.m.to_owned(),
                        a: curr_range.a.to_owned(),
                        s: curr_range.s.to_owned(),
                    })
                }
            }
            ('x', '<') => {
                if curr_range.x.0 > self.value {
                    None
                } else {
                    Some(DetailRange {
                        x: (curr_range.x.0, self.value),
                        m: curr_range.m.to_owned(),
                        a: curr_range.a.to_owned(),
                        s: curr_range.s.to_owned(),
                    })
                }
            }
            ('m', '>') => {
                if curr_range.m.1 <= self.value {
                    None
                } else {
                    Some(DetailRange {
                        x: curr_range.x.to_owned(),
                        m: (self.value + 1, curr_range.m.1),
                        a: curr_range.a.to_owned(),
                        s: curr_range.s.to_owned(),
                    })
                }
            }
            ('m', '<') => {
                if curr_range.m.0 > self.value {
                    None
                } else {
                    Some(DetailRange {
                        x: curr_range.x.to_owned(),
                        m: (curr_range.m.0, self.value),
                        a: curr_range.a.to_owned(),
                        s: curr_range.s.to_owned(),
                    })
                }
            }
            ('a', '>') => {
                if curr_range.a.1 <= self.value {
                    None
                } else {
                    Some(DetailRange {
                        x: curr_range.x.to_owned(),
                        m: curr_range.m.to_owned(),
                        a: (self.value + 1, curr_range.a.1),
                        s: curr_range.s.to_owned(),
                    })
                }
            }
            ('a', '<') => {
                if curr_range.a.0 > self.value {
                    None
                } else {
                    Some(DetailRange {
                        x: curr_range.x.to_owned(),
                        m: curr_range.m.to_owned(),
                        a: (curr_range.a.0, self.value),
                        s: curr_range.s.to_owned(),
                    })
                }
            }
            ('s', '>') => {
                if curr_range.s.1 <= self.value {
                    None
                } else {
                    Some(DetailRange {
                        x: curr_range.x.to_owned(),
                        m: curr_range.m.to_owned(),
                        a: curr_range.a.to_owned(),
                        s: (self.value + 1, curr_range.s.1),
                    })
                }
            }
            ('s', '<') => {
                if curr_range.s.0 > self.value {
                    None
                } else {
                    Some(DetailRange {
                        x: curr_range.x.to_owned(),
                        m: curr_range.m.to_owned(),
                        a: curr_range.a.to_owned(),
                        s: (curr_range.s.0, self.value),
                    })
                }
            }
            _ => panic!("Wrong comparison rule"),
        }
    }

    fn exclude_from(&self, range: &mut DetailRange) -> () {
        match (self.prop, self.comparison) {
            ('x', '>') => {
                if range.x.1 > self.value + 1 {
                    range.x = (range.x.0, self.value + 1)
                }
            }
            ('x', '<') => {
                if range.x.0 < self.value {
                    range.x = (self.value, range.x.1)
                }
            }
            ('m', '>') => {
                if range.m.1 > self.value + 1 {
                    range.m = (range.m.0, self.value + 1)
                }
            }
            ('m', '<') => {
                if range.m.0 < self.value {
                    range.m = (self.value, range.m.1)
                }
            }
            ('a', '>') => {
                if range.a.1 > self.value + 1 {
                    range.a = (range.a.0, self.value + 1)
                }
            }
            ('a', '<') => {
                if range.a.0 < self.value {
                    range.a = (self.value, range.a.1)
                }
            }
            ('s', '>') => {
                if range.s.1 > self.value + 1 {
                    range.s = (range.s.0, self.value + 1)
                }
            }
            ('s', '<') => {
                if range.s.0 < self.value {
                    range.s = (self.value, range.s.1)
                }
            }
            _ => panic!("Wrong comparison rule"),
        }
    }
}

impl Detail {
    fn from_str(input: &str) -> Detail {
        let mut detail = Detail {
            x: 0,
            m: 0,
            a: 0,
            s: 0,
        };
        input
            .trim_matches(|x| x == '{' || x == '}')
            .split(|x| x == ',' || x == '=')
            .collect::<Vec<&str>>()
            .chunks(2)
            .collect::<Vec<&[&str]>>()
            .iter()
            .for_each(|&x| match x[0].chars().next().unwrap() {
                'x' => detail.x = u64::from_str_radix(x[1], 10).unwrap(),
                'm' => detail.m = u64::from_str_radix(x[1], 10).unwrap(),
                'a' => detail.a = u64::from_str_radix(x[1], 10).unwrap(),
                's' => detail.s = u64::from_str_radix(x[1], 10).unwrap(),
                _ => panic!("Unknown property"),
            });

        detail
    }

    fn is_accepted(&self, workflows: &Vec<Workflow>, curr_workflow_name: String) -> bool {
        let workflow = workflows
            .iter()
            .find(|&w| w.name == curr_workflow_name)
            .unwrap();
        for rule in workflow.rules.iter() {
            if rule.condition.as_ref().is_some_and(|c| c.is_matching(self))
                || rule.condition.is_none()
            {
                match &rule.dest {
                    RuleDestination::Accept => return true,
                    RuleDestination::Reject => return false,
                    RuleDestination::Workflow(w) => {
                        return self.is_accepted(workflows, w.to_owned())
                    }
                }
            }
        }
        return false;
    }
}

fn process_input(input: &str) -> (Vec<Workflow>, Vec<Detail>) {
    let parts: Vec<&str> = input.split("\n\n").collect();
    let workflows: Vec<Workflow> = parts[0]
        .trim()
        .split('\n')
        .map(|x| Workflow::from_str(x))
        .collect();
    let details: Vec<Detail> = parts[1]
        .trim()
        .split('\n')
        .map(|x| Detail::from_str(x))
        .collect();
    (workflows, details)
}

fn find_accepted_details(workflows: &Vec<Workflow>) -> Vec<DetailRange> {
    // start with the most broad range
    let starting_range = DetailRange {
        x: (1, 4001),
        m: (1, 4001),
        a: (1, 4001),
        s: (1, 4001),
    };
    return do_find_accepted_details(workflows, starting_range, String::from("in"));
}

fn do_find_accepted_details(
    workflows: &Vec<Workflow>,
    range: DetailRange,
    workflow_id: String,
) -> Vec<DetailRange> {
    // get the current workflow
    let workflow = workflows.iter().find(|w| w.name == workflow_id).unwrap();
    let mut result: Vec<DetailRange> = vec![];
    let mut upd_range = range.clone();
    // apply each condition to the range
    for rule in workflow.rules.iter() {
        match &rule.condition {
            Some(cond) => {
                // extend result with range matching the condition
                let matching_range = cond.get_matching_range(&upd_range);
                if matching_range.is_some() {
                    result.extend(process_destination(
                        workflows,
                        matching_range.unwrap(),
                        rule.dest.to_owned(),
                    ));
                }
                // update upd_range so that it doesn't match the condition
                cond.exclude_from(&mut upd_range);
            }
            None => result.extend(process_destination(
                workflows,
                upd_range.clone(),
                rule.dest.to_owned(),
            )),
        }
    }

    return result;
}

fn process_destination(
    workflows: &Vec<Workflow>,
    range: DetailRange,
    destination: RuleDestination,
) -> Vec<DetailRange> {
    match destination {
        RuleDestination::Workflow(w) => do_find_accepted_details(workflows, range, w.to_owned()),
        RuleDestination::Reject => vec![],
        RuleDestination::Accept => vec![range],
    }
}
