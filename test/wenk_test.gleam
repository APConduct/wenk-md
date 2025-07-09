import gleeunit
import gleeunit/should
import wenk
import wenk/inline_parser

pub fn main() {
  gleeunit.main()
}

pub fn parse_heading_level_1_test() {
  wenk.parse("# Heading 1")
  |> should.equal([wenk.Heading(1, [inline_parser.Text("Heading 1")])])
}

pub fn parse_heading_level_3_test() {
  wenk.parse("### Heading 3")
  |> should.equal([wenk.Heading(3, [inline_parser.Text("Heading 3")])])
}

pub fn parse_heading_with_leading_space_test() {
  wenk.parse("#  Heading with space")
  |> should.equal([wenk.Heading(1, [inline_parser.Text("Heading with space")])])
}

pub fn parse_list_item_with_star_test() {
  wenk.parse("* A list item")
  |> should.equal([wenk.ListItem([inline_parser.Text("A list item")])])
}

pub fn parse_list_item_with_minus_test() {
  wenk.parse("- A list item")
  |> should.equal([wenk.ListItem([inline_parser.Text("A list item")])])
}

pub fn parse_list_item_with_plus_test() {
  wenk.parse("+ A list item")
  |> should.equal([wenk.ListItem([inline_parser.Text("A list item")])])
}

pub fn parse_test() {
  let text =
    "# First heading\n\nA paragraph\n\n- A list item\n- Another list item"
  let expected = [
    wenk.Heading(1, [inline_parser.Text("First heading")]),
    wenk.Paragraph([inline_parser.Text("A paragraph")]),
    wenk.ListItem([inline_parser.Text("A list item")]),
    wenk.ListItem([inline_parser.Text("Another list item")]),
  ]
  wenk.parse(text)
  |> should.equal(expected)
}

pub fn render_paragraph_test() {
  wenk.render_block(
    wenk.Paragraph([inline_parser.Text("This is a paragraph.")]),
  )
  |> should.equal("<p>This is a paragraph.</p>")
}

pub fn render_heading_test() {
  wenk.render_block(wenk.Heading(2, [inline_parser.Text("A heading")]))
  |> should.equal("<h2>A heading</h2>")
}

pub fn render_list_item_test() {
  wenk.render_block(wenk.ListItem([inline_parser.Text("A list item")]))
  |> should.equal("<li>A list item</li>")
}

pub fn render_test() {
  let blocks = [
    wenk.Heading(1, [inline_parser.Text("Title")]),
    wenk.Paragraph([inline_parser.Text("Some text.")]),
    wenk.ListItem([inline_parser.Text("Item 1")]),
    wenk.ListItem([inline_parser.Text("Item 2")]),
  ]
  let expected_html =
    "<h1>Title</h1><p>Some text.</p><li>Item 1</li><li>Item 2</li>"
  wenk.render(blocks)
  |> should.equal(expected_html)
}

pub fn parse_inlines_bold_test() {
  inline_parser.parse_inlines("This is **bold** text.")
  |> should.equal([
    inline_parser.Text("This is "),
    inline_parser.Bold([inline_parser.Text("bold")]),
    inline_parser.Text(" text."),
  ])
}

pub fn parse_inlines_italic_test() {
  inline_parser.parse_inlines("This is *italic* text.")
  |> should.equal([
    inline_parser.Text("This is "),
    inline_parser.Italic([inline_parser.Text("italic")]),
    inline_parser.Text(" text."),
  ])
}

pub fn render_bold_test() {
  wenk.render_inline(inline_parser.Bold([inline_parser.Text("bold")]))
  |> should.equal("<strong>bold</strong>")
}

pub fn render_italic_test() {
  wenk.render_inline(inline_parser.Italic([inline_parser.Text("italic")]))
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
  inline_parser.parse_inlines("**First** and **second**.")
  |> should.equal([
    inline_parser.Bold([inline_parser.Text("First")]),
    inline_parser.Text(" and "),
    inline_parser.Bold([inline_parser.Text("second")]),
    inline_parser.Text("."),
  ])
}

pub fn parse_inlines_multiple_italic_test() {
  inline_parser.parse_inlines("*First* and *second*.")
  |> should.equal([
    inline_parser.Italic([inline_parser.Text("First")]),
    inline_parser.Text(" and "),
    inline_parser.Italic([inline_parser.Text("second")]),
    inline_parser.Text("."),
  ])
}

pub fn parse_inlines_bold_and_italic_test() {
  inline_parser.parse_inlines("**Bold** and *italic*.")
  |> should.equal([
    inline_parser.Bold([inline_parser.Text("Bold")]),
    inline_parser.Text(" and "),
    inline_parser.Italic([inline_parser.Text("italic")]),
    inline_parser.Text("."),
  ])
}

pub fn parse_inlines_unmatched_bold_test() {
  inline_parser.parse_inlines("This is **unmatched bold.")
  |> should.equal([inline_parser.Text("This is **unmatched bold.")])
}

pub fn parse_inlines_unmatched_italic_test() {
  inline_parser.parse_inlines("This is *unmatched italic.")
  |> should.equal([inline_parser.Text("This is *unmatched italic.")])
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
    wenk.Heading(1, [inline_parser.Text("Title")]),
    wenk.CodeBlock("code line 1\ncode line 2"),
    wenk.Paragraph([inline_parser.Text("A paragraph after code.")]),
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
    wenk.OrderedListItem([inline_parser.Text("First item")]),
    wenk.OrderedListItem([inline_parser.Text("Second item")]),
  ]
  wenk.parse(markdown)
  |> should.equal(expected)
}

pub fn parse_ordered_list_with_paragraph_test() {
  let markdown = "1. First item\n\nThis is a paragraph.\n\n2. Second item"
  let expected = [
    wenk.OrderedListItem([inline_parser.Text("First item")]),
    wenk.Paragraph([inline_parser.Text("This is a paragraph.")]),
    wenk.OrderedListItem([inline_parser.Text("Second item")]),
  ]
  wenk.parse(markdown)
  |> should.equal(expected)
}

pub fn render_ordered_list_test() {
  let blocks = [
    wenk.OrderedListItem([inline_parser.Text("First item")]),
    wenk.OrderedListItem([inline_parser.Text("Second item")]),
  ]
  let expected_html = "<ol><li>First item</li><li>Second item</li></ol>"
  wenk.render(blocks)
  |> should.equal(expected_html)
}

pub fn render_mixed_list_test() {
  let blocks = [
    wenk.ListItem([inline_parser.Text("Unordered item")]),
    wenk.OrderedListItem([inline_parser.Text("Ordered item 1")]),
    wenk.OrderedListItem([inline_parser.Text("Ordered item 2")]),
    wenk.ListItem([inline_parser.Text("Another unordered item")]),
  ]
  let expected_html =
    "<li>Unordered item</li><ol><li>Ordered item 1</li><li>Ordered item 2</li></ol><li>Another unordered item</li>"
  wenk.render(blocks)
  |> should.equal(expected_html)
}

pub fn parse_inlines_nested_bold_italic_test() {
  inline_parser.parse_inlines("**bold *italic* text**")
  |> should.equal([
    inline_parser.Bold([
      inline_parser.Text("bold "),
      inline_parser.Italic([inline_parser.Text("italic")]),
      inline_parser.Text(" text"),
    ]),
  ])
}

pub fn parse_inlines_nested_italic_bold_test() {
  inline_parser.parse_inlines("*italic **bold** text*")
  |> should.equal([
    inline_parser.Italic([
      inline_parser.Text("italic "),
      inline_parser.Bold([inline_parser.Text("bold")]),
      inline_parser.Text(" text"),
    ]),
  ])
}

pub fn parse_inlines_multiple_nested_test() {
  inline_parser.parse_inlines(
    "**outer *inner* outer** and *another **one** here*.",
  )
  |> should.equal([
    inline_parser.Bold([
      inline_parser.Text("outer "),
      inline_parser.Italic([inline_parser.Text("inner")]),
      inline_parser.Text(" outer"),
    ]),
    inline_parser.Text(" and "),
    inline_parser.Italic([
      inline_parser.Text("another "),
      inline_parser.Bold([inline_parser.Text("one")]),
      inline_parser.Text(" here"),
    ]),
    inline_parser.Text("."),
  ])
}
