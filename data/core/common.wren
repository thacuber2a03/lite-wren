class Common {
	static lerp(a, b, t) { a + (b-a) * t }

	// currently just #abcdef styled strings are supported
	static color(str) {
		if (str[0] != "#") Fiber.abort("bar color string " + str)
		var col = []

		for (i in 0..2) {
			var curNum = i * 2 + 1
			var n = Num.fromString("0x" + str[curNum..curNum+1])
			col.add(n)
		}

		col.add(0xff)
		return col
	}
}
