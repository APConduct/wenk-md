import gleam/string
import gleam/int
import gleam/order.{Gt}
import gleam/list

pub type Block {
  Paragraph(String)
  Heading(Int, String)
  ListItem(String)
}

pub fn parse(text: String) -> List(Block) {
  text
  |> string.split("\n")
  |> list.map(parse_line)
}

pub fn render(blocks: List(Block)) -> String {
  blocks
  |> list.map(render_block)
  |> string.join("")
}

pub fn render_block(block: Block) -> String {
  case block {
    Paragraph(text) -> "<p>" <> text <> "</p>"
    Heading(level, text) -> "<h" <> int.to_string(level) <> ">" <> text <> "</h" <> int.to_string(level) <> ">"
    ListItem(text) -> "<li>" <> text <> "</li>"
  }
}

pub fn parse_line(line: String) -> Block {
  case string.starts_with(line, "#") {
    True -> {
      let level = get_heading_level(line, 0)
      let rest = string.slice(line, level, string.length(line))
      let text = string.trim(rest)
      Heading(level, text)
    }
    False -> {
      case string.starts_with(line, "* ") || string.starts_with(line, "- ") || string.starts_with(line, "+ ") {
        True -> {
          let text = string.slice(line, 2, string.length(line))
          ListItem(text)
        }
        False -> Paragraph(line)
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
    _ -> level
  }
}