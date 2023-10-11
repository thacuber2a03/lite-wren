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
  construct new(filename) {
    reset()
    load(filename)
  }

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

  load(filename) {
    var fp = File.load(filename, "rb")
  }

  splice(t, at, remove) {
    splice(t, at, remove, [])
  }

  splice(t, at, remove, insert) {

  }

  is_dirty { false }
  name { "a/testdoc.lua" }
}
