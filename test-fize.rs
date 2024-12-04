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
    
    // Load expected output
    let expected = fs::read_to_string("trees/complex.tree.expected")?;
    
    // Compare both outputs against expected
    println!("Comparing Python output:");
    let py_diff = TextDiff::from_lines(&expected, &py_output);
    let mut py_has_diff = false;
    for change in py_diff.iter_all_changes() {
        match change.tag() {
            ChangeTag::Delete => {
                py_has_diff = true;
                print!("{}", format!("-{}", change).red());
            }
            ChangeTag::Insert => {
                py_has_diff = true;
                print!("{}", format!("+{}", change).green());
            }
            ChangeTag::Equal => {
                print!(" {}", change);
            }
        }
    }
    
    println!("\nComparing Rust output:");
    let rs_diff = TextDiff::from_lines(&expected, &rs_output);
    
    let mut rs_has_diff = false;
    for change in rs_diff.iter_all_changes() {
        match change.tag() {
            ChangeTag::Delete => {
                rs_has_diff = true;
                print!("{}", format!("-{}", change).red());
            }
            ChangeTag::Insert => {
                rs_has_diff = true;
                print!("{}", format!("+{}", change).green());
            }
            ChangeTag::Equal => {
                print!(" {}", change);
            }
        }
    }
    
    if py_has_diff || rs_has_diff {
        println!("\n{}", "One or both outputs differ from expected!".red());
        std::process::exit(1);
    } else {
        println!("\n{}", "Both outputs match expected!".green());
    }
    
    Ok(())
}
