import "renderer" for Renderer

import "core" for Core
import "core/common" for Common, Vector, Rect
import "core/style" for Style

class View {
	construct new() {
		_position = Vector.zero
		_size = Vector.zero
		_scroll = Vector.zero
		_scrollTo = Vector.zero
		_cursor = "arrow"
		_scrollable = false
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

	scrollbarRect {
		var sz = scrollableSize
		if (sz <= size.y || sz == Num.infinity) return Rect.zero
		var h = 20.max(size.y * size.y / sz)
		return Rect.new(
			position.x + size.x - Style.scrollbarSize,
			position.y + scroll.y * (size.y - h) / (sz - size.y),
			Style.scrollbarSize,
			h
		)
	}

	scrollbarOverlapsPoint(p) {
		var s = scrollbarRect
		return p.x >= s.x - s.w * 3 && p.x < s.x + s.w &&
		       p.y >= s.y && p.y < s.y + s.h
	}

	onMousePressed(button, pos, clicks) {
		if (scrollbarOverlapsPoint(pos)) {
			_draggingScrollbar = true
			return true
		}
	}

	onMouseReleased(button, pos) { _draggingScrollbar = false }

	onMouseMoved(pos, delta) {
		if (_draggingScrollbar) {
			var delta = scrollableSize / size.y * delta.y
			scrollTo.y = scrollTo.y + delta
		}
		_hoveredScrollbar = scrollbarOverlapsPoint(pos)
	}

	contentOffset { (position-scroll).round }

	clampScrollPosition() {
		var max = scrollableSize - _size.y
		_scrollTo.y = _scrollTo.y.clamp(0, max)
	}

	update() {
		clampScrollPosition()
		_scroll.x = moveTowards(_scroll.x, _scrollTo.x, 0.3)
		_scroll.y = moveTowards(_scroll.y, _scrollTo.y, 0.3)
	}

	drawBackground(color) {
		Renderer.drawRect(
			_position.x, _position.y,
			_size.x+_position.x%1, _size.y+_position.y%1,
			color
		)
	}

	drawScrollbar() {
		var r = scrollbarRect
		var highlight = _hoveredScrollbar || _draggingScrollbar
		var color = highlight ? Style.scrollbar2 : Style.scrollbar
		Renderer.drawRect(r.x, r.y, r.w, r.h, color)
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
