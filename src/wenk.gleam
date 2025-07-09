/// Markdown block parser and renderer.
///
/// This module provides functions to parse Markdown text into block elements and render them as HTML.
/// It supports headings, paragraphs, unordered and ordered lists, and fenced code blocks.
/// Inline parsing (for bold, italic, etc.) is delegated to `wenk/inline_parser`.
///
/// # Example
/// ```gleam
/// import wenk
/// let blocks = wenk.parse("# Hello, *world*!\\nThis is **Markdown**.")
/// let html = wenk.render(blocks)
/// ```
///
/// # Supported Markdown Features
/// - Headings: Lines starting with one or more `#` characters (e.g., `# Heading 1`)
/// - Paragraphs: Any non-empty line not matching another block type
/// - Unordered Lists: Lines starting with `* `, `- `, or `+ `
/// - Ordered Lists: Lines starting with a number and `. ` (e.g., `1. Item`)
/// - Fenced Code Blocks: Lines surrounded by triple backticks (```), content is not parsed for inlines
/// - Inline formatting: Bold (`**bold**`), Italic (`*italic*`), etc. via `wenk/inline_parser`
///
/// # Types
/// - `Block`: Represents a block-level Markdown element (see below)
/// - `ParseState`: Internal state for block parsing
/// - `RenderState`: Internal state for rendering ordered lists
/// # Limitations
/// - Not all edge cases of the full Markdown spec are supported.
/// - Only asterisks (`*`, `**`) are recognized for bold and italic (no underscores).
/// - Inline escaping (e.g., `\\*`) is not supported.
/// - No support for blockquotes, links, images, or code spans (yet).
/// - Heading levels above 6 are not limited and will render as `<hN>`.
import gleam/int
import gleam/list
import gleam/order.{Eq, Gt, Lt}
import gleam/string
import wenk/inline_parser

/// Represents a block-level Markdown element.
pub type Block {
  /// A paragraph of text.
  Paragraph(List(inline_parser.Inline))
  /// A heading with a specific level and inline content.
  Heading(Int, List(inline_parser.Inline))
  /// An unordered list item.
  ListItem(List(inline_parser.Inline))
  /// An ordered list item.
  OrderedListItem(List(inline_parser.Inline))
  /// A fenced code block.
  CodeBlock(String)
}

/// Parse a Markdown string into a list of block elements.
///
/// Splits the input string into lines and parses each line into a block element.
/// Returns a list of `Block` values representing the Markdown structure.
///
/// # Example
/// ```gleam
/// let blocks = wenk.parse("# Title\\nSome text")
/// ```
pub fn parse(text: String) -> List(Block) {
  let lines = string.split(text, "\n")
  parse_blocks_recursive(lines, [], Normal)
}

/// Recursively parses lines of Markdown into blocks.
///
/// - Handles code blocks using the `ParseState`.
/// - Ignores empty lines.
/// - Delegates line parsing to `parse_line`.
fn parse_blocks_recursive(
  lines: List(String),
  acc: List(Block),
  state: ParseState,
) -> List(Block) {
  case lines {
    [] -> {
      case state {
        InCodeBlock(code_lines) ->
          list.append(acc, [CodeBlock(string.join(code_lines, "\n"))])
        Normal -> acc
      }
    }
    [head, ..tail] -> {
      case state {
        Normal -> {
          case string.starts_with(head, "```") {
            True -> parse_blocks_recursive(tail, acc, InCodeBlock([]))
            False -> {
              case string.trim(head) == "" {
                True -> parse_blocks_recursive(tail, acc, Normal)
                False -> {
                  let block = parse_line(head)
                  parse_blocks_recursive(
                    tail,
                    list.append(acc, [block]),
                    Normal,
                  )
                }
              }
            }
          }
        }
        InCodeBlock(code_lines) -> {
          case string.starts_with(head, "```") {
            True -> {
              let code_block = CodeBlock(string.join(code_lines, "\n"))
              parse_blocks_recursive(
                tail,
                list.append(acc, [code_block]),
                Normal,
              )
            }
            False -> {
              parse_blocks_recursive(
                tail,
                acc,
                InCodeBlock(list.append(code_lines, [head])),
              )
            }
          }
        }
      }
    }
  }
}

/// Internal state for parsing blocks.
type ParseState {
  /// Not currently in a code block.
  Normal
  /// Currently inside a code block, accumulating lines.
  InCodeBlock(List(String))
}

/// Render a list of block elements as an HTML string.
///
/// Wraps ordered lists in `<ol>` tags as needed.
/// Returns the HTML string for the entire Markdown document.
///
/// # Example
/// ```gleam
/// let html = wenk.render([wenk.Heading(1, [wenk.inline_parser.Text("Title")])])
/// // html == "<h1>Title</h1>"
/// ```
pub fn render(blocks: List(Block)) -> String {
  render_blocks_recursive(blocks, [], NotInOrderedList)
  |> string.join("")
}

/// Recursively renders blocks to HTML, handling ordered list state.
///
/// - Opens and closes `<ol>` tags as needed.
/// - Delegates block rendering to `render_block`.
fn render_blocks_recursive(
  blocks: List(Block),
  acc: List(String),
  state: RenderState,
) -> List(String) {
  case blocks {
    [] -> {
      case state {
        InOrderedList -> list.append(acc, ["</ol>"])
        _ -> acc
      }
    }
    [head, ..tail] -> {
      case head {
        OrderedListItem(_) -> {
          case state {
            NotInOrderedList -> {
              let new_acc = list.append(acc, ["<ol>", render_block(head)])
              render_blocks_recursive(tail, new_acc, InOrderedList)
            }
            InOrderedList -> {
              let new_acc = list.append(acc, [render_block(head)])
              render_blocks_recursive(tail, new_acc, InOrderedList)
            }
          }
        }
        _ -> {
          case state {
            InOrderedList -> {
              let new_acc = list.append(acc, ["</ol>", render_block(head)])
              render_blocks_recursive(tail, new_acc, NotInOrderedList)
            }
            NotInOrderedList -> {
              let new_acc = list.append(acc, [render_block(head)])
              render_blocks_recursive(tail, new_acc, NotInOrderedList)
            }
          }
        }
      }
    }
  }
}

/// Internal state for rendering ordered lists.
type RenderState {
  /// Currently inside an ordered list.
  InOrderedList
  /// Not inside an ordered list.
  NotInOrderedList
}

/// Render a single inline element as HTML.
///
/// Delegates to the appropriate HTML tag for bold and italic.
/// Returns the HTML string for the inline element.
pub fn render_inline(inline: inline_parser.Inline) -> String {
  case inline {
    inline_parser.Text(text) -> text
    inline_parser.Bold(inlines) ->
      "<strong>"
      <> list.map(inlines, render_inline) |> string.join("")
      <> "</strong>"
    inline_parser.Italic(inlines) ->
      "<em>" <> list.map(inlines, render_inline) |> string.join("") <> "</em>"
  }
}

/// Render a single block as HTML.
///
/// - Paragraphs are wrapped in `<p>`.
/// - Headings use `<h1>` to `<h6>`.
/// - List items use `<li>`.
/// - Code blocks use `<pre><code>`.
/// - Delegates inline rendering to `render_inline`.
pub fn render_block(block: Block) -> String {
  case block {
    Paragraph(inlines) ->
      "<p>" <> list.map(inlines, render_inline) |> string.join("") <> "</p>"
    Heading(level, inlines) ->
      "<h"
      <> int.to_string(level)
      <> ">"
      <> list.map(inlines, render_inline) |> string.join("")
      <> "</h"
      <> int.to_string(level)
      <> ">"
    ListItem(inlines) ->
      "<li>" <> list.map(inlines, render_inline) |> string.join("") <> "</li>"
    OrderedListItem(inlines) ->
      "<li>" <> list.map(inlines, render_inline) |> string.join("") <> "</li>"
    CodeBlock(code) -> "<pre><code>" <> code <> "</code></pre>"
  }
}

/// Parse a single line of Markdown into a block element.
///
/// - Headings: Lines starting with `#` (level determined by number of `#`)
/// - Unordered lists: Lines starting with `* `, `- `, or `+ `
/// - Ordered lists: Lines starting with a number and `. `
/// - Otherwise, treated as a paragraph.
///
/// Delegates inline parsing to `wenk/inline_parser`.
pub fn parse_line(line: String) -> Block {
  case string.starts_with(line, "#") {
    True -> {
      let level = get_heading_level(line, 0)
      let rest = string.slice(line, level, string.length(line))
      let text = string.trim(rest)
      Heading(level, inline_parser.parse_inlines(text))
    }
    False -> {
      case
        string.starts_with(line, "* ")
        || string.starts_with(line, "- ")
        || string.starts_with(line, "+ ")
      {
        True -> {
          let text = string.slice(line, 2, string.length(line))
          ListItem(inline_parser.parse_inlines(text))
        }
        False -> {
          let parts = string.split(line, ". ")
          case parts {
            [number_str, rest] -> {
              case int.parse(number_str) {
                Ok(_) -> OrderedListItem(inline_parser.parse_inlines(rest))
                _ -> Paragraph(inline_parser.parse_inlines(line))
              }
            }
            _ -> Paragraph(inline_parser.parse_inlines(line))
          }
        }
      }
    }
  }
}

/// Helper to determine the heading level by counting leading `#` characters.
///
/// Returns the number of `#` at the start of the line.
fn get_heading_level(line: String, level: Int) -> Int {
  case int.compare(string.length(line), level) {
    Gt -> {
      case string.slice(line, level, 1) {
        "#" -> get_heading_level(line, level + 1)
        _ -> level
      }
    }
    Eq -> level
    Lt -> level
  }
}
