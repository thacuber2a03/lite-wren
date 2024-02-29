import "api" for Renderer, Program

class Common {
	static is_utf8_cont(char) {
		var byte = char.bytes[0]
		return byte >= 0x80 && byte < 0xc0
	}

	static lerp(a, b, t) {
		if (!(a is List)) return a + (b-a) * t
		var res = []
		for (i in 0...b.count) {
			res.insert(i, Common.lerp(a[i], b[i], t))
		}
		return res
	}

	static draw_text(font, color, text, align, rect) {
		var tw = font.width(text)
		var th = font.height
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

	static fuzzy_match_items(items, needle) {
		var res = []
		for (item in items) {
			var score = Program.fuzzy_match(item.toString, needle)
			if (score) res.add({ "text": item, "score": score })
		}
		res.sort { |a,b| a["score"] > b["score"] }
		for (i in 0...res.count) res[i] = res[i]["text"]
		return res
	}

	static fuzzy_match(haystack, needle) {
		if (haystack is List) return fuzzy_match_items(haystack, needle)
		return Program.fuzzy_match(haystack, needle)
	}
}

