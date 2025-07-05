class Vector {
	construct new(x, y) { set(x, y) }

	static zero { Vector.new(0,0) }

	set(x, y) {
		_x = x
		_y = y
	}

	- { Vector.new(-_x, -_y) }

	+(other) { Vector.new(_x+other.x, _y+other.y) }
	-(other) { Vector.new(_x-other.x, _y-other.y) }

	*(other) {
		if (other is Num) return Vector.new(_x*other, y*other)
		Fiber.abort("expected Num, got %(other.type)")
	}

	x { _x }
	x=(v) { _x=v }
	y { _y }
	y=(v) { _y=v }

	toList { [_x, _y] }
	toString { "(%(_x), %(_y))" }
}

class Common {
	static assert(cond) { assert(cond, "Assertion failed") }
	static assert(cond, msg) {
		if (!cond) Fiber.abort(msg)
		return cond
	}

	static parseHexNumber(s) {
		var n = 0
		for (c in s) {
			c = c.bytes[0]
			var a
			if (c >= 97 && c <= 102) {
				a = c - 97 + 10 // 97 - a
			} else if (c >= 65 && c <= 70) {
				a = c - 65 + 10 // 65 - A
			} else if (c >= 48 && c <= 57) {
				a = c - 48 // 48 - 0
			} else {
				Fiber.abort("invalid hex digit: %(c)")
			}
			n = (n * 16) + a
		}
		return n
	}

	static color(s) {
		var err = "bad color string %(s)"
		assert(s[0] == "#", err)
		s = s[1..-1]

		var color = []
		var match = Fn.new {
			color.add(parseHexNumber(s[0..1]))
			s = s[2..-1]
		}

		for (i in 0...3) match.call()
		if (s.count != 0) match.call()
		assert(s.count == 0, err)
		return color
	}

	static lerp(a, b, t) {
		if (a is List) return a.map{|x| lerp(x, b, t) }.toList
		if (a is Map) {
			var m = {}
			for (kv in a) m[kv.key] = lerp(a[kv.key], b, t)
			return m
		}
		return a + (b - a) * t
	}
}
