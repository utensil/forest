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

use std::{env, fs, process, io::Write};
use logos::Logos;
use pretty::{BoxDoc, Pretty, BoxAllocator};

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;
type ListStack = Vec<(bool, Vec<Node>)>;

const DEFAULT_LINE_WIDTH: usize = 80;

/// Represents a node in the abstract syntax tree for the document
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
    /// Checks if a BoxDoc is empty by rendering it and checking the result
    fn is_empty_doc(doc: &BoxDoc) -> Result<bool> {
        let mut output = Vec::new();
        doc.clone().pretty(&BoxAllocator).render(0, &mut output)?;
        Ok(String::from_utf8(output)?.is_empty())
    }

    /// Combines multiple BoxDocs into a single document, separated by newlines
    fn fold_docs<'a, I>(docs: I) -> BoxDoc<'a> 
    where
        I: Iterator<Item = BoxDoc<'a>>,
    {
        docs.fold(BoxDoc::nil(), |acc, doc| {
            if Self::is_empty_doc(&acc).unwrap_or(true) {
                doc
            } else {
                acc.append(BoxDoc::hardline()).append(doc)
            }
        })
    }

    /// Converts an AST node into a pretty-printable document
    /// 
    /// The document structure uses these formatting rules:
    /// - Lists are indented by 2 spaces
    /// - Double hardlines create paragraph breaks
    /// - Commands with bodies get paragraph breaks around the body
    /// - Groups allow the pretty printer to choose optimal line breaks
    fn to_doc(&self) -> BoxDoc<'_> {
        match self {
            Node::List { ordered, items } => {
                let cmd = if *ordered { "ol" } else { "ul" };
                let items_doc = Self::fold_docs(items.iter().map(|item| item.to_doc()));
                BoxDoc::text(format!("\\{}", cmd))
                    .append(BoxDoc::text("{"))
                    .append(BoxDoc::hardline())
                    .append(items_doc.nest(2))  // Indent list items
                    .append(BoxDoc::hardline())
                    .append(BoxDoc::text("}"))
                    .group()  // Allow pretty printer to optimize breaks
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
                        .append(BoxDoc::hardline())
                        .append(BoxDoc::hardline())
                        .append(BoxDoc::text("\\p{"))
                        .append(body.to_doc())
                        .append(BoxDoc::text("}"))
                        .append(BoxDoc::hardline())
                        .append(BoxDoc::hardline())
                        .append(BoxDoc::text("}"))
                        .append(BoxDoc::hardline())
                        .append(BoxDoc::hardline())
                        .append(BoxDoc::text("}"))
                        .append(BoxDoc::hardline());
                }
                doc.group()
            }
            Node::Text(text) => BoxDoc::text(text.clone()),
            Node::Block(nodes) => Self::fold_docs(nodes.iter().map(|node| node.to_doc()))
        }
    }
}

#[derive(Logos, Debug, PartialEq)]
enum Token {
    // Lists - capture list type and content
    #[regex(r"\\begin\{(enumerate|itemize)\}", |lex| lex.slice().contains("enumerate"))]
    BeginList(bool),  // true for enumerate, false for itemize
    #[regex(r"\\end\{(enumerate|itemize)\}")]
    EndList,
    
    // List items - capture content after command
    #[regex(r"\\(item|ii)\s+([^\n\r]+)", |lex| {
        let content = lex.slice();
        let after_command = content.find(' ').map(|i| i + 1).unwrap_or(content.len());
        content[after_command..].trim().to_string()
    })]
    ListItem(String),

    // Math expressions
    #[regex(r"\$\$([^$]*)\$\$", |lex| lex.captures_iter(lex.slice()).next().unwrap()[1].to_string())]
    DisplayMath(String),
    #[regex(r"\$([^$]*)\$", |lex| lex.captures_iter(lex.slice()).next().unwrap()[1].to_string())]
    InlineMath(String),

    // Special blocks - capture command type and arguments
    #[regex(r"\\(texdef|texnote)\{([^}]*)\}\{([^}]*)\}\{", 
        |lex| {
            let content = lex.slice();
            let cmd_type = if content.starts_with("\\texdef") { "refdef" } else { "refnote" };
            let args: Vec<&str> = content.split('{')
                .skip(1)  // Skip command name
                .take(2)  // Take first two arguments
                .map(|s| s.trim_end_matches('}'))
                .collect();
            (cmd_type.to_string(), args[0].to_string(), args[1].to_string())
        })]
    DefBlock(String, String, String),  // command name, arg1, arg2
    #[token("\\minitex{")]
    MiniTex,

    // Other commands
    #[regex(r"\\emph\{[^}]*\}")]
    EmphText,

    // Basic text token - matches any sequence of characters that:
    // - isn't a command (no backslash)
    // - isn't math (no dollar signs)
    // - isn't braces
    // - isn't line endings
    #[regex(r"[^\\$\{\}\n\r]+", |lex| lex.slice().to_string())]
    Text(String),
    #[regex(r"[\n\r]+")]
    Newline,
    #[regex(r"\{")]
    OpenBrace,
    #[regex(r"\}")]
    CloseBrace
}

/// Handles the end of a list by popping it from the stack and adding it to the nodes
fn handle_list_end(nodes: &mut Vec<Node>, list_stack: &mut ListStack, ordered: bool) {
    if let Some((_, items)) = list_stack.pop() {
        nodes.push(Node::List { ordered, items });
    }
}

fn parse_tokens(lex: logos::Lexer<Token>) -> Node {
    let mut nodes = Vec::new();
    let mut list_stack = Vec::new();
    
    println!("\nDEBUG: Starting tokenization...");
    
    for token in lex {
        println!("\nDEBUG: Processing token: {:?}", token);
        match token {
            Ok(Token::BeginList(ordered)) => {
                list_stack.push((ordered, Vec::new()));
            }
            Ok(Token::EndList) => {
                if let Some((ordered, items)) = list_stack.pop() {
                    nodes.push(Node::List { ordered, items });
                }
            }
            Ok(Token::ListItem(content)) => {
                if let Some((_, items)) = list_stack.last_mut() {
                    items.push(Node::ListItem(content));
                } else {
                    nodes.push(Node::ListItem(content));
                }
            }
            Ok(Token::DisplayMath(content)) => {
                nodes.push(Node::Text(format!("##{{{}}}",content)));
                println!("DEBUG: Created display math node: content={}", content);
            }
            Ok(Token::InlineMath(content)) => {
                nodes.push(Node::Text(format!("#{{{}}}",content)));
                println!("DEBUG: Created inline math node: content={}", content);
            }
            Ok(Token::DefBlock(cmd, arg1, arg2)) => {
                nodes.push(Node::Command {
                    name: cmd,
                    args: vec![arg1, arg2],
                    body: None
                });
                println!("DEBUG: Created command node: name={}, args={:?}", cmd, vec![arg1, arg2]);
            }
            Ok(Token::MiniTex) => {
                nodes.push(Node::Command {
                    name: "minitex".to_string(),
                    args: vec![],
                    body: None
                });
                println!("DEBUG: Created minitex command node");
            }
            Ok(Token::EmphText) => {
                let content = lex.slice()
                    .trim_start_matches("\\emph{")
                    .trim_end_matches("}");
                nodes.push(Node::Command {
                    name: "em".to_string(),
                    args: vec![content.to_string()],
                    body: None
                });
                println!("DEBUG: Created em command node with content: {}", content);
            }
            Ok(Token::Text(text)) => {
                // Join consecutive text nodes
                if let Some(Node::Text(prev)) = nodes.last_mut() {
                    prev.push_str(&text);
                } else {
                    nodes.push(Node::Text(text));
                }
            }
            Ok(Token::Newline) => {
                // Skip newlines as they'll be handled by the pretty printer
            }
            Ok(Token::OpenBrace) => {
                nodes.push(Node::Text("{".to_string()));
            }
            Ok(Token::CloseBrace) => {
                nodes.push(Node::Text("}\n".to_string()));
            }
            Err(_) => (), // Skip errors
        }
    }
    
    Node::Block(nodes)
}

/// Processes the input content by tokenizing, parsing and pretty printing
fn process_content(input: &str) -> Result<String> {
    println!("\nDEBUG: Input content:");
    println!("{}", input);
    let lex = Token::lexer(input);
    let ast = parse_tokens(lex);
    println!("\nDEBUG: Generated AST:");
    println!("{:#?}", ast);
    let doc = ast.to_doc();
    let mut output = Vec::new();
    doc.pretty(&BoxAllocator).render(DEFAULT_LINE_WIDTH, &mut output)?;
    Ok(String::from_utf8(output)?)
}

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    
    if args.len() != 2 {
        eprintln!("Usage: ./fize.rs <tree>");
        process::exit(1);
    }

    let tree_path = format!("trees/{}.tree", args[1]);
    let content = fs::read_to_string(&tree_path)?;
    let processed = process_content(&content)?;
    let mut file = fs::OpenOptions::new()
        .write(true)
        .truncate(true)
        .open(&tree_path)?;
    file.write_all(processed.as_bytes())?;
    file.flush()?;
    Ok(())
}
