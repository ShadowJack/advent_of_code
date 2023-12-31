use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::collections::HashMap;

fn main() -> io::Result<()> {
    // Specify the path to the input file
    let input_path = "day1/src/input.txt";

    // Open the file
    let file = File::open(input_path)?;
    let reader = BufReader::new(file);

    // Prapare data structure for efficient lookup
    let mut names = HashMap::new();
    names.insert("one", 1);
    names.insert("two", 2);
    names.insert("three", 3);
    names.insert("four", 4);
    names.insert("five", 5);
    names.insert("six", 6);
    names.insert("seven", 7);
    names.insert("eight", 8);
    names.insert("nine", 9);
    names.insert("1", 1);
    names.insert("2", 2);
    names.insert("3", 3);
    names.insert("4", 4);
    names.insert("5", 5);
    names.insert("6", 6);
    names.insert("7", 7);
    names.insert("8", 8);
    names.insert("9", 9);

    // Iterate over each line in the file
    let mut result = 0;
    let mut counter = 10;
    let print_lines = 20;
    for line in reader.lines() {
        counter += 1;
        let line_content = line?;
        if counter < print_lines {
            print!("{} ", line_content);
        }
        // Process each line as needed
        let mut first: Option<i32> = None;
        let mut last: Option<i32> = None;
        let len = line_content.len();
        // look for the first digit
        let mut i = 0;
        while i < len {
            let sub = &line_content[i..];
            for (name, value) in &names {
                if sub.starts_with(name) {
                    first = Some(*value);
                    break;
                }
            }
            match first {
                Some(_) => break,
                None => i += 1
            }
        }
        // look for the last digit
        i = len;
        while i > 0 {
            let sub = &line_content[0..i];
            for (name, value) in &names {
                if sub.ends_with(name) {
                    last = Some(*value);
                    break;
                }
            }
            match last {
                Some(_) => break,
                None => i -= 1,
            }
        }

        if first == None {
            first = Some(0);
        }
        if last == None {
            last = first;
        }
        if counter < print_lines {
            println!("{}{}", first.unwrap(), last.unwrap());
        }
        result += first.unwrap() * 10 + last.unwrap();
    }
    println!("{}", result);

    Ok(())
}
