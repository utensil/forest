#!/usr/bin/env cargo +nightly -Zscript
---cargo
[package]
name = "fize"
version = "0.1.0"
edition = "2021"
[dependencies]
logos = "0.13.0"
---

use std::env;
use std::fs;
use std::process;
use logos::Logos;

#[derive(Logos, Debug, PartialEq)]
enum Token {
    // Lists
    #[regex(r"\\begin\{enumerate\}", priority = 2)]
    BeginEnumerate,
    #[regex(r"\\end\{enumerate\}", priority = 2)]
    EndEnumerate,
    #[regex(r"\\begin\{itemize\}", priority = 2)]
    BeginItemize,
    #[regex(r"\\end\{itemize\}", priority = 2)]
    EndItemize,
    #[regex(r"\\item\s+([^\n\r]+)", |lex| lex.slice().trim_start_matches("\\item").trim().to_string())]
    Item(String),
    #[regex(r"\\ii\s+([^\n\r]+)", |lex| lex.slice().trim_start_matches("\\ii").trim().to_string())]
    Ii(String),

    // Math
    #[regex(r"\$\$[^$]*\$\$", |lex| lex.slice().trim_matches('$').to_string())]
    DisplayMath(String),
    #[regex(r"\$[^$]*\$", |lex| lex.slice().trim_matches('$').to_string())]
    InlineMath(String),

    // Special blocks
    #[regex(r"\\texdef\{([^}]*)\}\{([^}]*)\}\{", |lex| {
        let content = lex.slice();
        let mut parts = content.split('{');
        parts.next(); // skip command
        let arg1 = parts.next().unwrap().trim_end_matches('}').to_string();
        let arg2 = parts.next().unwrap().trim_end_matches('}').to_string();
        (arg1, arg2)
    })]
    TexDef((String, String)),
    #[regex(r"\\texnote\{([^}]*)\}\{([^}]*)\}\{", |lex| {
        let content = lex.slice();
        let mut parts = content.split('{');
        parts.next(); // skip command
        let arg1 = parts.next().unwrap().trim_end_matches('}').to_string();
        let arg2 = parts.next().unwrap().trim_end_matches('}').to_string();
        (arg1, arg2)
    })]
    TexNote((String, String)),
    #[token("\\minitex{")]
    MiniTex,

    // Other commands
    #[regex(r"\\emph\{([^}]*)\}", |lex| {
        lex.slice().trim_start_matches("\\emph{").trim_end_matches('}').to_string()
    })]
    Emph(String),

    // Basic tokens
    #[regex(r"[^\\$\{\}\n\r]+")]
    Text(&'static str),
    #[regex(r"[\n\r]+")]
    Newline,
    #[regex(r"\{")]
    OpenBrace,
    #[regex(r"\}")]
    CloseBrace,

    #[error]
    Error,
}

fn process_content(input: &str) -> String {
    let mut output = String::new();
    let lex = Token::lexer(input);
    
    for token in lex {
        match token {
            Token::BeginEnumerate => output.push_str("\\ol{"),
            Token::EndEnumerate => output.push('}'),
            Token::BeginItemize => output.push_str("\\ul{"),
            Token::EndItemize => output.push('}'),
            Token::Item(content) => output.push_str(&format!("\\li{{{}}}", content)),
            Token::Ii(content) => output.push_str(&format!("\\li{{{}}}", content)),
            Token::DisplayMath(content) => output.push_str(&format!("##{{{}}}", content)),
            Token::InlineMath(content) => output.push_str(&format!("#{{{}}}", content)),
            Token::TexDef((arg1, arg2)) => {
                output.push_str(&format!("\\refdef{{{}}}{{{}}}{{\n\n\\p{{", arg1, arg2))
            },
            Token::TexNote((arg1, arg2)) => {
                output.push_str(&format!("\\refnote{{{}}}{{{}}}{{\n\n\\p{{", arg1, arg2))
            },
            Token::MiniTex => output.push_str("{\n\n\\p{"),
            Token::Emph(content) => output.push_str(&format!("\\em{{{}}}", content)),
            Token::Text(text) => output.push_str(text),
            Token::Newline => output.push_str("\r"),
            Token::OpenBrace => output.push('{'),
            Token::CloseBrace => output.push('}'),
            Token::Error => (), // Skip errors
        }
    }

    // Handle paragraph breaks after refdef/refnote
    let lines: Vec<&str> = output.split('\n').collect();
    let mut skip = true;
    let mut new_content = Vec::new();

    for line in lines {
        if line.contains("\\refdef") || line.contains("\\refnote") {
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
    output = new_content.join("\n");

    // Final cleanup
    if output.trim_end().ends_with('}') {
        output.push_str("\r\r}\r");
    }

    output
}

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() != 2 {
        println!("Usage: ./fize.rs <tree>");
        process::exit(1);
    }

    let tree_path = format!("trees/{}.tree", args[1]);
    
    // Read the file content
    let content = fs::read_to_string(&tree_path)
        .expect("Should have been able to read the file");

    // Process content using lexer
    let processed = process_content(&content);

    // Write back to file
    fs::write(&tree_path, processed)
        .expect("Should have been able to write the file");
}
