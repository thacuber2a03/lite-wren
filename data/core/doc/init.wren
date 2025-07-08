import "core/common" for Common

class Position {
	construct new(doc, line, col) {
		_doc = doc
		_line = line
		_col = col
	}

	copy { Position.new(_doc, _line, _col) }

	+(other) {
		Common.assert(other is Position, "Position + other: expected Position, got %(other.type)")
		Common.assert(_doc == other.doc, "Position + other: both Positions must point to the same Doc")
		return Position.new(_doc, _line+other.line, _col+other.col)
	}

	doc { _doc }
	doc=(v) { _doc=v }
	line { _line }
	line=(v) { _line=v }
	col { _col }
	col=(v) { _col=v }
}

class Selection {
	construct new(doc, l1, c1, l2, c2) {
		_a = Position.new(doc, l1, c1)
		_b = Position.new(doc, l2, c2)
	}

	construct new(doc, line, col) {
		if (line is Position) {
			Common.assert(col is Position)
			_a = line
			_b = col
		} else {
			_a = Position.new(doc, line, col)
			_b = _a.copy
		}
	}

	copy { Selection.new(_doc, _a.copy, _b.copy) }

	a { _a }
	a=(v) { _a=v }
	b { _b }
	b=(v) { _b=v }
}

class Doc {
	construct new() { reset() }

	construct new(filename) {
		reset()
		load(filename)
	}

	reset() {
		_lines = ["\n"]
		_selection = Selection.new()
		// NOTE(thacuber2a03): currently not doing the index memory-saving technique
		// -# holy shit, the one note that actually *is* a note
		_undoStack = []
		_redoStack = []
		_cleanChangeID = 1
		// _highlighter = Highlighter.new(this)
		resetSyntax()
	}

	load(filename) {
		// NOTE(thacuber2a03): I'm not making a full file-handling API
		reset()
		_filename = filename
		_lines = []

		Common.lines(Filesystem.read(filename)) {|line|
			if (line[-1] == "\r") _crlf = true
			_lines.add(line + "\n")
		}

		if (_lines.count ==) _lines.add("\n")
		resetSyntax()
	}

	name { _filename || "unsaved" }
	dirty { _cleanChangeID != changeID }
	clean { _cleanChangeID = changeID }
	changeID { _undoStack.count }

	setSelection(sel) { setSelection(sel, swap) }
	setSelection(sel, swap) {
		sel = sel.copy
		if (sel is Position) {
			sel.sanitize()
			_selection.a = sel
			_selection.b = sel.copy
		} else {
			if (swap) {
				var temp = sel.a
				sel.a = sel.b
				sel.b = temp
			}
			sel.a.sanitize()
			sel.b.sanitize()
			_selection = sel
		}
	}

	sortPositions_(p1, p2) {
		// NOTE(thacuber2a03): I love programming
		return p1.line > p2.line ||
		       p1.line == p2.line && p1.col > p2.col ?
			       [p2.copy, p1.copy, true] :
			       [p1.copy, p2.copy, false]
	}

	selection { selection(false) }
	selection(sort) {
		if (sort) {
			var i = sortPositions(_selection.a, _selection.b)
			return Selection.new(i[0], i[1])
		}
		return _selection
	}

	hasSelection {
		var a = _selection.a
		var b = _selection.b
		return !(a.line == b.line && a.col == b.col)
	}

	sanitizeSelection() { setSelection(selection) }

	positionOffset(pos, other) {
		if (other is Fn) return other.call(pos)

		if (other is Num) {
			Fiber.abort("TODO: byte offset")
		}

		if (other is Position) return sanitizePosition(pos + other)
	}
}
