import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/order.{Eq, Gt, Lt}
import gleam/string

pub type Inline {
  Text(String)
  Bold(List(Inline))
  Italic(List(Inline))
}

pub type Block {
  Paragraph(List(Inline))
  Heading(Int, List(Inline))
  ListItem(List(Inline))
  OrderedListItem(List(Inline))
  CodeBlock(String)
}

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

pub fn render_inline(inline: Inline) -> String {
  case inline {
    Text(text) -> text
    Bold(inlines) ->
      "<strong>"
      <> list.map(inlines, render_inline) |> string.join("")
      <> "</strong>"
    Italic(inlines) ->
      "<em>" <> list.map(inlines, render_inline) |> string.join("") <> "</em>"
  }
}

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

pub fn parse_inlines(text: String) -> List(Inline) {
  let #(inlines, _) = parse_inlines_recursive(text, option.None)
  inlines
}

type DelimiterType {
  BoldDelimiter
  ItalicDelimiter
}

fn find_first_occurrence(text: String, sub: String) -> Result(Int, Nil) {
  let text_length = string.length(text)
  let sub_length = string.length(sub)

  case int.compare(text_length, sub_length) {
    Gt -> {
      let max_index = text_length - sub_length
      find_first_occurrence_recursive(text, sub, 0, max_index)
    }
    Eq -> {
      case text == sub {
        True -> Ok(0)
        False -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn find_first_occurrence_recursive(
  text: String,
  sub: String,
  index: Int,
  max_index: Int,
) -> Result(Int, Nil) {
  case int.compare(index, max_index) {
    Gt -> Error(Nil)
    _ -> {
      let current_slice = string.slice(text, index, string.length(sub))
      case current_slice == sub {
        True -> Ok(index)
        False ->
          find_first_occurrence_recursive(text, sub, index + 1, max_index)
      }
    }
  }
}

fn find_next_delimiter(text: String) -> Result(#(DelimiterType, Int), Nil) {
  let bold_occurrence = find_first_occurrence(text, "**")
  let italic_occurrence = find_first_occurrence(text, "*")

  case bold_occurrence, italic_occurrence {
    Ok(b_idx), Ok(i_idx) -> {
      case int.compare(b_idx, i_idx) {
        order.Lt -> Ok(#(BoldDelimiter, b_idx))
        order.Eq -> Ok(#(BoldDelimiter, b_idx))
        order.Gt -> Ok(#(ItalicDelimiter, i_idx))
      }
    }
    Ok(b_idx), _ -> {
      Ok(#(BoldDelimiter, b_idx))
    }
    // Only bold found
    _, Ok(i_idx) -> {
      Ok(#(ItalicDelimiter, i_idx))
    }
    // Only italic found
    _, _ -> {
      Error(Nil)
    }
    // No delimiters found
  }
}

fn delimiter_length(delimiter_type: DelimiterType) -> Int {
  case delimiter_type {
    BoldDelimiter -> 2
    ItalicDelimiter -> 1
  }
}

fn parse_inlines_recursive(
  text: String,
  current_delimiter: option.Option(DelimiterType),
) -> #(List(Inline), String) {
  case find_next_delimiter(text) {
    Ok(#(delimiter_type, index)) -> {
      let delimiter_len = delimiter_length(delimiter_type)
      let before_text = string.slice(text, 0, index)
      let after_delimiter_text =
        string.slice(text, index + delimiter_len, string.length(text))

      // If we're inside a delimiter, check if this is a closing delimiter at the start
      case current_delimiter {
        option.Some(inner) if inner == delimiter_type && index == 0 -> {
          // Found closing delimiter for current context
          #([], after_delimiter_text)
        }
        _ -> {
          // If this is an opening delimiter, search for the next matching closing delimiter
          let closing_index_result =
            find_first_occurrence(after_delimiter_text, case delimiter_type {
              BoldDelimiter -> "**"
              ItalicDelimiter -> "*"
            })
          case closing_index_result {
            Ok(closing_index) -> {
              // Found a closing delimiter, parse inside as a block
              let inside_text =
                string.slice(after_delimiter_text, 0, closing_index)
              let after_closing =
                string.slice(
                  after_delimiter_text,
                  closing_index + delimiter_len,
                  string.length(after_delimiter_text),
                )
              let parsed_before_inlines = case string.length(before_text) > 0 {
                True -> [Text(before_text)]
                False -> []
              }
              let parsed_inside =
                parse_inlines_recursive(inside_text, option.None).0
              let new_inline = case delimiter_type {
                BoldDelimiter -> Bold(parsed_inside)
                ItalicDelimiter -> Italic(parsed_inside)
              }
              let #(rest_inlines, final_remaining_text) =
                parse_inlines_recursive(after_closing, current_delimiter)
              #(
                list.append(
                  list.append(parsed_before_inlines, [new_inline]),
                  rest_inlines,
                ),
                final_remaining_text,
              )
            }
            Error(_) -> {
              // No closing delimiter found, treat everything from this delimiter as plain text (including before_text)
              let whole_text = string.slice(text, 0, string.length(text))
              #([Text(whole_text)], "")
            }
          }
        }
      }
    }
    _ -> {
      // No more delimiters, add remaining text as plain text
      #(
        case string.length(text) > 0 {
          True -> [Text(text)]
          False -> []
        },
        "",
      )
    }
  }
}

pub fn parse_line(line: String) -> Block {
  case string.starts_with(line, "#") {
    True -> {
      let level = get_heading_level(line, 0)
      let rest = string.slice(line, level, string.length(line))
      let text = string.trim(rest)
      Heading(level, parse_inlines(text))
    }
    False -> {
      case
        string.starts_with(line, "* ")
        || string.starts_with(line, "- ")
        || string.starts_with(line, "+ ")
      {
        True -> {
          let text = string.slice(line, 2, string.length(line))
          ListItem(parse_inlines(text))
        }
        False -> {
          let parts = string.split(line, ". ")
          case parts {
            [number_str, rest] -> {
              case int.parse(number_str) {
                Ok(_) -> OrderedListItem(parse_inlines(rest))
                _ -> Paragraph(parse_inlines(line))
              }
            }
            _ -> Paragraph(parse_inlines(line))
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
