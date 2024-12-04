#!/usr/bin/env cargo +nightly -Zscript
---cargo
[package]
name = "fize"
version = "0.1.0"
edition = "2021"
[dependencies]
regex = "1.9.5"
---

use std::env;
use std::fs;
use std::process;
use regex::Regex;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() != 2 {
        println!("Usage: ./fize.rs <tree>");
        process::exit(1);
    }

    let tree_path = format!("trees/{}.tree", args[1]);
    
    // Read the file content
    let mut content = fs::read_to_string(&tree_path)
        .expect("Should have been able to read the file");

    // Fix enumerate and itemize
    let re = Regex::new(r"\\begin\{enumerate\}").unwrap();
    content = re.replace_all(&content, r"\ol{").to_string();
    
    let re = Regex::new(r"\\end\{enumerate\}").unwrap();
    content = re.replace_all(&content, r"}").to_string();
    
    let re = Regex::new(r"\\begin\{itemize\}").unwrap();
    content = re.replace_all(&content, r"\ul{").to_string();
    
    let re = Regex::new(r"\\end\{itemize\}").unwrap();
    content = re.replace_all(&content, r"}").to_string();
    
    let re = Regex::new(r"\\item (.*)").unwrap();
    content = re.replace_all(&content, r"\li{$1}").to_string();
    
    let re = Regex::new(r"\\ii (.*)").unwrap();
    content = re.replace_all(&content, r"\li{$1}").to_string();

    // Convert LaTeX commands to forester commands
    let re = Regex::new(r"\\emph\{([^}]*)\}").unwrap();
    content = re.replace_all(&content, r"\em{$1}").to_string();

    // Replace line breaks with \r for multiline handling
    content = content.replace('\n', "\r");

    // Replace display math
    let re = Regex::new(r"\$\$([^$]+)\$\$").unwrap();
    content = re.replace_all(&content, r"##{$1}").to_string();

    // Replace inline math
    let re = Regex::new(r"\$([^$]+)\$").unwrap();
    content = re.replace_all(&content, r"#{$1}").to_string();

    // Replace LaTeX block openings
    let re = Regex::new(r"\\texdef\{([^}]*)\}\{([^}]*)\}\{").unwrap();
    content = re.replace_all(&content, r"\refdef{$1}{$2}{\n\n\p{").to_string();
    
    let re = Regex::new(r"\\texnote\{([^}]*)\}\{([^}]*)\}\{").unwrap();
    content = re.replace_all(&content, r"\refnote{$1}{$2}{\n\n\p{").to_string();
    
    let re = Regex::new(r"\\minitex\{").unwrap();
    content = re.replace_all(&content, r"{\n\n\p{").to_string();

    // Handle paragraph breaks after refdef/refnote
    let lines: Vec<&str> = content.split('\n').collect();
    let mut skip = true;
    let mut new_content = Vec::new();

    for line in lines {
        if line.contains(r"\refdef") || line.contains(r"\refnote") {
            skip = false;
            new_content.push(line.to_string());
            continue;
        }
        if !skip {
            new_content.push(line.replace("\r\r", "}\r\r\\p{"));
        } else {
            new_content.push(line.to_string());
        }
    }
    content = new_content.join("\n");

    // Replace ending
    let re = Regex::new(r"}\s*$").unwrap();
    content = re.replace_all(&content, "}\r\r}\r").to_string();

    // Replace \texdef with \refdef
    let re = Regex::new(r"\\texdef").unwrap();
    content = re.replace_all(&content, r"\refdef").to_string();

    // Write back to file
    fs::write(&tree_path, content)
        .expect("Should have been able to write the file");
}
