import "api" for Renderer

class Common {
	static lerp(a, b, t) { a + (b-a) * t }

	static draw_text(font, color, text, align, rect) {
		var tw = font.get_width(text)
		var th = font.get_height()
		if (align == "center") {
			rect.x = rect.x + (rect.w - tw) / 2
		} else if (align == "right") {
			rect.x = rect.x + (rect.w - tw)
		}
		rect.y = (rect.y + (rect.h - th) / 2)
		return [
			Renderer.draw_text(font, text, rect.x, rect.y, color),
			rect.y + th
		]
	}

	// currently just '#abcdef' styled strings are supported
	static color(str) {
		var col = []

		var res = Fiber.new {
			for (i in 0..2) {
				var curNum = i * 2 + 1
				var n = Num.fromString("0x" + str[curNum..curNum+1])
				col.add(n)
			}
		}.try()

		if (res != null) Fiber.abort("bad color string %(str)")

		col.add(0xff)
		return col
	}

	static assert(cond) { assert(cond, "assertion failed") }

	static assert(cond, err) {
		if (!cond) Fiber.abort(err)
		return cond
	}
}

