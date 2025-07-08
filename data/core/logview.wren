import "system" for OS
import "renderer" for Renderer

import "core" for Core
import "core/common" for Common, Vector
import "core/style" for Style
import "core/view" for View

class LogView is View {
	construct new() {
		super()
		_lastItem = Core.logItems[-1]
		scrollable = true
		_yOffset = 0
	}

	name { "Log" }

	update() {
		var item = Core.logItems[-1]
		if (_lastItem != item) {
			_lastItem = item
			scrollTo.y = 0
			_yOffset = -(Style.font.height + Style.padding.y)
		}

		_yOffset = moveTowards(_yOffset, 0)

		super()
	}

	drawTextMultiline_(font, text, x, y, color) {
		var th = font.height
		var resx = x
		var resy = y

		Common.lines(text) {|line|
			resy = y
			resx = Renderer.drawText(Style.font, line, x, y, color)
			y = y + th
		}

		return Vector.new(resx, resy)
	}

	draw() {
		drawBackground(Style.background)

		var off = contentOffset
		var th = Style.font.height
		var y = off.y + Style.padding.y + _yOffset

		for (i in (Core.logItems.count-1)..0) {
			var x = off.x + Style.padding.x
			var item = Core.logItems[i]
			var time = OS.formatTime(item["time"])
			x = Renderer.drawText(Style.font, time, x, y, Style.dim) + Style.padding.x
			var subx = x
			var pos = drawTextMultiline_(Style.font, item["text"], x, y, Style.text)
			Renderer.drawText(Style.font, " at %(item["at"])", pos.x, pos.y, Style.dim)
			y = pos.y + th
			if (item["info"]) {
				var pos = drawTextMultiline_(Style.font, item["info"], subx, y, Style.dim)
				subx = pos.x
				y = pos.y + th
			}
			y = y + Style.padding.y
		}
	}
}
