import gleeunit
import gleeunit/should
import wenk

pub fn main() {
  gleeunit.main()
}

pub fn parse_paragraph_test() {
  wenk.parse_line("This is a paragraph.")
  |> should.equal(wenk.Paragraph("This is a paragraph."))
}

pub fn parse_heading_level_1_test() {
  wenk.parse_line("# Heading 1")
  |> should.equal(wenk.Heading(1, "Heading 1"))
}

pub fn parse_heading_level_3_test() {
  wenk.parse_line("### Heading 3")
  |> should.equal(wenk.Heading(3, "Heading 3"))
}

pub fn parse_heading_with_leading_space_test() {
  wenk.parse_line("#  Heading with space")
  |> should.equal(wenk.Heading(1, "Heading with space"))
}

pub fn parse_list_item_with_star_test() {
  wenk.parse_line("* A list item")
  |> should.equal(wenk.ListItem("A list item"))
}

pub fn parse_list_item_with_minus_test() {
  wenk.parse_line("- A list item")
  |> should.equal(wenk.ListItem("A list item"))
}

pub fn parse_list_item_with_plus_test() {
  wenk.parse_line("+ A list item")
  |> should.equal(wenk.ListItem("A list item"))
}

pub fn parse_test() {
  let text = "# First heading\n\nA paragraph\n\n- A list item\n- Another list item"
  let expected = [
    wenk.Heading(1, "First heading"),
    wenk.Paragraph(""),
    wenk.Paragraph("A paragraph"),
    wenk.Paragraph(""),
    wenk.ListItem("A list item"),
    wenk.ListItem("Another list item"),
  ]
  wenk.parse(text)
  |> should.equal(expected)
}

pub fn render_paragraph_test() {
  wenk.render_block(wenk.Paragraph("This is a paragraph."))
  |> should.equal("<p>This is a paragraph.</p>")
}

pub fn render_heading_test() {
  wenk.render_block(wenk.Heading(2, "A heading"))
  |> should.equal("<h2>A heading</h2>")
}

pub fn render_list_item_test() {
  wenk.render_block(wenk.ListItem("A list item"))
  |> should.equal("<li>A list item</li>")
}

pub fn render_test() {
  let blocks = [
    wenk.Heading(1, "Title"),
    wenk.Paragraph("Some text."),
    wenk.ListItem("Item 1"),
    wenk.ListItem("Item 2"),
  ]
  let expected_html = "<h1>Title</h1><p>Some text.</p><li>Item 1</li><li>Item 2</li>"
  wenk.render(blocks)
  |> should.equal(expected_html)
}
