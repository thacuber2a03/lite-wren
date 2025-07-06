import "renderer" for Renderer

import "core" for Core
import "core/common" for Common, Vector, Rect
import "core/style" for Style

class View {
	construct new() {
		position = Vector.zero
		size = Vector.zero
		scroll = Vector.zero
		scrollTo = Vector.zero
		cursor = "arrow"
		scrollable = false
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

	tryClose(doClose) { doClose.call() }

	name { "---" }
	scrollableSize { Num.infinity }

	scrollbarRect {
		var sz = scrollableSize
		if (sz <= size.y || sz == Num.infinity) return List.filled(4,0)
		var h = 20.max(size.y * size.y / sz)
		return Rect.new(
			position.x + size.x - Style.scrollbarSize,
			position.y + scroll.y * (size.y - h) / (sz - size.y),
			Style.scrollbarSize,
			h
		)
	}

	onTextInput(text) {}
	// onMouseWheel(scroll) {}

	contentOffset { Vector.new((position.x-scroll.x).round, (position.y-scroll.y).round) }

	// onMouseMoved(mousePos, mouseDelta) {}
	// onMousePressed(button, mousePos, clicks) {}
	// onMouseReleased(button, mousePos) {}

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
}
