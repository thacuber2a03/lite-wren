import "api" for Program, Renderer
import "core" for Core
import "core/common" for Common
import "core/shapes" for Vector, Rect
import "core/view" for View
import "core/doc" for Doc, Position
import "core/style" for Style
import "core/config" for Config
import "core/keymap" for Keymap

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

  font=(v) { _font = v }
  doc { _doc }

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

  scrollable_size { line_height * (_doc.lines.count - 1) + this.size.y }

  font {
    if (_font == "font") return Style.font
    if (_font == "big_font") return Style.big_font
    if (_font == "code_font") return Style.code_font
    if (_font == "icon_font") return Style.icon_font
  }

  line_height { (this.font.height * Config.line_height).floor }

  gutter_width { this.font.width(_doc.lines.count) + Style.padding.x * 2 }

  line_screen_position(idx) {
    var p = get_content_offset()
    var lh = this.line_height
    var gw = this.gutter_width
    return Vector.new(p.x + gw, p.y + (idx-1) * lh + Style.padding.y)
  }

  get_line_text_y_offset() {
    var lh = this.line_height
    var th = get_font().get_height()
    return (lh - th) / 2
  }

  visible_line_range {
    var bounds = get_content_bounds()
    var lh = this.line_height
    var minline = 1.max((bounds.y / lh).floor)
    var maxline = _doc.lines.count.min((bounds.h / lh) + 1)
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
      var w = this.font.width(char)
      if (xoffset >= x) return (xoffset - x > w / 2) ? last_i : i
      xoffset = xoffset + w
      last_i = i
      i = i + char.count
    }

    return text.count
  }

  resolve_screen_position(x, y) {
    var o = line_screen_position(1)
    var line = ((y - o.y) / this.line_height).floor + 1
    line = line.clamp(0, _doc.lines.count)
    var col = get_x_offset_col(line, x - o.x)
    return Position.new(line, col)
  }

  scroll_to_line(line, ignore_if_visible, instant) {
    var range = get_visible_line_range()
    if (!(ignore_if_visible && line > range[0] && line < range[1])) {
      var lh = this.line_height
      this.scroll[1].y = 0.max(lh * (line - 1) - this.size.y / 2)
      if (instant) this.scroll[0].y = this.scroll[1].y
    }
  }

  scroll_to_make_visible(line, col) {
    var min = this.line_height * (line - 1)
    var max = this.line_height * (line + 2) - this.size.y
    this.scroll[1].y = this.scroll[1].y.min(min)
    this.scroll[1].y = this.scroll[1].y.max(max)
    var gw = this.gutter_width
    var xoffset = get_col_x_offset(line, col)
    max = xoffset - this.size.x + gw + this.size.x / 5
    this.scroll[1].x = 0.max(max)
  }

  on_mouse_pressed(button, mousePos, clicks) {
    var caught = super.on_mouse_pressed(button, mousePos, clicks)
    if (caught) return
    if (Keymap.modkeys["shift"]) {
      if (clicks == 1) {
        var head = _doc.get_selection()
        var tail = resolve_screen_position(mousePos)
        _doc.set_selection(tail, head)
      }
    } else {
      var pos = resolve_screen_position(mousePos)
      _doc.set_selection(mouse_selection(clicks, pos, pos))
      _mouse_selecting = { "pos": pos, "clicks": clicks }
    }
    _blink_timer = 0
  }

  on_text_input(text) { _doc.text_input(text) }

  draw_line_text(idx, p) {
    var t = Vector.new(p.x, p.y + this.line_text_y_offset)
    var font = this.font
    t.x = Renderer.draw_text(font, _doc.lines[idx], t.x, t.y, Style.text)
  }

  draw_line_body(idx, p) {
    var caret = get_selection()
    caret = caret[0]

    var line = get_selection()
    if (idx >= line[0].line && idx <= line[1].line) {
      var text = _doc.lines[idx]
      if (line[0].line != idx) line[0].col = 1
      if (line[1].line != idx) line[1].col = text.count + 1
      var x1 = p.x + get_col_x_offset(idx, line[0].col)
      var x2 = p.x + get_col_y_offset(idx, line[1].col)
      var lh = this.line_height
      Renderer.draw_rect(x1, p.y, x2 - x1, lh, Style.selection)
    }

    if (Config.highlight_current_line && !_doc.has_selection && caret.line == idx && Core.active_view == this) {
      draw_line_highlight(p.x + this.scroll.x, y)
    }

    draw_line_text(idx, x, y)

    if (caret.line == idx && Core.active_view == this && _blink_timer < _blink_period / 2 && Program.window_has_focus()) {
      var lh = this.line_height
      var x1 = x + get_col_x_offset(caret.line, caret.col)
      Renderer.draw_rect(x1, y, Style.caret_width, lh, Style.caret)
    }
  }

  draw_line_gutter(idx, p) {
    var color = Style.line_number
    var sel = this.doc.get_selection(true)
    if (idx >= sel[0].line && idx <= sel[1].line) {
      color = Style.line_number2
    }
    var yoffset = this.line_text_y_offset
    p.x = p.x + Style.padding.x
    Renderer.draw_text(this.font, idx, p.x, p.y + yoffset, color)
  }

  draw() {
    draw_background(Style.background)

    var font = this.font
    font.set_tab_width(font.width(" ") * Config.indent_size)

    var range = this.visible_line_range
    var lh = this.line_height

    var pos = line_screen_position(range[0])
    var x = this.position.x
    for (i in range[0]...range[1]) {
      draw_line_gutter(i, x, y)
      y = y + lh
    }

    var line_pos = line_screen_position(range[0])
    var gw = this.gutter_width
    pos = this.position
    Core.push_clip_rect(Rect.new(pos.x + gw, pos.y, this.size.x, this.size.y))
    for (i in range[0]...range[1]) {
      draw_line_body(i, x, y)
      y = y + lh
    }
    Core.pop_clip_rect()

    draw_scrollbar()
  }
}
