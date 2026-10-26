import etui/buffer
import etui/geometry.{Position}
import etui/span
import etui/style
import etui/widgets/paragraph
import gleam/list
import gleeunit/should

pub fn string_controls_do_not_consume_cells_test() {
  let area = geometry.rect_new(0, 0, 4, 2)
  let s = style.bold_style()
  list.each(
    [
      "\n",
      "\r",
      "\r\n",
      "\t",
      "\u{0}",
      "\u{7}",
      "\u{8}",
      "\u{1b}",
      "\u{1f}",
      "\u{7f}",
    ],
    fn(control) {
      let actual =
        buffer.buffer_new(area)
        |> buffer.set_string_linked(
          Position(0, 0),
          control <> "a" <> control <> "漢" <> control <> "b!",
          s,
          "https://example.com",
        )
      let expected =
        buffer.buffer_new(area)
        |> buffer.set_string_linked(
          Position(0, 0),
          "a漢b!",
          s,
          "https://example.com",
        )
      buffer.diff(expected, actual) |> should.equal([])
      buffer.to_ansi(actual) |> should.equal(buffer.to_ansi(expected))
    },
  )
}

pub fn filled_buffer_skips_controls_on_every_row_test() {
  let area = geometry.rect_new(0, 0, 4, 2)
  let s = style.bold_style()
  let actual = buffer.buffer_new_filled(area, "a\r\n漢\tb", s)
  let expected = buffer.buffer_new_filled(area, "a漢b", s)
  buffer.diff(expected, actual) |> should.equal([])
}

// Issue #11: a newline inside a styled span must never reach the terminal
// or leave the next span / next frame at the wrong position.
pub fn styled_paragraph_newlines_do_not_move_the_terminal_cursor_test() {
  let area = geometry.rect_new(0, 0, 30, 1)
  let s = style.bold_style()
  let actual =
    buffer.buffer_new(area)
    |> paragraph.render_styled(area, [
      span.line_new([
        span.span_styled("something\r\nwith new lines", s),
        span.span_plain("!"),
      ]),
    ])
  let expected =
    buffer.buffer_new(area)
    |> paragraph.render_styled(area, [
      span.line_new([
        span.span_styled("somethingwith new lines", s),
        span.span_plain("!"),
      ]),
    ])
  buffer.to_ansi(actual) |> should.equal(buffer.to_ansi(expected))
  let next =
    buffer.buffer_new(area)
    |> paragraph.render_styled(area, [span.line_plain("ok")])
  buffer.diff_to_ansi(actual, next)
  |> should.equal(buffer.diff_to_ansi(expected, next))
}
