import "system" for Clock
import "renderer" for Font

import "core" for Core
import "core/common" for Common, Vector, Rect
import "core/config" for Config
import "core/view" for View
import "core/style" for Style

class StatusView is View {
	static separator  { "      " }
	static separator2 { "   |   " }

	construct new() {
		super()
		_messageTimeout = 0
		_message = {}
	}

	onMousePressed(button, mousePos, mouseDelta, clicks) {
		Core.setActiveView(Core.lastActiveView)
		// if (Clock.now < _messageTimeout && !(Core.activeView is LogView)) {
		// 	Command.perform("core:open-log")
		// }
	}

	showMessage(icon, iconColor, text) {
		_message = [
			iconColor, Style.iconFont, icon,
			Style.dim, Style.font, StatusView.separator2, Style.text, text
		]
		_messageTimeout = Clock.now + Config.messageTimeout
	}

	update() {
		size.y = Style.font.height + Style.padding.y * 2
		scrollTo.y = Clock.now < _messageTimeout ? size.y : 0
		super()
	}

	drawItems_(items, off, drawFn) {
		var font = Style.font
		var color = Style.text

		for (item in items) {
			if (item is Font) {
				font = item
			} else if (item is List) {
				color = item
			} else {
				var o = drawFn.call(font, color, item, null, Rect.new(off, Vector.new(0, size.y)))
				off.x = o.x
			}
		}

		return off.x
	}

	drawItems(items) { drawItems(items, false) }
	drawItems(items, rightAlign) { drawItems(items, rightAlign, 0) }
	drawItems(items, rightAlign, yoffset) {
		var off = contentOffset
		off.y = off.y + yoffset
		// NOTE(thacuber2a03): *goddddd* how I'd wish for delegates or something, this blows
		var f = Fn.new {|font, color, text, align, rect|
			return Common.drawText(font, color, text, align, rect)
		}

		if (rightAlign) {
			// NOTE(thacuber2a03): this is even worse
			var w = drawItems_(items, Vector.zero) {|font, color, text, align, rect| rect.x + font.width(text) }
			off.x = off.x + size.x - w - Style.padding.x
			drawItems_(items, off, f)
		} else {
			off.x = off.x + Style.padding.x
			drawItems_(items, off, f)
		}
	}

	items {
		return [
			[
				Style.iconFont, "g",
				Style.font, Style.dim, StatusView.separator2,
				"0", // Core.docs.count,
				Style.text, " / ",
				"0", // Core.projectFiles.count,
				" files",
			],
			[]
		]
	}

	draw() {
		drawBackground(Style.background2)

		if (_message) drawItems(_message, false, size.y)

		var i = items
		drawItems(i[0])
		drawItems(i[1], true)
	}
}
