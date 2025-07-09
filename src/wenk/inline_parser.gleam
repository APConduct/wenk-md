/// Markdown inline parser.
/// Parses inline elements (bold, italic, text) from a string.
/// Used internally by the main Markdown parser.
///
/// # Supported Inline Elements
/// - **Bold**: Text wrapped in double asterisks (`**bold**`)
/// - *Italic*: Text wrapped in single asterisks (`*italic*`)
/// - Plain text: Any text not wrapped in delimiters
///
/// # Nesting
/// Bold and italic can be nested inside each other, e.g. `**bold *italic***`.
///
/// # Limitations
/// - Only asterisks (`*`, `**`) are supported as delimiters (no underscores).
/// - Escaping delimiters is not supported.
/// - Delimiters must be properly closed; unmatched delimiters are treated as plain text.
///
/// # Example
/// ```gleam
/// import wenk/inline_parser
///
/// let parsed = inline_parser.parse_inlines("Hello **world *foo***!")
/// // Result: [Text("Hello "), Bold([Text("world "), Italic([Text("foo")])]), Text("!")]
/// ```
import gleam/int
import gleam/list
import gleam/option
import gleam/order.{Eq, Gt}
import gleam/string

/// Represents an inline Markdown element.
pub type Inline {
  /// Plain text.
  Text(String)
  /// Bold text.
  Bold(List(Inline))
  /// Italic text.
  Italic(List(Inline))
}

/// Internal type representing the kind of delimiter found.
type DelimiterType {
  /// Bold delimiter: `**`
  BoldDelimiter
  /// Italic delimiter: `*`
  ItalicDelimiter
}

/// Find the first occurrence of a substring in a string.
/// Returns `Ok(index)` if found, or `Error(Nil)` if not found.
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

/// Helper for `find_first_occurrence`, recursively searches for the substring.
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

/// Finds the next delimiter (`**` or `*`) in the text.
/// Returns the delimiter type and its index, or `Error(Nil)` if none found.
fn find_next_delimiter(text: String) -> Result(#(DelimiterType, Int), Nil) {
  let bold_occurrence = find_first_occurrence(text, "**")
  let italic_occurrence = find_first_occurrence(text, "*")

  case bold_occurrence, italic_occurrence {
    Ok(b_idx), Ok(i_idx) -> {
      case int.compare(b_idx, i_idx) {
        Gt -> Ok(#(ItalicDelimiter, i_idx))
        _ -> Ok(#(BoldDelimiter, b_idx))
      }
    }
    Ok(b_idx), _ -> Ok(#(BoldDelimiter, b_idx))
    _, Ok(i_idx) -> Ok(#(ItalicDelimiter, i_idx))
    _, _ -> Error(Nil)
  }
}

/// Returns the length of the delimiter: 2 for bold, 1 for italic.
fn delimiter_length(delimiter_type: DelimiterType) -> Int {
  case delimiter_type {
    BoldDelimiter -> 2
    ItalicDelimiter -> 1
  }
}

/// Parse a string into a list of inline elements (text, bold, italic).
/// Returns a list of `Inline` elements representing the parsed structure.
///
/// # Example
/// ```gleam
/// parse_inlines("**bold** and *italic* text")
/// // => [Bold([Text("bold")]), Text(" and "), Italic([Text("italic")]), Text(" text")]
/// ```
pub fn parse_inlines(text: String) -> List(Inline) {
  let #(inlines, _) = parse_inlines_recursive(text, option.None)
  inlines
}

/// Internal recursive parser for inline elements.
/// - `text`: the input string to parse
/// - `current_delimiter`: the delimiter context (if inside bold/italic)
/// Returns a tuple: (parsed inlines, remaining text after closing delimiter)
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

      case current_delimiter {
        option.Some(inner) -> {
          case inner == delimiter_type {
            True -> {
              case index == 0 {
                True ->
                  // Found closing delimiter for current context, return inlines up to here
                  #([], after_delimiter_text)
                False -> {
                  // Same delimiter, but not at start: treat up to delimiter as plain text, then continue parsing from the delimiter (not skipping it)
                  let before = string.slice(text, 0, index)
                  let after = string.slice(text, index, string.length(text))
                  let parsed_before = case string.length(before) > 0 {
                    True -> [Text(before)]
                    False -> []
                  }
                  let #(rest_inlines, final_remaining_text) =
                    parse_inlines_recursive(after, current_delimiter)
                  #(
                    list.append(parsed_before, rest_inlines),
                    final_remaining_text,
                  )
                }
              }
            }
            False -> {
              // Nested context for different delimiter
              let parsed_before_inlines = case string.length(before_text) > 0 {
                True -> [Text(before_text)]
                False -> []
              }
              let #(nested_inlines, remaining_after_nested) =
                parse_inlines_recursive(
                  after_delimiter_text,
                  option.Some(delimiter_type),
                )
              let new_inline = case delimiter_type {
                BoldDelimiter -> Bold(nested_inlines)
                ItalicDelimiter -> Italic(nested_inlines)
              }
              // Resume parsing with the current context, not as a new context
              let #(rest_inlines, final_remaining_text) =
                parse_inlines_recursive(
                  remaining_after_nested,
                  current_delimiter,
                )
              #(
                list.append(
                  list.append(parsed_before_inlines, [new_inline]),
                  rest_inlines,
                ),
                final_remaining_text,
              )
            }
          }
        }
        option.None -> {
          // Not inside any context
          let parsed_before_inlines = case string.length(before_text) > 0 {
            True -> [Text(before_text)]
            False -> []
          }
          // Check for a matching closing delimiter before recursing
          let closing_index_result =
            find_first_occurrence(after_delimiter_text, case delimiter_type {
              BoldDelimiter -> "**"
              ItalicDelimiter -> "*"
            })
          case closing_index_result {
            Ok(_) -> {
              let #(nested_inlines, remaining_after_nested) =
                parse_inlines_recursive(
                  after_delimiter_text,
                  option.Some(delimiter_type),
                )
              let new_inline = case delimiter_type {
                BoldDelimiter -> Bold(nested_inlines)
                ItalicDelimiter -> Italic(nested_inlines)
              }
              let #(rest_inlines, final_remaining_text) =
                parse_inlines_recursive(
                  remaining_after_nested,
                  current_delimiter,
                )
              #(
                list.append(
                  list.append(parsed_before_inlines, [new_inline]),
                  rest_inlines,
                ),
                final_remaining_text,
              )
            }
            Error(_) -> {
              // No closing delimiter found, treat delimiter and rest as plain text
              let delim = case delimiter_type {
                BoldDelimiter -> "**"
                ItalicDelimiter -> "*"
              }
              let as_text = before_text <> delim <> after_delimiter_text
              #([Text(as_text)], "")
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
