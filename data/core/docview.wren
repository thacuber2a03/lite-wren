import "core" for Core
import "core/common" for Common, Vector, Rect
import "core/config" for Config
import "core/style" for Style
import "core/keymap" for Keymap
// import "core/doc/translate" for Translate
import "core/view" for View

class DocView is View {
	construct new(doc) {
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
			if (name[i] == "/" || name[i] == "\\") name = name[i..-1]
		}
		return name + post
	}

	scrollableSize { lineHeight * (_doc.lines.count - 1) + size.y }

	font { _font }
}
