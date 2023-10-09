import "api" for Renderer
import "core/shapes" for Vector, Rect
import "core/config" for Config
import "core/style" for Style
import "core/common" for Common

class View {
  construct new() {
    _position = Vector.new()
    _size = Vector.new()
    _scroll = [
      Vector.new(),
      Vector.new()
    ]
    _cursor = "arrow"
    _scrollable = false
  }

  position { _position }
  size { _size }
  scroll { _scroll }
  cursor { _cursor }
  scrollable { _scrollable }

  move_towards(v, dest, rate) {
    var val = v

    if ((val-dest).abs < 0.5) {
      val = dest
    } else {
      val = Common.lerp(val, dest, rate)
    }

    if (val != dest) core.redraw = true
    return val
  }

  try_close(do_close) { do_close.call() }

  get_name() { "---" }

  get_scrollable_size() { Num.infinity }

  get_scrollbar_rect() {
    var sz = get_scrollable_size()
    if (sz <= _size.y || sz == Num.infinity) return Rect.new(0,0,0,0)

    var h = 20.max(_size.y * _size.y / sz)
    return Rect.new(
      _position.x + _size.x - Style.scrollbar_size,
      _position.y + _scroll[0].y * (_size.y - h) / (sz - _size.y),
      Style.scrollbar_size,
      h
    )
  }

  scrollbar_overlaps_point(p) {
    var s = get_scrollbar_rect()
    return p.x >= s.x - s.width * 3 && p.x < s.x + s.width && p.y >= s.y && p.y < sy + s.height
  }

  on_mouse_pressed(button, mousePos, clicks) {
    if (scrollbar_overlaps_point(mousePos)) {
      _dragging_scrollbar = true
      return true
    }
  }

  on_mouse_released(button, mousePos) {
    _dragging_scrollbar = false
  }

  on_mouse_moved(absolute, relative) {
    if (_dragging_scrollbar) {
      var delta = get_scrollable_size() / _size.y * relative.y
      _scroll[1].y = _scroll[1].y + delta
    }
    _hovered_scrollbar = scrollbar_overlaps_point(absolute)
  }

  on_text_input(text) { /* no-op */ }

  on_mouse_wheel(y) {
    if (_scrollable) {
      _scroll[1].y = _scroll[1].y + y * -Config.mouse_wheel_scroll
    }
  }

  get_content_bounds() {
    var x = _scroll[0].x
    var y = _scroll[1].y
    return Rect.new(x, y, x + _size.x, y + _size.y)
  }

  get_content_offset() {
    var x = (_position.x - _scroll[0].x).round
    var y = (_position.y - _scroll[0].y).round
    return Vector.new(x, y)
  }

  clamp_scroll_position() {
    var max = get_scrollable_size() - _size.y
    _scroll[1].y = _scroll[1].y.clamp(0, max)
  }

  update() {
    clamp_scroll_position()
    _scroll[0].x = move_towards(_scroll[0].x, _scroll[1].x, 0.3)
    _scroll[0].y = move_towards(_scroll[0].y, _scroll[1].y, 0.3)
  }

  draw_background(color) {
    var x = _position.x
    var y = _position.y
    var w = _size.x
    var h = _size.y
    Renderer.draw_rect(x, y, w + x % 1, h + y % 1, color)
  }

  draw_scrollbar() {
    var rect = get_scrollbar_rect()
    var highlight = _hovered_scrollbar || _dragged_scrollbar
    var color = highlight ? Style.scrollbar2 : Style.scrollbar
  }

  draw() { /* noop */ }
}
