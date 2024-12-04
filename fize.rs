#!/usr/bin/env cargo +nightly -Zscript
---cargo
[package]
name = "fize"
version = "0.1.0"
edition = "2021"
[dependencies]
logos = "0.13.0"
pretty = "0.12.1"
---

use std::env;
use std::fs;
use std::process;
use logos::Logos;
use pretty::{BoxDoc, Doc};

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

impl Node {
    fn to_doc(&self) -> BoxDoc<'static> {
        match self {
            Node::List { ordered, items } => {
                let cmd = if *ordered { "ol" } else { "ul" };
                let items_doc = Doc::intersperse(
                    items.iter().map(|item| item.to_doc()),
                    Doc::line()
                );
                Doc::text(format!("\\{}", cmd))
                    .append(Doc::text("{"))
                    .append(Doc::line())
                    .append(items_doc.nest(2))
                    .append(Doc::line())
                    .append(Doc::text("}"))
                    .group()
                    .into_boxed()
            }
            Node::ListItem(content) => {
                Doc::text(format!("\\li{{{}}}", content))
                    .into_boxed()
            }
            Node::Math { display, content } => {
                let delim = if *display { "##" } else { "#" };
                Doc::text(format!("{}{{{}}}", delim, content))
                    .into_boxed()
            }
            Node::Command { name, args, body } => {
                let mut doc = Doc::text(format!("\\{}", name));
                for arg in args {
                    doc = doc.append(Doc::text(format!("{{{}}}", arg)));
                }
                if let Some(body) = body {
                    doc = doc
                        .append(Doc::text("{"))
                        .append(Doc::line())
                        .append(Doc::line())
                        .append(Doc::text("\\p{"))
                        .append(body.to_doc())
                        .append(Doc::text("}"))
                        .append(Doc::line())
                        .append(Doc::line())
                        .append(Doc::text("}"))
                        .append(Doc::text("\r\r}\r"));
                }
                doc.group().into_boxed()
            }
            Node::Text(text) => Doc::text(text).into_boxed(),
            Node::Block(nodes) => {
                Doc::intersperse(
                    nodes.iter().map(|node| node.to_doc()),
                    Doc::nil()
                ).into_boxed()
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
    let doc = ast.to_doc();
    let width = 80; // configurable line width
    doc.pretty(width).to_string()
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
