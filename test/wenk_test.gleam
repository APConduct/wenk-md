import gleeunit
import gleeunit/should
import wenk

pub fn main() {
  gleeunit.main()
}

pub fn parse_heading_level_1_test() {
  wenk.parse("# Heading 1")
  |> should.equal([wenk.Heading(1, [wenk.Text("Heading 1")])])
}

pub fn parse_heading_level_3_test() {
  wenk.parse("### Heading 3")
  |> should.equal([wenk.Heading(3, [wenk.Text("Heading 3")])])
}

pub fn parse_heading_with_leading_space_test() {
  wenk.parse("#  Heading with space")
  |> should.equal([wenk.Heading(1, [wenk.Text("Heading with space")])])
}

pub fn parse_list_item_with_star_test() {
  wenk.parse("* A list item")
  |> should.equal([wenk.ListItem([wenk.Text("A list item")])])
}

pub fn parse_list_item_with_minus_test() {
  wenk.parse("- A list item")
  |> should.equal([wenk.ListItem([wenk.Text("A list item")])])
}

pub fn parse_list_item_with_plus_test() {
  wenk.parse("+ A list item")
  |> should.equal([wenk.ListItem([wenk.Text("A list item")])])
}

pub fn parse_test() {
  let text =
    "# First heading\n\nA paragraph\n\n- A list item\n- Another list item"
  let expected = [
    wenk.Heading(1, [wenk.Text("First heading")]),
    wenk.Paragraph([wenk.Text("A paragraph")]),
    wenk.ListItem([wenk.Text("A list item")]),
    wenk.ListItem([wenk.Text("Another list item")]),
  ]
  wenk.parse(text)
  |> should.equal(expected)
}

pub fn render_paragraph_test() {
  wenk.render_block(wenk.Paragraph([wenk.Text("This is a paragraph.")]))
  |> should.equal("<p>This is a paragraph.</p>")
}

pub fn render_heading_test() {
  wenk.render_block(wenk.Heading(2, [wenk.Text("A heading")]))
  |> should.equal("<h2>A heading</h2>")
}

pub fn render_list_item_test() {
  wenk.render_block(wenk.ListItem([wenk.Text("A list item")]))
  |> should.equal("<li>A list item</li>")
}

pub fn render_test() {
  let blocks = [
    wenk.Heading(1, [wenk.Text("Title")]),
    wenk.Paragraph([wenk.Text("Some text.")]),
    wenk.ListItem([wenk.Text("Item 1")]),
    wenk.ListItem([wenk.Text("Item 2")]),
  ]
  let expected_html =
    "<h1>Title</h1><p>Some text.</p><li>Item 1</li><li>Item 2</li>"
  wenk.render(blocks)
  |> should.equal(expected_html)
}

pub fn parse_inlines_bold_test() {
  wenk.parse_inlines("This is **bold** text.")
  |> should.equal([
    wenk.Text("This is "),
    wenk.Bold([wenk.Text("bold")]),
    wenk.Text(" text."),
  ])
}

pub fn parse_inlines_italic_test() {
  wenk.parse_inlines("This is *italic* text.")
  |> should.equal([
    wenk.Text("This is "),
    wenk.Italic([wenk.Text("italic")]),
    wenk.Text(" text."),
  ])
}

pub fn render_bold_test() {
  wenk.render_inline(wenk.Bold([wenk.Text("bold")]))
  |> should.equal("<strong>bold</strong>")
}

pub fn render_italic_test() {
  wenk.render_inline(wenk.Italic([wenk.Text("italic")]))
  |> should.equal("<em>italic</em>")
}

pub fn parse_and_render_bold_test() {
  let markdown = "This is **bold**."
  let expected_html = "<p>This is <strong>bold</strong>.</p>"
  wenk.parse(markdown)
  |> wenk.render
  |> should.equal(expected_html)
}

pub fn parse_and_render_italic_test() {
  let markdown = "This is *italic*."
  let expected_html = "<p>This is <em>italic</em>.</p>"
  wenk.parse(markdown)
  |> wenk.render
  |> should.equal(expected_html)
}

pub fn parse_inlines_multiple_bold_test() {
  wenk.parse_inlines("**First** and **second**.")
  |> should.equal([
    wenk.Bold([wenk.Text("First")]),
    wenk.Text(" and "),
    wenk.Bold([wenk.Text("second")]),
    wenk.Text("."),
  ])
}

pub fn parse_inlines_multiple_italic_test() {
  wenk.parse_inlines("*First* and *second*.")
  |> should.equal([
    wenk.Italic([wenk.Text("First")]),
    wenk.Text(" and "),
    wenk.Italic([wenk.Text("second")]),
    wenk.Text("."),
  ])
}

pub fn parse_inlines_bold_and_italic_test() {
  wenk.parse_inlines("**Bold** and *italic*.")
  |> should.equal([
    wenk.Bold([wenk.Text("Bold")]),
    wenk.Text(" and "),
    wenk.Italic([wenk.Text("italic")]),
    wenk.Text("."),
  ])
}

pub fn parse_inlines_unmatched_bold_test() {
  wenk.parse_inlines("This is **unmatched bold.")
  |> should.equal([wenk.Text("This is **unmatched bold.")])
}

pub fn parse_inlines_unmatched_italic_test() {
  wenk.parse_inlines("This is *unmatched italic.")
  |> should.equal([wenk.Text("This is *unmatched italic.")])
}

pub fn parse_fenced_code_block_test() {
  let markdown = "```\nfunc main() {\n  println(\"Hello\")\n}\n```"
  let expected = [wenk.CodeBlock("func main() {\n  println(\"Hello\")\n}")]
  wenk.parse(markdown)
  |> should.equal(expected)
}

pub fn parse_fenced_code_block_with_info_string_test() {
  let markdown =
    "```gleam\nimport gleam/io\n\npub fn main() {\n  io.println(\"Hello\")\n}\n```"
  let expected = [
    wenk.CodeBlock(
      "import gleam/io\n\npub fn main() {\n  io.println(\"Hello\")\n}",
    ),
  ]
  wenk.parse(markdown)
  |> should.equal(expected)
}

pub fn parse_multiple_blocks_with_code_test() {
  let markdown =
    "# Title\n\n```\ncode line 1\ncode line 2\n```\n\nA paragraph after code."
  let expected = [
    wenk.Heading(1, [wenk.Text("Title")]),
    wenk.CodeBlock("code line 1\ncode line 2"),
    wenk.Paragraph([wenk.Text("A paragraph after code.")]),
  ]
  wenk.parse(markdown)
  |> should.equal(expected)
}

pub fn render_code_block_test() {
  wenk.render_block(wenk.CodeBlock("some code"))
  |> should.equal("<pre><code>some code</code></pre>")
}

pub fn parse_and_render_code_block_test() {
  let markdown = "```\nfunc main() {\n  println(\"Hello\")\n}\n```"
  let expected_html =
    "<pre><code>func main() {\n  println(\"Hello\")\n}</code></pre>"
  wenk.parse(markdown)
  |> wenk.render
  |> should.equal(expected_html)
}

pub fn parse_ordered_list_test() {
  let markdown = "1. First item\n2. Second item"
  let expected = [
    wenk.OrderedListItem([wenk.Text("First item")]),
    wenk.OrderedListItem([wenk.Text("Second item")]),
  ]
  wenk.parse(markdown)
  |> should.equal(expected)
}

pub fn parse_ordered_list_with_paragraph_test() {
  let markdown = "1. First item\n\nThis is a paragraph.\n\n2. Second item"
  let expected = [
    wenk.OrderedListItem([wenk.Text("First item")]),
    wenk.Paragraph([wenk.Text("This is a paragraph.")]),
    wenk.OrderedListItem([wenk.Text("Second item")]),
  ]
  wenk.parse(markdown)
  |> should.equal(expected)
}

pub fn render_ordered_list_test() {
  let blocks = [
    wenk.OrderedListItem([wenk.Text("First item")]),
    wenk.OrderedListItem([wenk.Text("Second item")]),
  ]
  let expected_html = "<ol><li>First item</li><li>Second item</li></ol>"
  wenk.render(blocks)
  |> should.equal(expected_html)
}

pub fn render_mixed_list_test() {
  let blocks = [
    wenk.ListItem([wenk.Text("Unordered item")]),
    wenk.OrderedListItem([wenk.Text("Ordered item 1")]),
    wenk.OrderedListItem([wenk.Text("Ordered item 2")]),
    wenk.ListItem([wenk.Text("Another unordered item")]),
  ]
  let expected_html =
    "<li>Unordered item</li><ol><li>Ordered item 1</li><li>Ordered item 2</li></ol><li>Another unordered item</li>"
  wenk.render(blocks)
  |> should.equal(expected_html)
}

pub fn parse_inlines_nested_bold_italic_test() {
  wenk.parse_inlines("**bold *italic* text**")
  |> should.equal([
    wenk.Bold([
      wenk.Text("bold "),
      wenk.Italic([wenk.Text("italic")]),
      wenk.Text(" text"),
    ]),
  ])
}

pub fn parse_inlines_nested_italic_bold_test() {
  wenk.parse_inlines("*italic **bold** text*")
  |> should.equal([
    wenk.Italic([
      wenk.Text("italic "),
      wenk.Bold([wenk.Text("bold")]),
      wenk.Text(" text"),
    ]),
  ])
}

pub fn parse_inlines_multiple_nested_test() {
  wenk.parse_inlines("**outer *inner* outer** and *another **one** here*.")
  |> should.equal([
    wenk.Bold([
      wenk.Text("outer "),
      wenk.Italic([wenk.Text("inner")]),
      wenk.Text(" outer"),
    ]),
    wenk.Text(" and "),
    wenk.Italic([
      wenk.Text("another "),
      wenk.Bold([wenk.Text("one")]),
      wenk.Text(" here"),
    ]),
    wenk.Text("."),
  ])
}
