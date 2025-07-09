/// Markdown block parser and renderer.
/// Provides functions to parse Markdown text into block elements and render them as HTML.
/// Delegates inline parsing to `wenk/inline_parser`.
///
/// Example:
/// ```gleam
/// import wenk
/// let blocks = wenk.parse("# Hello, *world*!\\nThis is **Markdown**.")
/// let html = wenk.render(blocks)
/// ```
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
pub fn parse(text: String) -> List(Block) {
  let lines = string.split(text, "\n")
  parse_blocks_recursive(lines, [], Normal)
}

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

type ParseState {
  Normal
  InCodeBlock(List(String))
}

/// Render a list of block elements as an HTML string.
pub fn render(blocks: List(Block)) -> String {
  render_blocks_recursive(blocks, [], NotInOrderedList)
  |> string.join("")
}

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

type RenderState {
  InOrderedList
  NotInOrderedList
}

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

/// Render a single inline element as HTML.
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
