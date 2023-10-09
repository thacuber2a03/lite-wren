import "api" for Program, Renderer
import "core/shapes" for Vector, Rect
import "core/common" for Common
import "core/style" for Style
import "core/keymap" for Keymap
import "core/view" for View
import "core/docview" for DocView

class EmptyView is View {
	construct new() { super() }

	draw_text(x, y, color) {
		var th = Style.big_font.get_height()
		var dh = th + Style.padding.y * 2
		x = Renderer.draw_text(Style.big_font, "lite", x, y + (dh - th) / 2, color)
		x = x + Style.padding.x
		Renderer.draw_rect(x, y, (1 * Program.SCALE).ceil, dh, color)
		var lines = [
			{ "fmt": "@ to run a command", "cmd": "core:find-command" },
			{ "fmt": "@ to open a file from the project", "cmd": "core:find-file" },
		]
		th = Style.font.get_height()
		y = y + (dh - th * 2 - Style.padding.y) / 2
		var w = 0
		for (line in lines) {
			var text = line["fmt"].replace("@", Keymap.get_binding(line["cmd"]))
			w = w.max(Renderer.draw_text(Style.font, text, x + Style.padding.x, y, color))
			y = y + th + Style.padding.y
		}
		return [w, dh]
	}

	draw() {
		draw_background(Style.background)
		var size = draw_text(0, 0, [0,0,0,0])
		var x = this.position.x + Style.padding.x.max((this.size.x - size[0]) / 2)
		var y = this.position.y + (this.size.y - size[1]) / 2
		draw_text(x, y, Style.dim)
	}
}

var Copy_position_and_size = Fn.new { |dst, src|
	dst.position.x = src.position.x
	dst.position.y = src.position.y
	dst.size.x = src.size.x
	dst.size.y = src.size.y
}

class Node {
	construct new(type) {
		_type = type
		_position = Vector.new()
		_size = Vector.new()
		_views = []
		_divider = 0.5
	}

	construct new() {
		_type = "leaf"
		_position = Vector.new()
		_size = Vector.new()
		_views = []
		_divider = 0.5
		add_view(EmptyView.new())
	}

	type { _type }
	position { _position }
	size { _size }
	views { _views }
	divider { _divider }
	locked { _locked }
	locked=(v) { _locked = v }
	a { _a }
	b { _b }

	propagate(args, fn) {
		fn.call(_a, args)
		fn.call(_b, args)
	}

	on_mouse_moved(event) {
		_hovered_tab = get_tab_overlapping_point(event[1], event[2])
		if (_type == "leaf") {
			_active_view.on_mouse_moved(event)
		} else {
			propagate(event) { |n, a| n.on_mouse_moved(a) }
		}
	}

	on_mouse_released(event) {
		if (_type == "leaf") {
			_active_view.on_mouse_released(event)
		} else {
			propagate(event) { |n, a| n.on_mouse_released(a)  }
		}
	}

	consume(node) {
		_type = node.type
		_position = node.position
		_size = node.size
		_views = node.views
		_divider = node.divider
		_a = node.a
		_b = node.b
	}

	split(dir, view, locked) {
		import "core" for Core
		if (!__type_map) {
			__type_map = { "up": "vsplit", "down": "vsplit", "left": "hsplit", "right": "hsplit" }
		}

		Common.assert(_type == "leaf", "Tried to split non-leaf node")
		var type = Common.assert(__type_map[dir], "Invalid direction")
		var last_active = Core.active_view
		var child = Node.new()
		child.consume(this)
		this.consume(Node.new(type))
		_a = child
		_b = Node.new()
		if (view) _b.add_view(view)
		if (locked) {
			_b.locked = locked
			Core.set_active_view(last_active)
		}
		if (dir == "up" || dir == "left") {
			var temp = _a
			_a = _b
			_b = temp
		}
		return child
	}

	close_active_view(root) {
		import "core" for Core
		var do_close = Fn.new {
			if (_views.count > 1) {
				var idx = get_view_idx(_active_view)
				_views.remove(_active_view)
				set_active_view(_views[idx] || _views[_views.count-1])
			} else {
				var parent = get_parent_node(root)
				var is_a = (parent.a == this)
				var other = is_a ? parent.b : parent.a
				if (other.get_locked_size()) {
					_views = []
					add_view(EmptyView.new())
				} else {
					parent.consume(other)
					var p = parent
					while (p.type != "leaf") {
						p = is_a ? p.a : p.b
					}
					p.set_active_view(p.active_view)
				}
			}
			Core.last_active_view = nil
		}
		_active_view.try_close(do_close)
	}

	add_view(view) {
		Common.assert(_type == "leaf", "Tried to add view to non-leaf node")
		Common.assert(!_locked, "Tried to add view to locked node")
		if (_views.count >= 1 && _views[0] && (_views[0] is EmptyView)) {
			_views.removeAt(-1)
		}
		_views.add(view)
		set_active_view(view)
	}

	set_active_view(view) {
		import "core" for Core
		Common.assert(_type == "leaf", "Tried to set active view on non-leaf node")
		_active_view = view
		Core.set_active_view(view)
	}

	get_view_idx(view) {
		for (i in 0..._views.count) {
			if (_views[i] == view) return i
		}
	}

	get_node_for_view(view) {
		for (v in _views) {
			if (v == view) return this
		}
		if (_type != "leaf") {
			return _a.get_node_for_view(view) || _b.get_node_for_view(view)
		}
	}

	get_parent_node(root) {
		if (root.a == this || root.b == this) {
			return root
		} else if (root.type != "leaf") {
			return get_parent_node(root.a) || get_parent_node(root.b)
		}
	}

	get_children() { get_children([]) }

	get_children(t) {
		for (view in _views) t.add(view)
		if (_a) _a.get_children(t)
		if (_b) _b.get_children(t)
		return t
	}

	get_divider_overlapping_point(point) {
		if (_type != "leaf") {
			var p = 6
			var rect = get_divider_rect()
			rect.x = rect.x - p
			rect.y = rect.y - p
			rect.width = rect.width + p * 2
			rect.height = rect.height + p * 2
			// TODO(thacuber2a03): pack this if up
			if (point.x > rect.x && point.y > rect.y && point.x < rect.x + rect.width &&  point.y < rect.y + rect.height) {
				return this
			}
			var o = _a.get_divider_overlapping_point(point)
			return o || _b.get_divider_overlapping_point(point)
		}
	}

	get_tab_overlapping_point(p) {
		if (_views == 1) return
		var rect = get_tab_rect(1)
		if (p.x >= rect.x && p.y >= rect.y &&  p.x < rect.x + rect.width * _views.count && p.y < y + h) {
			return ((p.x - rect.x) / rect.width).floor + 1
		}
	}

	get_child_overlapping_point(p) {
		var child
		if (_type == "leaf") {
			return this
		} else if (_type == "hsplit") {
			child = p.x < _b.position.x ? _a : _b
		} else if (_type == "vsplit") {
			child = p.y < _b.position.y ? _a : _b
		}
		return child.get_child_overlapping_point(p)
	}

	get_tab_rect(idx) {
		var tw = Style.tab_width.min((_size.x / _views.count).ceil)
		var h = Style.font.get_height() + Style.padding.y * 2
		return Rect.new(_position.x + (idx-1) * tw, _position.y, tw, h)
	}

	get_divider_rect() {
		var x = _position.x
		var y = _position.y
		if (_type == "hsplit") {
			return Rect.new(x + _a.size.x, y, Style.divider_size, _size.y)
		} else if (_type == "vsplit") {
			return Rect.new(x, y + _a.size.y, _size.x, Style.divider_size)
		}
	}

	get_locked_size() {
		if (_type == "leaf") {
			if (_locked) return _active_view.size
		} else {
			var p1 = _a.get_locked_size()
			var p2 = _b.get_locked_size()
			if (p1 && p2) {
				var dsx = (p1.x < 1 || p2.x < 1) ? 0 : Style.divider_size
				var dsy = (p1.y < 1 || p2.y < 1) ? 0 : Style.divider_size
				return Vector.new(p1.x + p2.x + dsx, p1.y + p2.y + dsy)
			}
		}
	}

	calc_split_sizes_(x, y, x1, x2) {
		var n
		var ds = (x1 && x1 < 1 || x2 && x2 < 1) ? 0 : Style.divider_size
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

	update_layout() {
		if (_type == "leaf") {
			var av = _active_view
			if (_views.count > 1) {
				var th = get_tab_rect(1).height
				av.position.x = _position.x
				av.position.y = _position.y + th
				av.size.x = _size.x
				av.size.y = _size.y - th
			} else {
				Copy_position_and_size.call(av)
			}
		} else {
			var s1 = _a.get_locked_size()
			var s2 = _b.get_locked_size()
			if (_type == "hsplit") {
				calc_split_sizes_("x", "y", s1.x, s2.x)
			} else if (_type == "vsplit") {
				calc_split_sizes_("y", "x", s1.y, s2.y)
			}
			_a.update_layout()
			_b.update_layout()
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

	draw_tabs() {
		import "core" for Core
		var tab_rect = get_tab_rect(1)
		var ds = Style.divider_size
		Core.push_clip_rect(rect.x, rect.y, _size.x, rect.h)
		Renderer.draw_rect(x, y, _size.x, h, Style.background2)
		Renderer.draw_rect(x, y + h - ds, _size.x, ds, Style.divider)

		for (i in 0..._views.count) {
			var view = _views[i]
			var tab_rect = get_tab_rect(i)
			var text = view.get_name()
			var color = Style.dim
			if (view == _active_view) {
				color = Style.text
				Renderer.draw_rect(rect.x, rect.y, rect.width, rect.height, Style.background)
				Renderer.draw_rect(rect.x + rect.width, rect,y, ds, rect.height, Style.divider)
				Renderer.draw_rect(rect.x - ds, rect.y, ds, rect.h, Style.divider)
			}
			if (i == _hovered_tab) color = Style.text
			Core.push_clip_rect(rect.x, rect.y, rect.width, rect.height)
			rect.x = rect.x + Style.padding.x
			rect.width = rect.width - Style.padding.x * 2
			var align = Style.font.get_width(text) > w ? "left" : "center"
			Common.draw_text(Style.font, color, text, align, rect)
			Core.pop_clip_rect()
		}

		Core.pop_clip_rect()
	}

	draw() {
		import "core" for Core
		if (_type == "leaf") {
			if (_views.count > 1) draw_tabs()
			var pos = _active_view.position
			var size = _active_view.size
			Core.push_clip_rect(pos.x, pos.y, size.x + pos.x % 1, size.y + pos.y % 1)
			_active_view.draw()
			Core.pop_clip_rect()
		} else {
			var rect = get_divider_rect()
			renderer.draw_rect(x, y, w, h, Style.divider)
			propagate() { |n| n.draw() }
		}
	}
}

class RootView is View {
	construct new() {
		super()
		_root_node = Node.new()
		_deferred_draws = []
		_mouse = Vector.new()
	}

	root_node { _root_node }

	defer_draw(args, fn) {
		_deferred_draws.insert(0, { "fn": fn, "args": args })
	}

	get_active_node() {
		import "core" for Core
		return _root_node.get_node_for_view(Core.active_view)
	}

	open_doc(doc) {
		import "core" for Core
		var node = get_active_node()
		if (node.locked && Core.last_active_view) {
			Core.set_active_view(Core.last_active_view)
			node = get_active_node()
		}
		Common.assert(!node.locked, "Cannot open doc on locked node")
		for (i in 0..._views.count) {
			var view = _views[i]
			if (view.doc == doc) {
				node.set_active_view(node.views[i])
				return view
			}
		}
		var view = DocView.new(doc)
		node.add_view(view)
		_root_node.update_layout()
		view.scroll_to_line(view.doc.get_selection(), true, true)
		return view
	}

	on_mouse_pressed(event) {
		import "core" for Core
		var mouse = Vector.new(event[2], event[3])
		var div = _root_node.get_divider_overlapping_point(mouse)
		if (div) {
			_dragged_divider = div
			return
		}
		var node = _root_node.get_child_overlapping_point(mouse)
		var idx = node.get_tab_overlapping_point(mouse)
		if (idx) {
			node.set_active_view(node.views[i])
			if (event[1] == "middle") node.close_active_view(_root_node)
		} else {
			Core.set_active_view(node.active_view)
			node.active_view.on_mouse_pressed(event)
		}
	}

	on_mouse_released(event) {
		if (_dragged_divider) _dragged_divider = null
		_root_node.on_mouse_released(event)
	}

	on_mouse_moved(event) {
		if (_dragged_divider) {
			var node = _dragged_divider
			if (node.type == "hsplit") {
				node.divider = node.divider + event[3] / node.size.x
			} else {
				node.divider = node.divider + event[4] / node.size.y
			}
			node.divider = node.divider.clamp(0.01, 0.99)
			return
		}

		_mouse.x = event[1]
		_mouse.y = event[2]
		_root_node.on_mouse_moved(event)

		var mouse = Vector.new(event[1], event[2])
		var node = _root_node.get_child_overlapping_point(mouse)
		var div = _root_node.get_divider_overlapping_point(mouse)
		if (div) {
			Program.set_cursor(div.type == "hsplit" ? "sizeh" : "sizev")
		} else if (node.get_tab_overlapping_point(mouse)) {
			Program.set_cursor("arrow")
		} else {
			Program.set_cursor(node.active_view.cursor)
		}
	}

	on_mouse_wheel(event) {
		var node = _root_node.get_child_overlapping_point(_mouse)
		node.active_view.on_mouse_wheel(event)
	}

	on_text_input(event) {
		import "core" for Core
		return Core.active_view.on_text_input(event)
	}

	update() {
		Copy_position_and_size.call(_root_node, this)
		_root_node.update()
		_root_node.update_layout()
	}

	draw() {
		_root_node.draw()
		while (_deferred_draws.count > 0) {
			var m = _deferred_draws.removeAt(-1)
			t["fn"].call(t["args"])
		}
	}
}
