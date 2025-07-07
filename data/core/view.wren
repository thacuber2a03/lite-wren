import "renderer" for Renderer

import "core" for Core
import "core/common" for Common, Vector, Rect

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
		var ret = (val-dest).abs < 0.5 ? dest : Common.lerp(val, dest, rate)
		if (val != dest) Core.redraw = true
		return ret
	}

	tryClose(doClose) { doClose.call() }
	name { "---" }
	scrollableSize { Num.infinity }

	update() {
		// clampScrollPosition()
		scroll.x = moveTowards(scroll.x, scrollTo.x, 0.3)
		scroll.y = moveTowards(scroll.y, scrollTo.y, 0.3)
	}

	drawBackground(color) {
		Renderer.drawRect(
			position.x, position.y,
			size.x+position.x%1, size.y+position.y%1,
			color
		)
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
