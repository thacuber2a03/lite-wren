import "system" for Filesystem

import "core/common" for Common

class Position {
	construct new(doc, line, col) {
		_doc = doc
		_line = line
		_col = col
	}

	copy { Position.new(_doc, _line, _col) }

	sanitized { Position.new(_doc,
		_line.clamp(0, _doc.lines.count-1),
		_col.clamp(0, _doc.lines[_line].count-1)
	) }

	offsetBy(other) {
		if (other is Fn) return other.call(this)

		if (other is Position) {
			Common.assert(_doc == other.doc, "both Positions must refer to the same doc")
			return Position.new(_doc, _line+other.line, _col+other.col).sanitized
		}

		if (other is Num) {
			var pos = sanitized
			var line = pos.line
			var col = pos.col
			while (line > 0 && col < 0) {
				line = line - 1
				col = col + _doc.lines[line].count
			}
			while (line < _doc.lines.count-1 && col >= _doc.lines[line].count) {
				col = col - _doc.lines[line].count
				line = line + 1
			}
			return Position.new(_doc, line, col).sanitized
		}

		Fiber.abort("can't offset by a %(other.type)")
	}

	doc { _doc }
	line { _line }
	col { _col }
}

class Selection {
	construct fromCoords(doc, line, col) {
		_a = Position.new(doc, line, col)
		_b = _a.copy
	}

	construct new(a, b) {
		_a = a
		_b = b
	}

	copy { Selection.new(_a, _b) }

	empty { _a.line == _b.line && _a.col == _b.col }

	sanitized { Selection.new(_a.sanitized, _b.sanitized) }

	a { _a }
	b { _b }
}

class Doc {
	construct new() { reset() }

	construct new(filename) {
		reset()
		load(filename)
	}

	reset() {
		_lines = ["\n"]
		_selection = Selection.fromCoords(this, 0, 0)
		// NOTE(thacuber2a03): currently not doing the index memory-saving technique
		_undoStack = []
		_redoStack = []
		_cleanChangeID = 1
		// _highlighter = Highlighter.new(this)
		resetSyntax()
	}

	resetSyntax() {
		var start = Position.new(this, 0, 0)
		var sel = Selection.new(start, start.offsetBy(128))
		// var syn = Syntax.get(_filename || "", sel.text)
		// if (_syntax != syn) {
		// 	_syntax = syn
		// 	_highlighter.reset()
		// }
	}

	load(filename) {
		// NOTE(thacuber2a03): I'm not making a full file-handling API
		reset()
		_filename = filename
		_lines = []

		Common.lines(Filesystem.read(filename)) {|line|
			if (line.count != 0 && line[-1] == "\r") _crlf = true
			_lines.add(line + "\n")
		}

		if (_lines.count == 0) _lines.add("\n")

		resetSyntax()
	}

	save() {
		Common.assert(_filename, "no filename set to default to")
		save(_filename)
	}

	save(filename) {
		var contents = _lines.map {|x| _crlf ? x.replace("\n", "\r\n") : x }.join()
		Filesystem.write(filename, contents)

		_filename = filename
		resetSyntax()
		clean()
	}

	name { _filename || "unsaved" }
	dirty { _cleanChangeID != changeID }
	clean() { _cleanChangeID = changeID }
	changeID { _undoStack.count-1 }

	selection=(sel) { setSelection(sel, false) }
	setSelection(sel, swap) {
		sel = sel.copy
		if (sel is Position) {
			_selection.a = sel.sanitized
			_selection.b = _selection.b.copy
		} else {
			var a = sel.a
			var b = sel.b
			if (swap) {
				var temp = a
				a = b
				b = temp
			}
			_selection = Selection.new(a, b)
		}
	}

	sortPositions_(p1, p2) {
		return p1.line > p2.line ||
		       p1.line == p2.line && p1.col > p2.col ?
			       [p2.copy, p1.copy, true] :
			       [p1.copy, p2.copy, false]
	}

	selection { selection(false) }
	selection(sort) {
		if (sort) {
			var i = sortPositions_(_selection.a, _selection.b)
			return Selection.new(i[0], i[1])
		}
		return _selection
	}

	// TODO(thacuber2a03): I can't tell if this is great or if it's horrible
	sanitizeSelection() { selection = selection }

	lines { _lines }
}
