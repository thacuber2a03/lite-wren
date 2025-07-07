import "renderer" for Renderer
import "system" for Program

import "core" for Core
import "core/common" for Common, Vector
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
			_position.x + Style.padding.x.max((_size.x-textSize.x)/2),
			_position.y + (_size.y-textSize.y)/2
		), Style.dim)
	}
}

class Node {
	construct new(type) { init(type) }
	construct new()     { init("leaf") }

	init(type) {
		_type = type
		_position = Vector.zero
		_size = Vector.zero
		_views = []
		_divider = 0.5
		if (_type == "leaf") addView(EmptyView.new())
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

	updateLayout() {
		if (_type == "leaf") {
			var av = _activeView
			if (_views.count > 1) {

			} else {
				av.position.set(_position)
				av.size.set(_size)
			}
		} else {
			// _a.updateLayout()
			// _b.updateLayout()
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
			_activeView.draw()
		}
	}

	position { _position }
}

class RootView is View {
	construct new() {
		super()
		_rootNode = Node.new()
		_deferredDraws = []
		_mouse = Vector.zero
	}

	update() {
		// _rootNode.position.set(_position)
		// _rootNode.size.set(_size)
		_rootNode.update()
		_rootNode.updateLayout()
	}

	draw() {
		_rootNode.draw()
	}
}
