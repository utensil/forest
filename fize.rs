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

use std::{env, fs, process};
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
    // Lists
    #[regex(r"\\begin\{enumerate\}", priority = 2)]
    BeginEnumerate,
    #[regex(r"\\end\{enumerate\}", priority = 2)]
    EndEnumerate,
    #[regex(r"\\begin\{itemize\}", priority = 2)]
    BeginItemize,
    #[regex(r"\\end\{itemize\}", priority = 2)]
    EndItemize,
    // Match list items like:
    // \item This is a list item
    // \ii Another list item style
    #[regex(r"\\item\s+([^\n\r]+)", |lex| lex.slice().trim_start_matches("\\item").trim().to_string())]
    Item(String),
    #[regex(r"\\ii\s+([^\n\r]+)", |lex| lex.slice().trim_start_matches("\\ii").trim().to_string())]
    Ii(String),

    // Math expressions:
    // Display math: $$x^2 + y^2 = z^2$$
    // Inline math: $x + y = z$
    #[regex(r"\$\$[^$]*\$\$", |lex| lex.slice().trim_matches('$').to_string())]
    DisplayMath(String),
    #[regex(r"\$[^$]*\$", |lex| lex.slice().trim_matches('$').to_string())]
    InlineMath(String),

    // Special LaTeX-style blocks with arguments:
    // Match definition blocks like:
    // \texdef{Definition 1}{Title}{Content}
    // Captures the two arguments before the content block
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
    
    for token in lex {
        match token {
            Ok(Token::BeginEnumerate) => list_stack.push((true, Vec::new())),
            Ok(Token::EndEnumerate) => handle_list_end(&mut nodes, &mut list_stack, true),
            Ok(Token::BeginItemize) => list_stack.push((false, Vec::new())),
            Ok(Token::EndItemize) => handle_list_end(&mut nodes, &mut list_stack, false),
            Ok(Token::Item(content)) | Ok(Token::Ii(content)) => {
                let item = Node::ListItem(content);
                if let Some((_, items)) = list_stack.last_mut() {
                    items.push(item);
                } else {
                    nodes.push(item);
                }
            }
            Ok(Token::DisplayMath(content)) | Ok(Token::InlineMath(content)) => {
                let display = matches!(token, Ok(Token::DisplayMath(_)));
                // Join math with surrounding text if possible
                match nodes.last_mut() {
                    Some(Node::Text(text)) => {
                        text.push_str(if display { "##" } else { "#" });
                        text.push_str("{");
                        text.push_str(&content);
                        text.push_str("}");
                    }
                    _ => nodes.push(Node::Math { display, content }),
                }
            }
            Ok(Token::TexDef((arg1, arg2))) | Ok(Token::TexNote((arg1, arg2))) => {
                let name = if matches!(token, Ok(Token::TexDef(_))) { "refdef" } else { "refnote" };
                nodes.push(Node::Command {
                    name: name.to_string(),
                    args: vec![arg1, arg2],
                    body: Some(Box::new(Node::Block(Vec::new()))),
                });
            }
            Ok(Token::MiniTex) => {
                nodes.push(Node::Command {
                    name: "p".to_string(),
                    args: vec![],
                    body: Some(Box::new(Node::Block(Vec::new()))),
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
                nodes.push(Node::Text("}".to_string()));
            }
            Err(_) => (), // Skip errors
        }
    }
    
    Node::Block(nodes)
}

/// Processes the input content by tokenizing, parsing and pretty printing
fn process_content(input: &str) -> Result<String> {
    let lex = Token::lexer(input);
    let ast = parse_tokens(lex);
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
    fs::write(&tree_path, processed)?;
    Ok(())
}
