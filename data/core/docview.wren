import "renderer" for Renderer
import "system" for Window

import "core" for Core
import "core/common" for Common, Vector, Rect
import "core/config" for Config
import "core/doc" for Position
import "core/style" for Style
import "core/keymap" for Keymap
// import "core/doc/translate" for Translate
import "core/view" for View

class DocView is View {
	construct new(doc) {
		__blinkPeriod = 0.8

		super()
		cursor = "ibeam"
		scrollable = true
		_doc = Common.assert(doc)
		_font = Style.codeFont
		_lastXOffset = {}
		_blinkTimer = 0
	}

	name {
		var post = _doc.dirty ? "*" : ""
		var name = _doc.name
		for (i in (name.count-1)..0) {
			if (name[i] == "/" || name[i] == "\\") {
				name = name[(i+1)..-1]
				break
			}
		}
		return name + post
	}

	scrollableSize { lineHeight * (_doc.lines.count - 1) + size.y }

	font { _font }

	lineHeight { (font.height * Config.lineHeight).floor }

	gutterWidth { font.width(_doc.lines) + Style.padding.x * 2 }

	lineScreenPosition(idx) {
		var pos = contentOffset
		return Vector.new(
			pos.x + gutterWidth,
			pos.y + idx * lineHeight + Style.padding.y
		)
	}

	lineTextYOffset { (lineHeight - font.height) / 2 }

	visibleLineRange {
		var r = contentBounds
		var lh = lineHeight
		var minline = 0.max((r.y/lh).floor)
		var maxline = _doc.lines.count.min((r.h/lh).floor)
		return minline..maxline
	}

	colXOffset(pos) {
		var text = _doc.lines[pos.line]
		if (!text) return 0
		return font.width(text[0...pos.col])
	}

	onMousePressed(button, pos, clicks) {
		var caught = super(button, pos, clicks)
		if (caught) return
	}

	onMouseMoved(pos, delta) {
		super(pos, delta)
	}

	drawLineHighlight(pos) {
		Renderer.drawRect(pos.x, pos.y, size.x, lineHeight, Style.lineHighlight)
	}

	drawLineBody(idx, pos) {
		var a = _doc.selection.a

		var sel = _doc.selection(true)
		if (idx >= sel.a.line && idx <= sel.b.line) {
			var text = _doc.lines[idx]
			if (sel.a.line != idx) { sel.a.col = 0 }
			if (sel.b.line != idx) { sel.b.col = text.count }
			var x1 = pos.x + colXOffset(Position.new(_doc, idx, sel.a.col))
			var x2 = pos.x + colXOffset(Position.new(_doc, idx, sel.b.col))
			Renderer.drawRect(x1, pos.y, x2 - x1, lineHeight, Style.selection)
		}

		if (Config.highlightCurrentLine && !_doc.selection.empty &&
		    a.line == idx && Core.activeView == this) {
			drawLineHighlight(Vector.new(pos.x + scroll.x, pos.y))
	    }

	    if (a.line == idx && Core.activeView == this &&
		    _blinkTimer < __blinkPeriod / 2 && Window.hasFocus) {
			var x1 = pos.x + colXOffset(a)
			Renderer.drawRect(x1, pos.y, Style.caretWidth, lineHeight, Style.caret)
	    }
	}

	drawLineGutter(idx, pos) {
		var color = Style.lineNumber
		var sel = _doc.selection(true)
		if (idx >= sel.a.line && idx <= sel.b.line) color = Style.lineNumber2
		var yOffset = lineTextYOffset
		Renderer.drawText(font, idx+1, pos.x + Style.padding.x, pos.y + yOffset, color)
	}

	draw() {
		drawBackground(Style.background)

		font.tabWidth = (font.width(" ") * Config.indentSize)

		var range = visibleLineRange
		var lh = lineHeight

		var lp = lineScreenPosition(range.min)
		var pos = Vector.new(position.x, lp.y)
		for (i in range) {
			drawLineGutter(i, pos)
			pos.y = pos.y + lh
		}

		lp = lineScreenPosition(range.min)
		Core.pushClipRect(Rect.new(
			position.x + gutterWidth, position.y, size.x, size.y
		))
		for (i in range) {
			drawLineBody(i, lp)
			lp.y = lp.y + lh
		}
		Core.popClipRect()

		drawScrollbar()
	}

	doc { _doc }
}
