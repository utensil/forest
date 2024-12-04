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
use std::fmt;
use std::process;
use logos::Logos;

#[derive(Debug)]
enum Node {
    List {
        ordered: bool,
        items: Vec<Node>,
    },
    ListItem(String),
    Math {
        display: bool,
        content: String,
    },
    Command {
        name: String,
        args: Vec<String>,
        body: Option<Box<Node>>,
    },
    Text(String),
    Block(Vec<Node>),
}

impl fmt::Display for Node {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Node::List { ordered, items } => {
                write!(f, "\\{}{{", if *ordered { "ol" } else { "ul" })?;
                for item in items {
                    write!(f, "{}", item)?;
                }
                write!(f, "}}")
            }
            Node::ListItem(content) => write!(f, "\\li{{{}}}", content),
            Node::Math { display, content } => {
                write!(f, "{}{{{}}}",
                    if *display { "##" } else { "#" },
                    content
                )
            }
            Node::Command { name, args, body } => {
                write!(f, "\\{}", name)?;
                for arg in args {
                    write!(f, "{{{}}}", arg)?;
                }
                if let Some(body) = body {
                    write!(f, "{{\n\n\\p{{{}}}\n\n}}\r\r}}\r", body)?;
                }
                Ok(())
            }
            Node::Text(text) => write!(f, "{}", text),
            Node::Block(nodes) => {
                for node in nodes {
                    write!(f, "{}", node)?;
                }
                Ok(())
            }
        }
    }
}

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

fn parse_tokens(lex: logos::Lexer<Token>) -> Node {
    let mut nodes = Vec::new();
    let mut list_stack = Vec::new();
    
    for token in lex {
        match token {
            Token::BeginEnumerate => {
                list_stack.push((true, Vec::new())); // ordered=true
            }
            Token::EndEnumerate => {
                if let Some((_, items)) = list_stack.pop() {
                    nodes.push(Node::List { 
                        ordered: true, 
                        items 
                    });
                }
            }
            Token::BeginItemize => {
                list_stack.push((false, Vec::new())); // ordered=false
            }
            Token::EndItemize => {
                if let Some((_, items)) = list_stack.pop() {
                    nodes.push(Node::List { 
                        ordered: false, 
                        items 
                    });
                }
            }
            Token::Item(content) | Token::Ii(content) => {
                let item = Node::ListItem(content);
                if let Some((_, items)) = list_stack.last_mut() {
                    items.push(item);
                } else {
                    nodes.push(item);
                }
            }
            Token::DisplayMath(content) => {
                nodes.push(Node::Math {
                    display: true,
                    content,
                });
            }
            Token::InlineMath(content) => {
                nodes.push(Node::Math {
                    display: false,
                    content,
                });
            }
            Token::TexDef((arg1, arg2)) => {
                nodes.push(Node::Command {
                    name: "refdef".to_string(),
                    args: vec![arg1, arg2],
                    body: Some(Box::new(Node::Text(String::new()))),
                });
            }
            Token::TexNote((arg1, arg2)) => {
                nodes.push(Node::Command {
                    name: "refnote".to_string(),
                    args: vec![arg1, arg2],
                    body: Some(Box::new(Node::Text(String::new()))),
                });
            }
            Token::MiniTex => {
                nodes.push(Node::Command {
                    name: "p".to_string(),
                    args: vec![],
                    body: Some(Box::new(Node::Text(String::new()))),
                });
            }
            Token::Emph(content) => {
                nodes.push(Node::Command {
                    name: "em".to_string(),
                    args: vec![content],
                    body: None,
                });
            }
            Token::Text(text) => {
                nodes.push(Node::Text(text.to_string()));
            }
            Token::Newline => {
                nodes.push(Node::Text("\r".to_string()));
            }
            Token::OpenBrace => {
                nodes.push(Node::Text("{".to_string()));
            }
            Token::CloseBrace => {
                nodes.push(Node::Text("}".to_string()));
            }
            Token::Error => (), // Skip errors
        }
    }
    
    Node::Block(nodes)
}

fn process_content(input: &str) -> String {
    let lex = Token::lexer(input);
    let ast = parse_tokens(lex);
    ast.to_string()
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
