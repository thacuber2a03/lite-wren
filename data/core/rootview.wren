import "system" for Program
import "renderer" for Renderer

import "core/common" for Common, Vector
import "core/style" for Style
import "core/view" for View
import "core" for Core

class EmptyView is View {
	construct new() { super() }

	drawText_(x, y, color) {
		var th = Style.bigFont.height
		var dh = th + Style.padding.y * 2
		x = Renderer.drawText(Style.bigFont, "lite-wren", x, y + (dh-th) / 2, color)
		x = x + Style.padding.x
		Renderer.drawRect(x, y, Program.scale.ceil, dh, color)
		var lines = [
			{ "fmt": "{} to run a command", "cmd": "core:find-command" },
			{ "fmt": "{} to open a file from the project", "cmd": "core:find-file" },
		]
		th = Style.font.height
		y = y + (dh - th * 2 - Style.padding.y) / 2
		var w = 0
		for (line in lines) {
			var text = line["fmt"].replace("{}", line["cmd"])
			w = w.max(Renderer.drawText(Style.font, text, x + Style.padding.x, y, color))
			y = y + th + Style.padding.y
		}
		return Vector.new(w, dh)
	}

	draw() {
		drawBackground(Style.background)
		var textSize = drawText_(0, 0, List.filled(4, 0))
		var x = position.x + Style.padding.x.max(size.x-textSize.x) / 2
		var y = position.y + (size.y - textSize.y) / 2
		drawText_(x, y, Style.dim)
	}
}

var CopyPositionAndSize_ = Fn.new {|dst, src|
	dst.position.set(src.position)
	dst.size.set(src.size)
}

var TypeMap_ = {
	"up": "vsplit",
	"down": "vsplit",
	"left": "hsplit",
	"right": "hsplit",
}

class Node {
	construct new()     { init_("leaf") }
	construct new(type) { init_(type)   }

	init_(type) {
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

	onMouseMoved(mousePos, mouseDelta) {
		// _hoveredTab = getTabOverlappingPoint(mousePos)
		if (_type == "leaf") {
			_activeView.onMouseMoved(mousePos, mouseDelta)
		} else {
			propagate {|n| n.onMouseMoved(mousePos, mouseDelta) }
		}
	}

	onMouseReleased(button, mousePos, mouseDelta, clicks) {
		if (_type == "leaf") {
			_activeView.onMouseReleased(button, mousePos, mouseDelta, clicks)
		} else {
			propagate {|n| n.onMouseReleased(button, mousePos, mouseDelta, clicks) }
		}
	}

	consume(node) {
		// no self[k] = v trick :pensive:
		_type = node.type
		_position = node.position
		_size = node.size
		_views = node.views
		_divider = node.divider
		_activeView = node.activeView
		_locked = node.locked
		_a = node.a
		_b = node.b
	}

	split(dir) { split(dir, null) }
	split(dir, view) { split(dir, view, false) }
	split(dir, view, locked) {
		Common.assert(_type == "leaf", "Tried to split non-leaf node")
		var type = Common.assert(TypeMap_[dir], "Invalid direction")
		var lastActive = Core.activeView
		var child = Node.new()
		child.consume(this)
		consume(Node.new(type))
		_a = child
		_b = Node.new()
		if (view) _b.addView(view)
		if (locked) {
			_b.locked = locked
			Core.setActiveView(lastActive)
		}
		if (dir == "up" || dir == "left") {
			var temp = _a
			_a = _b
			_b = temp
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
		Core.setActiveView(view)
	}

	lockedSize {
		if (_type == "leaf") {
			if (_locked) return _activeView.size
		} else {
			var s1 = _a.lockedSize
			var s2 = _b.lockedSize
			if (s1 && s2) {
				return Vector.new(
					s1.x+s2.x + ((s1.x < 1 || s2.x < 1) ? 0 : Style.dividerSize),
					s1.y+s2.y + ((s1.y < 1 || s2.y < 1) ? 0 : Style.dividerSize)
				)
			}
		}
		return Vector.new(null, null) // *a technicality*
	}

	calcSplitSizes_(x, y, x1, x2) {
		var n
		var ds = (x1 && x1 < 1 || x2 && x2 < 1) ? 0 : Style.dividerSize
		if (x1) {
			n = x1 + ds
		} else if (x2) {
			n = size[x] - x2
		} else {
			n = (size[x] * divider).floor
		}
		a.position[x] = position[x]
		a.position[y] = position[y]
		a.size[x] = n - ds
		a.size[y] = size[y]
		b.position[x] = position[x] + n
		b.position[y] = position[y]
		b.size[x] = size[x] - ds
		b.size[y] = size[y]
	}

	updateLayout() {
		if (_type == "leaf") {
			var av = _activeView
			if (_views.count > 1) {
				// TODO(thacuber2a03): something something tabs
			} else {
				CopyPositionAndSize_.call(av, this)
			}
		} else {
			var s1 = _a.lockedSize
			var s2 = _b.lockedSize
			if (_type == "hsplit") {
				calcSplitSizes_("x", "y", s1.x, s2.x)
			} else if (_type == "vsplit") {
				calcSplitSizes_("y", "x", s1.y, s2.y)
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
			// if (_views.count > 1) drawTabs()
			// var pos = _activeView.position
			// var size = _activeView.size
			_activeView.draw()
		} else {
			// Renderer.drawRect(x, y, w, h, Style.divider)
			propagate {|n| n.draw() }
		}
	}

	type { _type }
	type=(v) { _type=v }
	position { _position }
	position=(v) { _position=v }
	size { _size }
	size=(v) { _size=v }
	views { _views }
	views=(v) { _views=v }
	divider { _divider  }
	divider=(v) { _divider=v  }
	activeView { _activeView }
	activeView=(v) { _activeView=v }
	locked { _locked }
	locked=(v) { _locked=v }
	a { _a }
	a=(v) { _a=v }
	b { _b }
	b=(v) { _b=v }
}

class RootView is View {
	construct new() {
		super()
		_rootNode = Node.new()
		_deferredDraws = {}
		_mouse = Vector.zero
	}

	update() {
		CopyPositionAndSize_.call(_rootNode, this)
		_rootNode.update()
		_rootNode.updateLayout()
	}

	draw() {
		_rootNode.draw()
	}

	rootNode { _rootNode }
}
