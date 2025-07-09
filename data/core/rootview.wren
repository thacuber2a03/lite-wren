import "renderer" for Renderer
import "system" for Program, Window

import "core" for Core
import "core/common" for Common, Vector, Rect
import "core/docview" for DocView
import "core/keymap" for Keymap
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
			var text = line["fmt"].replace("{}", Keymap.binding(line["cmd"]))
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

	onMouseMoved(pos, delta) {
		_hoveredTab = tabOverlappingPoint(pos)
		if (_type == "leaf") {
			_activeView.onMouseMoved(pos, delta)
		} else {
			propagate {|n| n.onMouseMoved(pos, delta) }
		}
	}

	onMouseReleased(button, pos) {
		if (_type == "leaf") {
			_activeView.onMouseReleased(button, pos)
		} else {
			propagate {|n| n.onMouseReleased(button, pos) }
		}
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

	closeActiveView(root) {
		_activeView.tryClose {
			if (_views > 1) {
				_views.remove(_activeView)
				activeView = _views[idx.min(_views.count-1)]
			} else {
				Fiber.abort("hold up whar")
			}
		}
	}

	addView(view) {
		Common.assert(_type == "leaf", "Tried to add view to non-leaf node")
		Common.assert(!_locked, "Tried to add view to locked node")
		if (_views.count >= 1 && _views[0] is EmptyView) _views.removeAt(-1)
		_views.add(view)
		activeView = view
	}

	activeView=(view) {
		Common.assert(_type == "leaf", "Tried to set active view on non-leaf node")
		_activeView = view
		Core.activeView = view
	}

	viewIndex(view) {
		for (i in 0..._views.count) if (_views[i] == view) return i
	}

	getNodeForView(view) {
		for (v in _views) {
			if (v == view) return this
		}
		if (_type != "leaf") return _a.getNodeForView(view) || _b.getNodeForView(view)
	}

	parentNode(root) {
		if (root.a == this || root.b == this) {
			return root
		} else if (root.type != leaf) {
			return parentNode(root.a) || parentNode(root.b)
		}
	}

	children { children([]) }
	children(l) {
		for (view in _views) l.add(view)
		if (_a) _a.children(l)
		if (_b) _b.children(l)
		return l
	}

	dividerOverlappingPoint(pos) {
		if (_type == "leaf") return

		var p = Vector.new(6,6)
		var r = dividerRect
		r.position = r.position - p
		r.size = r.size + p*2
		if (pos.x > r.x && pos.y > r.y && pos.x < r.x + r.w && pos.y < r.y + r.h) return this

		return _a.dividerOverlappingPoint(pos) || _b.dividerOverlappingPoint(pos)
	}

	tabOverlappingPoint(pos) {
		if (_views.count == 1) return
		var r = tabRect(0)

		if (pos.x >= r.x && pos.y >= r.y &&
		    pos.x < r.x + r.w * _views.count &&
		    pos.y < r.y + r.h) return ((pos.x - r.x) / r.w).floor + 1
	}

	childOverlappingPoint(pos) {
		var child
		if (_type == "leaf") return this
		if (_type == "hsplit") child = pos.x < _b.position.x ? _a : _b
		if (_type == "vsplit") child = pos.y < _b.position.y ? _a : _b
		return child.childOverlappingPoint(pos)
	}

	tabRect(idx) {
		var tw = Style.tabWidth.min((size.x / _views.count).ceil)
		var h = Style.font.height + Style.padding.y * 2
		return Rect.new(position.x + idx * tw, position.y, tw, h)
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
				var tr = tabRect(0)
				var th = tr.h
				av.position.set(position.x, position.y + th)
				av.size.set(size.x, size.y - th)
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

	drawTabs() {
		var tr = tabRect(0)
		var ds = Style.dividerSize
		Core.pushClipRect(Rect.new(tr.pos, Vector.new(size.x, tr.h)))
		Renderer.drawRect(tr.x, tr.y, size.x, tr.h, Style.background2)
		Renderer.drawRect(tr.x, tr.y + tr.h - ds, size.x, ds, Style.divider)

		for (i in 0..._views.count) {
			var view = _views[i]
			var tr = tabRect(i)
			var text = view.name
			var color = Style.dim
			if (view == _activeView) {
				color = Style.text
				Renderer.drawRect(tr.x, tr.y, tr.w, tr.h, Style.background)
				Renderer.drawRect(tr.x + tr.w, tr.y, ds, tr.h, Style.divider)
				Renderer.drawRect(tr.x - ds, tr.y, ds, tr.h, Style.divider)
			}
			if (i == _hoveredTab) color = Style.text
			Core.pushClipRect(tr)
			tr.x = tr.x + Style.padding.x
			tr.w = tr.w - Style.padding.x * 2
			var align = Style.font.width(text) > tr.w ? "left" : "center"
			Common.drawText(Style.font, color, text, align, tr)
			Core.popClipRect()
		}

		Core.popClipRect()
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
	divider=(v) { _divider=v }
	a { _a }
	b { _b }
	locked { _locked }
	locked=(v) { _locked=v }

	activeView { _activeView }
}

class RootView is View {
	construct new() {
		super()
		_rootNode = Node.new()
		_deferredDraws = []
		_mouse = Vector.zero
	}

	deferDraw(f) { _deferredDraws.add(f) }

	activeNode { _rootNode.getNodeForView(Core.activeView) }

	openDoc(doc) {
		var node = activeNode
		if (node.locked && Core.lastActiveView) {
			Core.activeView = Core.lastActiveView
			node = activeNode
		}
		Common.assert(!node.locked, "Cannot open doc on locked node")
		for (view in node.views) {
			if (view is DocView && view.doc == doc) {
				node.activeView = view
				return view
			}
		}
		var view = DocView.new(doc)
		node.addView(view)
		_rootNode.updateLayout()
		// view.scrollToLine(view.doc.selection, true, true)
		return view
	}

	onMousePressed(button, pos, clicks) {
		var div = _rootNode.dividerOverlappingPoint(pos)
		if (div) {
			_draggedDivider = div
			return
		}
		var node = _rootNode.childOverlappingPoint(pos)
		var idx = node.tabOverlappingPoint(pos)
		if (idx) {
			node.activeView = node.views[idx]
			if (button == "middle") node.closeActiveView(_rootNode)
		} else {
			Core.activeView = node.activeView
			node.activeView.onMousePressed(button, pos, clicks)
		}
	}

	onMouseReleased(button, pos) {
		if (_draggedDivider) _draggedDivider = null
		_rootNode.onMouseReleased(button, pos)
	}

	onMouseMoved(pos, delta) {
		if (_draggedDivider) {
			var node = _draggedDivider
			if (node.type == "hsplit") {
				node.divider = node.divider + delta.x / node.size.x
			} else {
				node.divider = node.divider + delta.y / node.size.y
			}
			node.divider = node.divider.clamp(0.01, 0.99)
			return
		}

		_mouse.set(pos)
		_rootNode.onMouseMoved(pos, delta)

		var node = _rootNode.childOverlappingPoint(pos)
		var div = _rootNode.dividerOverlappingPoint(pos)
		if (div) {
			Window.cursor = div.type == "hsplit" ? "sizeh" : "sizev"
		} else if (node.tabOverlappingPoint(pos)) {
			Window.cursor = "arrow"
		} else {
			Window.cursor = node.activeView.cursor
		}
	}

	onMouseWheel(scroll) {
		var node = _rootNode.childOverlappingPoint(_mouse)
		node.activeView.onMouseWheel(scroll)
	}

	onTextInput(text) { Core.activeView.onTextInput(text) }

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
