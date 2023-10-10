import "api" for Program
import "core/common" for Common
import "core/shapes" for Vector
import "core/view" for View
import "core/doc" for Doc

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
    import "core" for Core
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
}

var test = DocView.new(Doc.new())
System.print(test.get_name())
