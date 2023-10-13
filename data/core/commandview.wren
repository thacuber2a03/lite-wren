import "api" for Renderer
import "core" for Core
import "core/shapes" for Vector, Rect
import "core/common" for Common
import "core/style" for Style
import "core/doc" for Doc, Position
import "core/docview" for DocView
import "core/view" for View

class SingleLineDoc is Doc {
  construct new() { super() }

  insert(line, col, text) {
    super.insert(line, col, text.replace("\n", ""))
  }
}

var Noop = Fn.new {}

class CommandView is DocView {
  construct new() {
    super(SingleLineDoc.new())
    _suggestion_idx = 1
    _suggestions = []
    _suggestions_height = 0
    _last_change_id = 0
    _gutter_width = 0
    _gutter_text_brightness = 0
    _selection_offset = 0
    _state = CommandView.default_state
    this.font = "font"
    this.size.y = 0
    _label = ""
  }

  static max_suggestions { 10 }

  static default_state {
    if (!__default_state) __default_state = {
      "submit": Noop,
      "suggest": Noop,
      "cancel": Noop,
    }
    return __default_state
  }

  name { super.name }

  line_screen_position {
    var p = super.line_screen_position(1)
    var x = p.x
    p = get_content_offset()
    var y = p.y
    var lh = this.line_height
    return Vector.new(x, y + (this.size.y - lh) / 2)
  }

  scrollable_size { 0 }

  scroll_to_make_visible() { /* no-op */ }

  text {
    return this.doc.get_text(
      Position.new(), Position.new(0, Num.infinity)
    )
  }

  set_text(text) { set_text(text, false) }

  set_text(text, select) {
    this.doc.remove(1, 1, Num.infinity, Num.infinity)
    this.doc.text_input(text)
    if (select) this.doc.set_selection(Num.infinity, Num.infinity, 1, 1)
  }

  move_suggestion_idx(dir) {
    var n = _suggestion_idx + dir
    _suggestion_idx = n.clamp(1, _suggestions.count)
    complete()
    this.last_change_id = this.doc.get_change_id()
  }

  complete() {
    if (_suggestions.count > 0) {
      set_text(_suggestions[_suggestion_idx].text)
    }
  }

  submit() {
    var suggestion = _suggestions[_suggestion_idx]
    var text = get_text()
    var submit = _state["submit"]
    exit(true)
    submit.call(text, suggestion)
  }

  enter(text, submit) { enter(text, submit, null) }

  enter(text, submit, suggest) { enter(text, submit, suggest, null) }

  enter(text, submit, suggest, cancel) {
    if (_state != CommandView.default_state) return
    _state = {
      "submit": submit || Noop,
      "suggest": suggest || Noop,
      "cancel": cancel || Noop,
    }
    Core.set_active_view(this)
    update_suggestions()
    _gutter_text_brightness = 100
    _label = text + ": "
  }

  exit(submitted, inexplicit) {
    if (Core.active_view == this) {
      Core.set_active_view(Core.last_active_view)
    }
    var cancel = _state["cancel"]
    _state = CommandView.default_state
    this.doc.reset()
    _suggestions = []
    if (!submitted) cancel.call(!inexplicit) // TODO(thacuber2a03): what??
  }

  gutter_width { _gutter_width }

  suggestion_line_height { this.font.height + Style.padding.y }

  update_suggestions() {
    var t = _state["suggest"].call(this.text) || []
    var res = []
    for (i in 0...t.count) {
      if (i == CommandView.max_suggestions-1) break
      var item = t[i]
      if (item is String) item = { "text": item }
      res.insert(i, item)
    }
    _suggestions = res
    _suggestion_idx = 0
  }

  update() {
    super.update()

    if (Core.active_view != this && _state != CommandView.default_state) {
      exit(false, true)
    }

    if (_last_change_id != this.doc.change_id) {
      update_suggestions()
      _last_change_id = this.doc.change_id
    }

    _gutter_text_brightness = move_towards(
      _gutter_text_brightness,
      0, 0.1
    )

    var dest = this.font.width(_label) + Style.padding.x
    if (this.size.y <= 0) {
      _gutter_width = dest
    } else {
      _gutter_width = move_towards(_gutter_width, dest)
    }

    var lh = this.suggestion_line_height
    dest = _suggestions.count * lh
    _suggestions_height = move_towards(_suggestions_height, dest)

    dest = _suggestion_idx * this.suggestion_line_height
    _selection_offset = move_towards(_selection_offset, dest)

    dest = 0
    if (this == Core.active_view) {
      dest = Style.font.height + Style.padding.y * 2
    }
    this.size.y = move_towards(this.size.y, dest)
  }

  draw_line_highlight() { /* no-op */ }

  draw_line_gutter(idx, p) {
    var yoffset = get_line_text_y_offset()
    var pos = this.position
    var color = Common.lerp(Style.text, Style.accent, _gutter_text_brightness / 100)
    Core.push_clip_rect(Rect.new(pos.x, pos.y, this.gutter_width, this.size.y))
    p.x = p.x + Style.padding.x
    Renderer.draw_text(this.font, _label, x, y + yoffset, color)
  }

  draw_suggestions_box() {
    var lh = this.suggestion_line_height
    var dh = Style.divider_size
    var x = this.line_screen_position.x
    var h = _suggestions_height.ceil
    var r = Rect.new(
      this.position.x,
      this.position.y - h - dh,
      this.size.x, h
    )

    if (_suggestions.count > 0) {
      Renderer.draw_rect(r.x, r.y, r.w, r.h, Style.background3)
      Renderer.draw_rect(r.x, r.y - dh, r.w, dh, Style.divider)
      var y = this.position.y - _selection_offset - dh
      Renderer.draw_rect(r.x, y, r.w, lh, Style.line_highlight)
    }

    Core.push_clip_rect(r)
    for (i in 0..._suggestions.count) {
      var item = _suggestions[i]
      var color = (i == _suggestion_idx) ? Style.accent : Style.text
      var y = this.position.y - (i+1) * lh - dh
      Common.draw_text(this.font, color, item["text"], null, Rect.new(x, y, 0, lh))

      if (item["info"]) {
        var w = this.size.x - x - Style.padding.x
        Common.draw_text(this.font, Style.dim, item["info"], "right", Rect.new(x, y, w, lh))
      }
    }
    Core.pop_clip_rect()
  }

  draw() {
    super.draw()
    Core.root_view.defer_draw(null) { |a| draw_suggestions_box() }
  }
}
