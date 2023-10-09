class Vector {
	construct new(x, y) {
		_x = x
		_y = y
	}

	construct new() {
		_x = 0
		_y = 0
	}

	x { _x }
	y { _y }

	x=(v) { _x=v }
	y=(v) { _y=v }

	asList { [x, y] }

	[prop] {
		if (prop == "x") return _x
		if (prop == "y") return _y
		Fiber.abort("invalid property access %(prop)")
	}

	[prop]=(value) {
		if (prop == "x") _x = value
		if (prop == "y") _y = value
		Fiber.abort("invalid property assign %(prop)")
	}
}

class Rect {
	construct new(x, y, w, h) {
		_x = x
		_y = y
		_w = w
		_h = h
	}

	x { _x }
	y { _y }
	width { _w }
	height { _h }

	x=(v) { _x=v }
	y=(v) { _y=v }
	width=(v) { _w=v }
	height=(v) { _h=v }

	asList { [x, y, width, height] }
}
