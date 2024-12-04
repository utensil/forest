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
use pretty::{BoxDoc, Pretty, BoxAllocator};

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
                let items_doc = items.iter()
                    .map(|item| item.to_doc())
                    .fold(BoxDoc::nil(), |acc, doc| {
                        if acc.is_empty() { doc } else { acc.append(BoxDoc::line()).append(doc) }
                    });
                BoxDoc::text(format!("\\{}", cmd))
                    .append(BoxDoc::text("{"))
                    .append(BoxDoc::line())
                    .append(items_doc.nest(2))
                    .append(BoxDoc::line())
                    .append(BoxDoc::text("}"))
                    .group()
            }
            Node::ListItem(content) => {
                BoxDoc::text(format!("\\li{{{}}}", content))
            }
            Node::Math { display, content } => {
                let delim = if *display { "##" } else { "#" };
                BoxDoc::text(format!("{}{{{}}}", delim, content))
            }
            Node::Command { name, args, body } => {
                let mut doc = BoxDoc::text(format!("\\{}", name));
                for arg in args {
                    doc = doc.append(BoxDoc::text(format!("{{{}}}", arg)));
                }
                if let Some(body) = body {
                    doc = doc
                        .append(BoxDoc::text("{"))
                        .append(BoxDoc::line())
                        .append(BoxDoc::line())
                        .append(BoxDoc::text("\\p{"))
                        .append(body.to_doc())
                        .append(BoxDoc::text("}"))
                        .append(BoxDoc::line())
                        .append(BoxDoc::line())
                        .append(BoxDoc::text("}"))
                        .append(BoxDoc::text("\r\r}\r"));
                }
                doc.group()
            }
            Node::Text(text) => BoxDoc::text(text),
            Node::Block(nodes) => {
                nodes.iter()
                    .map(|node| node.to_doc())
                    .fold(BoxDoc::nil(), |acc, doc| {
                        if acc.is_empty() { doc } else { acc.append(doc) }
                    })
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
    #[regex(r"[^\\$\{\}\n\r]+", |lex| lex.slice().to_string())]
    Text(String),
    #[regex(r"[\n\r]+")]
    Newline,
    #[regex(r"\{")]
    OpenBrace,
    #[regex(r"\}")]
    CloseBrace,

    Error,
}

fn parse_tokens(lex: logos::Lexer<Token>) -> Node {
    let mut nodes = Vec::new();
    let mut list_stack = Vec::new();
    
    for token in lex {
        match token {
            Ok(Token::BeginEnumerate) => {
                list_stack.push((true, Vec::new())); // ordered=true
            }
            Ok(Token::EndEnumerate) => {
                if let Some((_, items)) = list_stack.pop() {
                    nodes.push(Node::List { 
                        ordered: true, 
                        items 
                    });
                }
            }
            Ok(Token::BeginItemize) => {
                list_stack.push((false, Vec::new())); // ordered=false
            }
            Ok(Token::EndItemize) => {
                if let Some((_, items)) = list_stack.pop() {
                    nodes.push(Node::List { 
                        ordered: false, 
                        items 
                    });
                }
            }
            Ok(Token::Item(content)) | Ok(Token::Ii(content)) => {
                let item = Node::ListItem(content);
                if let Some((_, items)) = list_stack.last_mut() {
                    items.push(item);
                } else {
                    nodes.push(item);
                }
            }
            Ok(Token::DisplayMath(content)) => {
                nodes.push(Node::Math {
                    display: true,
                    content,
                });
            }
            Ok(Token::InlineMath(content)) => {
                nodes.push(Node::Math {
                    display: false,
                    content,
                });
            }
            Ok(Token::TexDef((arg1, arg2))) => {
                nodes.push(Node::Command {
                    name: "refdef".to_string(),
                    args: vec![arg1, arg2],
                    body: Some(Box::new(Node::Text(String::new()))),
                });
            }
            Ok(Token::TexNote((arg1, arg2))) => {
                nodes.push(Node::Command {
                    name: "refnote".to_string(),
                    args: vec![arg1, arg2],
                    body: Some(Box::new(Node::Text(String::new()))),
                });
            }
            Ok(Token::MiniTex) => {
                nodes.push(Node::Command {
                    name: "p".to_string(),
                    args: vec![],
                    body: Some(Box::new(Node::Text(String::new()))),
                });
            }
            Ok(Token::Emph(content)) => {
                nodes.push(Node::Command {
                    name: "em".to_string(),
                    args: vec![content],
                    body: None,
                });
            }
            Ok(Token::Text(text)) => {
                nodes.push(Node::Text(text.to_string()));
            }
            Ok(Token::Newline) => {
                nodes.push(Node::Text("\r".to_string()));
            }
            Ok(Token::OpenBrace) => {
                nodes.push(Node::Text("{".to_string()));
            }
            Ok(Token::CloseBrace) => {
                nodes.push(Node::Text("}".to_string()));
            }
            Ok(Token::Error) | Err(_) => (), // Skip errors
        }
    }
    
    Node::Block(nodes)
}

fn process_content(input: &str) -> String {
    let lex = Token::lexer(input);
    let ast = parse_tokens(lex);
    let doc = ast.to_doc();
    let width = 80; // configurable line width
    let allocator = BoxAllocator;
    let mut vec = Vec::new();
    doc.pretty(&allocator).render(width, &mut vec).unwrap();
    String::from_utf8(vec).unwrap()
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
