import "renderer" for Renderer

import "core/common" for Common, Vector
import "core" for Core

class View {
	construct new() {
		position = Vector.zero
		size = Vector.zero
		scroll = Vector.zero
		scrollTo = Vector.zero
		cursor = "arrow"
		scrollable = false
		name = "---"
	}

	moveTowards(val, dest) { moveTowards(val, dest, 0.5) }
	moveTowards(val, dest, rate) {
		var ret
		if ((val - dest).abs < 0.5) {
			ret = dest
		} else {
			ret = Common.lerp(val, dest, rate)
		}
		if (val != dest) Core.redraw = true
		return ret
	}

	onTextInput(text) {}
	onMouseMoved(mousePos, mouseDelta) {}
	onMousePressed(button, mousePos, clicks) {}
	onMouseReleased(button, mousePos) {}
	onMouseWheel(scroll) {}

	update() {
		scroll.x = moveTowards(scroll.x, scrollTo.x, 0.3)
		scroll.y = moveTowards(scroll.y, scrollTo.y, 0.3)
	}

	drawBackground(color) {
		var x = position.x
		var y = position.y
		var w = size.x
		var h = size.y
		Renderer.drawRect(x, y, w+x%1, h+y%1, color)
	}

	draw() {}

	position { _position }
	position=(v) { _position=v }
	size { _size }
	size=(v) { _size=v }
	scroll { _scroll }
	scroll=(v) { _scroll=v }
	scrollTo { _scrollTo }
	scrollTo=(v) { _scrollTo=v }
	cursor { _cursor }
	cursor=(v) { _cursor=v }
	scrollable { _scrollable }
	scrollable=(v) { _scrollable=v }

	name { _name }
	name=(v) { _name=v }
}
