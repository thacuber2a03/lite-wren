import "core" for Core
import "core/common" for Common
import "core/style" for Style
import "core/doc" for Doc
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
    super(SingleLineDoc())
    _suggestion_idx = 1
    _suggestions = []
    _suggestions_height = 0
    _last_change_id = 0
    _gutter_width = 0
    _gutter_text_brightness = 0
    _selection_offset = 0
    _state = CommandView.default_state
    _font = "font"
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
}
