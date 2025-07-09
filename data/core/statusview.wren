import "system" for Clock
import "renderer" for Font

import "core" for Core
import "core/command" for Command
import "core/common" for Common, Vector, Rect
import "core/config" for Config
import "core/logview" for LogView
import "core/style" for Style
import "core/view" for View

class StatusView is View {
	static separator { "      " }
	static separator2 { "   |   " }

	construct new() {
		super()
		_messageTimeout = 0
	}

	onMousePressed(button, pos, clicks) {
		Core.activeView = Core.lastActiveView
		if (Clock.now < _messageTimeout && !(Core.activeView is LogView)) {
			Command.perform("core:open-log")
		}
	}

	showMessage(icon, iconColor, text) {
		_message = [
			iconColor, Style.iconFont, icon,
			Style.dim, Style.font, StatusView.separator2,
			Style.text, text
		]
		_messageTimeout = Clock.now + Config.messageTimeout
	}

	update() {
		size.y = Style.font.height + Style.padding.y * 2
		scrollTo.y = Clock.now < _messageTimeout ? size.y : 0
		super()
	}

	drawItems_(items, pos, drawFn) {
		var font = Style.font
		var color = Style.text

		for (item in items) {
			if (item is Font) {
				font = item
			} else if (item is List) {
				color = item
			} else {
				pos.x = drawFn.call(font, color, item, Rect.new(pos.x, pos.y, 0, size.y))
			}
		}

		return pos
	}

	drawItems(items)                      { drawItems(items, false) }
	drawItems(items, rightAlign)          { drawItems(items, rightAlign, 0) }
	drawItems(items, rightAlign, yOffset) {
		var pos = contentOffset
		pos.y = pos.y + yOffset

		var f = Fn.new {|font, color, item, rect|
			return Common.drawText(font, color, item, null, rect).x
		}

		if (rightAlign) {
			var s = drawItems_(items, Vector.zero) {|font, color, text, rect| rect.x + font.width(text) }
			pos.x = pos.x + size.x - s.x - Style.padding.x
			drawItems_(items, pos, f)
		} else {
			pos.x = pos.x + Style.padding.x
			drawItems_(items, pos, f)
		}
	}

	items {
		return [
			[],
			[
				Style.iconFont, "g",
				Style.font, Style.dim, StatusView.separator2,
				0, // Core.docs.count
				Style.text, " / ",
				0, // Core.projectFiles
				" files"
			]
		]
	}

	draw() {
		drawBackground(Style.background2)

		if (_message) drawItems(_message, false, size.y)

		drawItems(items[0])
		drawItems(items[1], true)
	}
}
