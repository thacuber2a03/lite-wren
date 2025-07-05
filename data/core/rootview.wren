import "system" for Program
import "renderer" for Renderer

import "core/common" for Common, Vector
import "core/style" for Style
import "core/view" for View
import "core" for Core

class EmptyView is View {
	construct new() {
		super()
	}

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
		var x = position.x + Style.padding.x.max(textSize.x - size.x) / 2
		var y = position.y + (size.y - textSize.y) / 2
		drawText_(x, y, Style.dim)
	}
}

class Node {
	construct new()     { init("leaf") }
	construct new(type) { init(type)   }

	init(type) {
		_type = type
		_position = Vector.zero
		_size = Vector.zero
		_views = []
		_divider = 0.5
		if (_type == "leaf") {
			addView(EmptyView.new())
			// TODO(thacuber2a03): haxxxxx!!!!!!!!!!! stop procrastinating Node already
			var s = Renderer.size
			_activeView.size.set(s[0], s[1])
		}
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

	draw() {
		if (_type == "leaf") {
			System.print(_views[0].position)
			System.print(_views[0].size)
			if (_views.count > 1) drawTabs()
			// var pos = _activeView.position
			// var size = _activeView.size
			_activeView.draw()
		} else {
			Renderer.drawRect(x, y, w, h, Style.divider)
		}
	}
}

class RootView is View {
	construct new() {
		super()
		_rootNode = Node.new()
		_deferredDraws = {}
		_mouse = Vector.zero
	}

	draw() {
		_rootNode.draw()
	}
}
