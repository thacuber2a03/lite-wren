import "renderer" for Renderer

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

	static drawText(font, color, text, align, rect) {
		var tw = font.width(text)
		var th = font.height
		if (align == "center") {
			rect.x = rect.x + (rect.w - tw) / 2
		} else if (align == "right") {
			rect.x = rect.x + (rect.w - tw)
		}
		rect.y = (rect.y + (rect.h - th) / 2).round
		return Vector.new(
			Renderer.drawText(font, text, rect.x, rect.y, color),
			rect.y + th
		)
	}
}

class Vector {
	construct new(x, y) { set(x, y) }

	static zero { Vector.new(0, 0) }

	copy { Vector.new(_x, _y) }

	round { Vector.new(_x.round, _y.round) }

	set(x, y) {
		Common.assert(x is Num && y is Num, "set(x,y): expected x and y to be Num, were %(x.type) and %(y.type) respectively")
		_x = x
		_y = y
	}

	set(v) {
		Common.assert(v is Vector, "set(v): expected v to be Vector, was %(v.type)")
		_x = v.x
		_y = v.y
	}

	min(v) {
		Common.assert(v is Vector, "min(v): expected v to be Vector, was %(v.type)")
		return Vector.new(_x.min(v.x), _y.min(v.y))
	}

	max(v) {
		Common.assert(v is Vector, "max(v): expected v to be Vector, was %(v.type)")
		return Vector.new(_x.max(v.x), _y.max(v.y))
	}

	x { _x }
	x=(v) { _x=v }
	y { _y }
	y=(v) { _y=v }

	+(other) { Vector.new(_x+other.x, _y+other.y) }
	- { Vector.new(-_x, -_y) }
	-(other) { this + -other }

	*(other) {
		if (other is Num) return Vector.new(_x*other, _y*other)
		Fiber.abort("Vector * %(other): expected Num but got %(other.type)")
	}

	[k] {
		if (k == "x" || k == 0) return _x
		if (k == "y" || k == 1) return _y
		Fiber.abort("attempt to access invalid field '%(k)'")
	}

	[k]=(v) {
		if (k == "x" || k == 0) return _x=v
		if (k == "y" || k == 1) return _y=v
		Fiber.abort("attempt to set invalid field '%(k)'")
	}

	toList { [_x, _y] }
	toString { "(%(_x), %(_y))" }
}

class Rect {
	construct new(x,y,w,h) {
		_position = Vector.new(x,y)
		_size = Vector.new(w,h)
	}

	construct new(pos, size) {
		_position = pos
		_size = size
	}

	copy { Rect.new(_position, _size) }

	set(x,y,w,h) {
		_position.set(x,y)
		_size.set(w,h)
	}

	set(pos, size) {
		_position = pos.copy
		_size = size.copy
	}

	x { _position.x }
	x=(v) { _position.x=v }
	y { _position.y }
	y=(v) { _position.y=v }
	w { _size.x }
	w=(v) { _size.x=v }
	h { _size.y }
	h=(v) { _size.y=v }

	width { _size.x }
	width=(v) { _size.x=v }
	height { _size.y }
	height=(v) { _size.y=v }

	position { Vector.new(_position.x, _position.y) }
	pos { position }
	size { Vector.new(_size.x, _size.y) }

	toList { [_position.x, _position.y, _size.x, size.y] }
	toString { "%(_position)-%(size)" }
}
