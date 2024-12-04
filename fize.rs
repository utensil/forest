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

const DEFAULT_LINE_WIDTH: usize = 80;

/// Represents a node in the abstract syntax tree for the document
#[derive(Debug)]
enum Node {
    List {
        ordered: bool,
        items: Vec<Node>,
    },
    ListItem(String),
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
    fn fold_docs<'a, I>(docs: I) -> BoxDoc<'a, ()> 
    where
        I: Iterator<Item = BoxDoc<'a, ()>> + 'a,
    {
        docs.fold(BoxDoc::nil(), |acc, doc| {
            if Self::is_empty_doc(&acc).unwrap_or(true) {
                doc
            } else {
                acc.append(BoxDoc::hardline()).append(doc)
            }
        })
    }

    fn to_doc(&self) -> BoxDoc<'_, ()> {
        match self {
            Node::List { ordered, items } => {
                let cmd = if *ordered { "\\ol" } else { "\\ul" };
                let items_doc = Self::fold_docs(items.iter().map(|item| item.to_doc())).nest(2);
                BoxDoc::text(cmd)
                    .append(BoxDoc::text("{"))
                    .append(BoxDoc::hardline())
                    .append(items_doc)
                    .append(BoxDoc::hardline())
                    .append(BoxDoc::text("}"))
                    .append(BoxDoc::hardline())
            }
            Node::ListItem(content) => {
                BoxDoc::text("\\li{")
                    .append(content)
                    .append(BoxDoc::text("}"))
                    .append(BoxDoc::hardline())
            }
            Node::Command { name, args, body } => {
                let mut doc = BoxDoc::text(format!("\\{}", name));
                for arg in args {
                    doc = doc.append(BoxDoc::text(format!("{{{}}}", arg)));
                }
                
                if let Some(body) = body {
                    doc = doc.append(BoxDoc::text("{"))
                        .append(BoxDoc::hardline())
                        .append(BoxDoc::text("\\p{"))
                        .append(body.to_doc())
                        .append(BoxDoc::text("}"))
                        .append(BoxDoc::hardline())
                        .append(BoxDoc::text("}"))
                        .append(BoxDoc::hardline());
                } else {
                    doc = doc.append(BoxDoc::text("{"))
                        .append(BoxDoc::text("}"));
                }
                
                doc
            }
            Node::Text(text) => {
                if text.ends_with('\n') {
                    BoxDoc::text(text.clone()).append(BoxDoc::hardline())
                } else {
                    BoxDoc::text(text.clone())
                }
            },
            Node::Block(nodes) => {
                Self::fold_docs(nodes.iter().map(|node| node.to_doc()))
            }
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
    #[regex(r"\$\$([^$]*)\$\$", |lex| {
        let content = lex.slice();
        content.trim_start_matches("$$").trim_end_matches("$$").to_string()
    })]
    DisplayMath(String),
    #[regex(r"\$([^$]*)\$", |lex| {
        let content = lex.slice();
        content.trim_start_matches("$").trim_end_matches("$").to_string()
    })]
    InlineMath(String),

    // Special blocks - capture command type and arguments
    #[regex(r"\\(texdef|texnote)\{([^}]*)\}\{([^}]*)\}\{", |lex| {
        let content = lex.slice();
        let parts: Vec<&str> = content.split('{')
            .map(|s| s.trim_end_matches('}'))
            .collect();
        format!("{}|{}", parts[1], parts[2])
    })]
    DefBlock(String),

    #[token("\\minitex{")]
    MiniTex,

    // Other commands - capture the text content
    #[regex(r"\\emph\{([^}]*)\}", |lex| {
        let content = lex.slice();
        content[6..content.len()-1].to_string()
    })]
    EmphText(String),

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


fn parse_tokens(lex: logos::Lexer<Token>) -> Node {
    let mut nodes = Vec::new();
    let mut list_stack: Vec<(bool, Vec<Node>)> = Vec::new();
    
    println!("\nDEBUG: Starting tokenization...");
    
    // Collect all tokens first to avoid ownership issues
    let tokens: Vec<_> = lex.collect();
    
    for token in tokens {
        println!("\nDEBUG: Processing token: {:?}", token);
        match token {
            Ok(Token::BeginList(ordered)) => {
                let stack_len = list_stack.len();
                if stack_len > 0 {
                    // This is a nested list
                    let new_list = Node::List { ordered, items: Vec::new() };
                    if let Some((_, parent_items)) = list_stack.last_mut() {
                        parent_items.push(new_list);
                    }
                }
                list_stack.push((ordered, Vec::new()));
            }
            Ok(Token::EndList) => {
                if let Some((ordered, items)) = list_stack.pop() {
                    let is_top_level = list_stack.is_empty();
                    if is_top_level {
                        nodes.push(Node::List { ordered, items });
                    }
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
                // Preserve LaTeX formatting
                let content = content.replace("cos", "\\cos")
                                   .replace("sin", "\\sin")
                                   .replace("theta", "\\theta");
                nodes.push(Node::Text(format!("##{{{}}}", content.trim())));
                println!("DEBUG: Created display math node: content={}", content);
            }
            Ok(Token::InlineMath(content)) => {
                // Preserve LaTeX formatting
                let content = content.replace("cos", "\\cos")
                                   .replace("sin", "\\sin")
                                   .replace("theta", "\\theta");
                nodes.push(Node::Text(format!("#{{{}}}", content.trim())));
                println!("DEBUG: Created inline math node: content={}", content);
            }
            Ok(Token::DefBlock(combined)) => {
                let parts: Vec<&str> = combined.split('|').collect();
                let name = if combined.starts_with("texdef") { "refdef" } else { "refnote" };
                nodes.push(Node::Command {
                    name: name.to_string(),
                    args: vec![parts[0].to_string(), parts[1].to_string()],
                    body: Some(Box::new(Node::Block(Vec::new())))
                });
            }
            Ok(Token::MiniTex) => {
                nodes.push(Node::Command {
                    name: "minitex".to_string(),
                    args: vec![],
                    body: Some(Box::new(Node::Block(Vec::new())))
                });
            }
            Ok(Token::EmphText(text)) => {
                nodes.push(Node::Command {
                    name: "em".to_string(),
                    args: vec![text],
                    body: None
                });
                // Don't add extra newline after em command
                match nodes.last_mut() {
                    Some(Node::Command { body: None, .. }) => (),
                    _ => nodes.push(Node::Text(" ".to_string()))
                }
            }
            Ok(Token::Text(text)) => {
                if !text.is_empty() {
                    match nodes.last_mut() {
                        Some(Node::Text(prev)) => {
                            prev.push_str(&text);
                        }
                        _ => nodes.push(Node::Text(text.to_string()))
                    }
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
