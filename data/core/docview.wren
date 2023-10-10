import "api" for Program
import "core" for Core
import "core/common" for Common
import "core/shapes" for Vector
import "core/view" for View
import "core/doc" for Doc
import "core/style" for Style
import "core/config" for Config
import "core/keymap" for Keymap

class Position {
  construct new() {
    _line = 0
    _col = 0
    _offset = 0
  }

  construct new(line, col) {
    _line = line
    _col = col
    _offset = 0
  }

  line { _line }
  col { _col }
  offset { _offset }

  line=(v) { _line }
  col=(v) { _col }
  offset=(v) { _offset }
}

class DocView is View {
  construct new(doc) {
    super()
    _cursor = "ibeam"
    _scrollable = true
    _doc = Common.assert(doc)
    _font = "code_font"
    _last_x_offset = Position.new()
    _blink_timer = 0
  }

  move_to_line_offset(line, col, offset) {
    var xo = _last_x_offset
    if (xo.line != line || xo.col != col) {
      xo.offset = get_col_x_offset(line, col)
    }

    xo.line = line + offset
    xo.col = get_x_offset_col(line + offset, xo.offset)
    return [xo.line, xo.col]
  }

  try_close(do_close) {
    if (_doc.is_dirty() && Core.get_views_referencing_doc(_doc) == 1) {
      Core.command_view.enter("Unsaved Changes; Confirm Close", Fn.new { |unused, item|
        var start = item.text[0]
        if (start == "s" || start == "S") _doc.save()
        do_close.call()
      }, Fn.new { |text|
        var items = []
        var start = text[0]
        if (!(start == "c" || start == "C")) items.add("Close Without Saving")
        if (!(start == "s" || start == "S")) items.add("Save And Close")
        return items
      })
    } else {
      do_close.call()
    }
  }

  get_name() {
    var post = _doc.is_dirty ? "*" : ""
    var name = _doc.name
    for (i in (name.count-1)..0) {
      if (name[i] == Program.PATHSEP) return name[(i+1)..-1] + post
    }
    return name + post
  }

  get_scrollable_size() { get_line_height() * (_doc.lines.count - 1) + self.size.y }

  get_font() {
    if (_font == "font") return Style.font
    if (_font == "big_font") return Style.big_font
    if (_font == "code_font") return Style.code_font
    if (_font == "icon_font") return Style.icon_font
  }

  get_line_height() { (get_font().get_height() * Config.line_height).floor }

  get_gutter_width() { get_font().get_width(_doc.lines.count) + Style.padding.x * 2 }

  get_line_screen_position(idx) {
    var p = get_content_offset()
    var lh = get_line_height()
    var gw = get_gutter_width()
    return Vector.new(p.x + gw, p.y + (idx-1) * lh + Style.padding.y)
  }

  get_line_text_y_offset() {
    var lh = get_line_height()
    var th = get_font().get_height()
    return (lh - th) / 2
  }

  get_visible_line_range() {
    var bounds = get_content_bounds()
    var lh = get_line_height()
    var minline = 1.max((y / lh).floor)
    var maxline = _doc.lines.count.min((y2 / lh) + 1)
    return [minline, maxline]
  }

  get_col_x_offset(line, col) {
    if (line > _doc.lines.count) return 0
    return get_font().get_width(_doc.lines[line][0...col])
  }

  get_x_offset_col(line, x) {
    var text = _doc.lines[line]

    var xoffset = 0
    var last_i = 1
    var i = 1
    for (char in text.codePoints) {
      var w = get_font().get_width(char)
      if (xoffset >= x) return (xoffset - x > w / 2) ? last_i : i
      xoffset = xoffset + w
      last_i = i
      i = i + char.count
    }

    return text.count
  }

  resolve_screen_position(x, y) {
    var o = get_line_screen_position(1)
    var line = ((y - o.y) / get_line_height()).floor + 1
    line = line.clamp(0, _doc.lines.count)
    var col = get_x_offset_col(line, x - o.x)
    return Position.new(line, col)
  }

  scroll_to_line(line, ignore_if_visible, instant) {
    var range = get_visible_line_range()
    if (!(ignore_if_visible && line > range[0] && line < range[1])) {
      var lh = get_line_height()
      this.scroll[1].y = 0.max(lh * (line - 1) - this.size.y / 2)
      if (instant) this.scroll[0].y = this.scroll[1].y
    }
  }

  scroll_to_make_visible(line, col) {
    var min = get_line_height() * (line - 1)
    var max = get_line_height() * (line + 2) - this.size.y
    this.scroll[1].y = this.scroll[1].y.min(min)
    this.scroll[1].y = this.scroll[1].y.max(max)
    var gw = get_gutter_width()
    var xoffset = get_col_x_offset(line, col)
    max = xoffset - this.size.x + gw + this.size.x / 5
    this.scroll[1].x = 0.max(max)
  }

  on_mouse_pressed(button, mousePos, clicks) {
    var caught = super.on_mouse_pressed(button, mousePos, clicks)
    if (caught) return
    if (Keymap.modkeys["shift"]) {
      if (clicks == 1) {
        // TODO(thacuber2a03): finish this
      }
    }
  }
}
