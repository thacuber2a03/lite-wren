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
		var err = "bad color string '%(s)'"
		assert(s[0] == "#", err)
		s = s[1..-1]

		var color = []
		var match = Fn.new {
			color.add(parseHexNumber(s[0..1]))
			s = s[2..-1]
		}

		for (i in 0...3) match.call()
		if (s.count != 0) match.call() else color.add(255)
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

class Vector {
	construct new(x, y) { set(x, y) }

	static zero { Vector.new(0, 0) }

	copy { Vector.new(_x, _y) }

	round { Vector.new(_x.round, _y.round) }

	set(x, y) {
		_x = x
		_y = y
	}

	set(v) {
		_x = v.x
		_y = v.y
	}

	x { _x }
	x=(v) { _x=v }
	y { _y }
	y=(v) { _y=v }

	+(other) { Vector.new(_x+other.x, _y+other.y) }

	*(other) {
		if (other is Num) return Vector.new(_x*other, _y*other)
		Fiber.abort("Vector * other: expected Num but got %(other.type)")
	}

	toString { "(%(_x), %(_y))" }
}

class Rect {
	construct new(x,y,w,h) { _data = [x,y,w,h] }

	set(x,y,w,h) {
		_data[0] = x
		_data[1] = y
		_data[2] = w
		_data[3] = h
	}

	x { _data[0] }
	x=(v) { _data[0]=v }
	y { _data[1] }
	y=(v) { _data[1]=v }
	w { _data[2] }
	w=(v) { _data[2]=v }
	h { _data[3] }
	h=(v) { _data[3]=v }

	toList { _data }
	toString { "(%(_data.join(", ")))" }
}
