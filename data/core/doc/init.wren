import "api" for File
import "core/common" for Common

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

class Doc {
  construct new(filename) { load(filename) }
  construct new() { reset() }

  reset() {
    _lines = [ "\n" ]
    _selection = [
      Position.new(),
      Position.new()
    ]
    _undo_stack = []
    _redo_stack = []
    _clean_change_id = 1
  }

  lines { _lines }
  filename { _filename }
  crlf { _crlf }

  load(filename) {
    var fp = File.load(filename, "rb")
    reset()
    _filename = filename
    _lines = []
    var line = fp.read_line()
    while (line) {
      if (line.bytes[-1] == 13) {
        line = line.trimEnd()
        _crlf = true
      }
      _lines.add(line + "\n")
    }
    if (_lines.count == 0) _lines.add("\n")
    fp.close()
    // reset_syntax()
  }

  save(filename) {
    filename = filename || Common.assert(_filename, "no filename set")
    var fp = File.load(filename, "w+b")
    for (line in _lines) {
      if (_crlf) line = line.replace("\n", "\r\n")
      fp.write(line)
    }
    fp.close()
    _filename = filename || _filename
    // reset_syntax()
    clean()
  }

  name { _filename || "unsaved" }

  is_dirty { _clean_change_id != this.change_id }

  clean() { _clean_change_id = this.change_id }

  change_id { _undo_stack.count }

  set_selection(pos, swap) { set_selection(pos, pos, swap) }

  set_selection(pos1, pos2, swap) {
    if (swap) {
      var temp = pos1
      pos1 = pos2
      pos2 = temp
    }
    _selection[0] = sanitize_position(pos1)
    _selection[1] = sanitize_position(pos2)
  }

  sort_positions(pos1, pos2) {
    if (pos1.line > pos2.line || pos1.line == pos2.line && pos1.col > pos2.col) {
      return [pos2, pos1, true]
    }
    return [pos1, pos2, false]
  }

  get_selection() { get_selection(false) }

  get_selection(sort) {
    var a = _selection[0]
    var b = _selection[1]
    if (sort) return sort_positions(a, b)
    return [a, b]
  }

  sanitize_position(pos) {
    pos.line = pos.line.clamp(0, _lines.count-1)
    return Position.new(
      pos.line, pos.col.clamp(0, _lines[pos.line].count-1)
    )
  }

  get_text(pos1, pos2) {
    pos1 = sanitize_position(pos1)
    pos2 = sanitize_position(pos2)
    var pos = sort_positions(pos1, pos2)
    pos1 = pos[1]
    pos2 = pos[0]
    if (pos1.line == pos2.line) {
      return _lines[pos1.line][pos1.col...pos2.col]
    }
    var lines = [ _lines[pos1.line][pos2.col...-1] ]
    for (i in pos1.line+1...pos2.line-1) lines.add(_lines[i])
    lines.add(_lines[pos2.line][0...pos2.col])
    return lines.join()
  }

  get_char(pos) {
    pos = sanitize_position(pos)
    return _lines[pos.line][pos.col]
  }

  raw_insert(pos, text, undo_stack, time) {
    var lines = text.split("\n")
    var before = _lines[pos.line][0...pos.col-1]
    var after = _line[pos.line][pos.col...]
    for (i in 0..._lines-1) lines[i] = lines[i] + "\n"
    lines[0] = before + lines[0]
    lines[-1] = lines[-1] + after

    splice(_lines, line, 1, lines)

    var pos2 = position_offset(pos, text.count)
    push_undo(undo_stack, time, "selection", get_selection())
    push_undo(undo_stack, time, "remove", [pos, pos2])

    sanitize_selection()
  }

  insert(pos, text) {
    _redo_stack = []
    pos = sanitize_position(pos)
    raw_insert(pos, text, _undo_stack, Program.get_time())
  }

  text_input(text) {
    if (this.has_selection) delete_to()
    var pos = get_selection()
    insert(pos, text)
    move_to(text.count)
  }
}
