#!/usr/bin/env cargo +nightly -Zscript
---cargo
[package]
name = "test-fize"
version = "0.1.0"
edition = "2021"
[dependencies]
similar = "2.4.0"
colored = "2.1.0"
---

use std::{fs, process::Command};
use similar::{ChangeTag, TextDiff};
use colored::*;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Ensure we have a clean copy of the test file
    let original = fs::read_to_string("trees/complex.tree")?;
    
    // Run fize.rs first
    let rs_output = {
        fs::write("trees/complex.tree", &original)?;
        Command::new("./fize.rs")
            .arg("complex")
            .output()?;
        fs::read_to_string("trees/complex.tree")?
    };
    
    // Run fize.py second
    let py_output = {
        fs::write("trees/complex.tree", &original)?;
        Command::new("./fize.py")
            .arg("complex")
            .output()?;
        fs::read_to_string("trees/complex.tree")?
    };
    
    // Restore original content
    fs::write("trees/complex.tree", &original)?;
    
    // Compare outputs
    let diff = TextDiff::from_lines(&py_output, &rs_output);
    
    let mut has_diff = false;
    for change in diff.iter_all_changes() {
        match change.tag() {
            ChangeTag::Delete => {
                has_diff = true;
                print!("{}", format!("-{}", change).red());
            }
            ChangeTag::Insert => {
                has_diff = true;
                print!("{}", format!("+{}", change).green());
            }
            ChangeTag::Equal => {
                print!(" {}", change);
            }
        }
    }
    
    if has_diff {
        println!("\n{}", "Outputs differ!".red());
        std::process::exit(1);
    } else {
        println!("\n{}", "Outputs match!".green());
    }
    
    Ok(())
}
