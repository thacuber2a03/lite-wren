import "renderer" for Renderer
import "system" for Program

import "core" for Core
import "core/common" for Common, Vector, Rect
import "core/style" for Style
import "core/view" for View

class EmptyView is View {
	construct new() {
		super()
	}

	drawText(pos, color) {
		var th = Style.bigFont.height
		var dh = th + Style.padding.y * 2
		pos.x = Renderer.drawText(Style.bigFont, "lite-wren", pos.x, pos.y + (dh-th) / 2, color)
		pos.x = pos.x + Style.padding.x
		Renderer.drawRect(pos.x, pos.y, Program.scale.ceil, dh, color)
		var lines = [
			{ "fmt": "{} to run a command",                "cmd": "core:find-command" },
			{ "fmt": "{} to open a file from the project", "cmd": "core:find-file"    },
		]
		th = Style.font.height
		pos.y = pos.y + (dh - th * 2 - Style.padding.y) / 2
		var w = 0
		for (line in lines) {
			var text = line["fmt"].replace("{}", line["cmd"])
			w = w.max(Renderer.drawText(Style.font, text, pos.x+Style.padding.x, pos.y, color))
			pos.y = pos.y + th + Style.padding.y
		}
		return Vector.new(w, dh)
	}

	draw() {
		drawBackground(Style.background)
		var textSize = drawText(Vector.zero, List.filled(4,0))
		drawText(Vector.new(
			position.x + Style.padding.x.max((size.x-textSize.x)/2),
			position.y + (size.y-textSize.y)/2
		), Style.dim)
	}
}

class Node {
	construct new(type) { init(type) }
	construct new()     { init("leaf") }

	init(type) {
		if (!__typeMap) __typeMap = {
			"up": "vsplit", "left": "hsplit",
			"down": "vsplit", "right": "hsplit"
		}

		_type = type
		_position = Vector.zero
		_size = Vector.zero
		_views = []
		_divider = 0.5
		if (_type == "leaf") addView(EmptyView.new())
	}

	propagate(f) {
		f.call(_a)
		f.call(_b)
	}

	consume(node) {
		_type = node.kind
		_position = node.position
		_size = node.size
		_views = node.views
		_divider = node.divider
		_a = node.a
		_b = node.b
	}

	split(dir) { split(dir, null) }
	split(dir, view) { split(dir, view, false) }
	split(dir, view, locked) {
		Common.assert(_type == "leaf", "Tried to split non-leaf node")
		var type = Common.assert(__typeMap[dir], "Invalid direction")
		var lastActive = Core.activeView
		var child = Node.new()
		child.consume(this)
		consume(Node.new(type))
		_a = child
		_b = Node.new()
		if (view) b.addView(view)
		if (locked) {
			_b.locked = locked
			Core.activeView = lastActive
		}
		if (dir == "up" || dir == "left") {
			var temp = _a
			_b = _a
			_a = temp
		}
		return child
	}

	addView(view) {
		Common.assert(_type == "leaf", "Tried to add view to non-leaf node")
		Common.assert(!_locked, "Tried to add view to locked node")
		if (_views.count >= 1 && _views[0] is EmptyView) _views.removeAt(-1)
		_views.add(view)
		setActiveView(view)
	}

	setActiveView(view) {
		Common.assert(_type == "leaf", "Tried to set active view on non-leaf node")
		_activeView = view
		Core.activeView = view
	}

	dividerRect {
		if (_type == "hsplit") {
			return Rect.new(
				_position.x + _a.size.x, _position.y,
				Style.dividerSize, size.y
			)
		} else if (_type == "vsplit") {
			return Rect.new(
				_position.x, _position.y + _a.size.y,
				_size.x, Style.dividerSize
			)
		}
	}

	lockedSize {
		if (_type == "leaf") {
			if (_locked) return _activeView.size
		} else {
			var s1 = _a.lockedSize
			var s2 = _b.lockedSize
			if (s1 && s2) {
				return Vector.new(
					s1.x + s2.x + (s1.x < 1 || s2.x < 1 ? 0 : Style.dividerSize),
					s1.y + s2.y + (s1.y < 1 || s2.y < 1 ? 0 : Style.dividerSize)
				)
			}
		}
	}

	calcSplitSizes_(x, y, x1, x2) {
		var n
		var ds = (x1 && x1 < 1 || x2 && x2 < 1) ? 0 : Style.dividerSize
		if (x1) {
			n = x1 + ds
		} else if (x2) {
			n = _size[x] - x2
		} else {
			n = (_size[x] * _divider).floor
		}
		_a.position[x] = _position[x]
		_a.position[y] = _position[y]
		_a.size[x] = n - ds
		_a.size[y] = _size[y]
		_b.position[x] = _position[x] + n
		_b.position[y] = _position[y]
		_b.size[x] = _size[x] - n
		_b.size[y] = _size[y]
	}

	updateLayout() {
		if (_type == "leaf") {
			var av = _activeView
			if (_views.count > 1) {

			} else {
				av.position.set(_position)
				av.size.set(_size)
			}
		} else {
			var s1 = _a.lockedSize
			var s2 = _b.lockedSize
			if (_type == "hsplit") {
				calcSplitSizes_("x", "y", s1 && s1.x, s2 && s2.x)
			} else if (_type == "vsplit") {
				calcSplitSizes_("y", "x", s1 && s1.y, s2 && s2.y)
			}
			_a.updateLayout()
			_b.updateLayout()
		}
	}

	update() {
		if (_type == "leaf") {
			for (view in _views) view.update()
		} else {
			_a.update()
			_b.update()
		}
	}

	draw() {
		if (_type == "leaf") {
			if (_views.count > 1) drawTabs()
			Core.pushClipRect(Rect.new(_activeView.position, _activeView.size))
			_activeView.draw()
			Core.popClipRect()
		} else {
			var r = dividerRect
			Renderer.drawRect(r.x, r.y, r.w, r.h, Style.divider)
			propagate {|n| n.draw() }
		}
	}

	kind { _type }
	position { _position }
	size { _size }
	views { _views }
	divider { _divider }
	a { _a }
	b { _b }
	locked=(v) { _locked=v }
}

class RootView is View {
	construct new() {
		super()
		_rootNode = Node.new()
		_deferredDraws = []
		_mouse = Vector.zero
	}

	update() {
		super()
		_rootNode.position.set(position)
		_rootNode.size.set(size)
		_rootNode.update()
		_rootNode.updateLayout()
	}

	draw() {
		_rootNode.draw()
	}

	rootNode { _rootNode }
}
