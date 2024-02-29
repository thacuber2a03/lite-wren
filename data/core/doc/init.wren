import "api" for Program, File
import "core/common" for Common
import "core/config" for Config

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

  <(other) {
    Common.assert(other is Position, "Can't compare with non-position")
    return other.line < line || other.line == line && other.col < col
  }

  >(other) {
    Common.assert(other is Position, "Can't compare with non-position")
    return other.line > line || other.line == line && other.col >= col
  }

  ==(other) {
    Common.assert(other is Position, "Can't compare with non-position")
    return other.line == line && other.col == col
  }

  line { _line }
  col { _col }
  offset { _offset }

  line=(v) { _line }
  col=(v) { _col }
  offset=(v) { _offset }
}

// [0, 1, 2, 3]

class Doc {
  splice(at, remove) { splice(at, remove, []) }
  splice(at, remove, insert) {
    while (remove > 0) _lines.removeAt(at)
    _lines = _lines[0...at] + insert + _lines[at...-1]
  }

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

  set_selection(pos) {
    if (pos is List) return set_selection(pos[0], pos[1], false)
    return set_selection(pos, pos, false)
  }

  set_selection(pos, swap) {
    if (pos is List) return set_selection(pos[0], pos[1], false)
    if (swap is Bool) return set_selection(pos, pos, swap)
    return set_selection(pos1, pos2, false)
  }

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
    if (pos2 > pos1) return [pos2, pos1, true]
    return [pos1, pos2, false]
  }

  get_selection() { get_selection(false) }

  get_selection(sort) {
    var a = _selection[0]
    var b = _selection[1]
    if (sort) return sort_positions(a, b)
    return [a, b]
  }

  has_selection {
    var a = _selection[0]
    var b = _selection[1]
    return !(a.line == b.line && a.col == b.col)
  }

  sanitize_selection() { set_selection(get_selection()) }

  sanitize_position(pos) {
    pos.line = pos.line.clamp(0, _lines.count-1)
    return Position.new(
      pos.line, pos.col.clamp(0, _lines[pos.line].count-1)
    )
  }

  position_offset(pos, rest) {
    var other = rest[0]
    if (other is Fn) {
      // func offset
      pos = sanitize_position(pos)
      return other.call(this, pos, rest)
    }

    if (other is Position) {
      return sanitize_position(Position.new(
        pos.line + other.line,
        pos.col + other.col
      ))
    }

    // byte offset
    pos = sanitize_position(pos)
    pos.col = pos.col + other
    while (pos.line > 1 && pos.col < 1) {
      pos.line = pos.line - 1
      pos.col = pos.col + _lines[pos.line].count
    }
    while (pos.line < _lines.count && pos.col > _lines[pos.line].count) {
      pos.col = pos.col - _lines[pos.line].count
      pos.line = pos.line + 1
    }
    return sanitize_position(pos)
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

  push_undo_(undo_stack, time, type, rest) {
    undo_stack.add({
      "type": type,
      "time": time,
      "rest": rest
    })
    if (undo_stack.count > Config.max_undos) undo_stack.removeAt(0)
  }

  pop_undo_(undo_stack, redo_stack) {
    var cmd = undo_stack[-1]
    if (!cmd) return
    undo_stack.removeAt(-1)

    var type = cmd["type"]
    var rest = cmd["rest"]
    var time = cmd["time"]
    if (type == "insert") {
      raw_insert_(rest[0], rest[1], redo_stack, time)
    } else if (type == "remove") {
      raw_remove_(rest[0], rest[1], redo_stack, time)
    } else if (type == "selection") {
      _selection[0] = rest[0]
      _selection[1] = rest[1]
    }

    // if next undo command is within the merge timeout then treat as a single
    // command and continue to execute it
    var next = undo_stack[-1]
    if (next && (time - next["time"]).abs < Config.undo_merge_timeout) {
      return pop_undo_(undo_stack, redo_stack)
    }
  }

  raw_insert_(pos, text, undo_stack, time) {
    var lines = text.split("\n")
    var before = _lines[pos.line-1][0...pos.col-1]
    var after = _lines[pos.line-1][pos.col-1..-1]
    lines.map { |v| v + "\n" }
    lines[0] = before + lines[0]
    lines[-1] = lines[-1] + after

    splice(pos.line, 0, lines)

    var pos2 = position_offset(pos, [text.count])
    push_undo_(undo_stack, time, "selection", get_selection())
    push_undo_(undo_stack, time, "remove", [pos, pos2])

    sanitize_selection()
  }

  insert(pos, text) {
    _redo_stack = []
    pos = sanitize_position(pos)
    raw_insert_(pos, text, _undo_stack, Program.get_time())
  }

  text_input(text) {
    if (this.has_selection) delete_to()
    var sel = get_selection()
    insert(sel[0], text)
    move_to([text.count])
  }

  move_to(args) {
    var sel = get_selection()
    set_selection(position_offset(sel[0], args))
  }
}
