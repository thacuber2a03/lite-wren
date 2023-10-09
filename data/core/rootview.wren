import "api" for Program, Renderer
import "core" for Core
import "core/shapes" for Vector
import "core/common" for Common
import "core/keymap" for Keymap
import "core/style" for Style
import "core/view" for View

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
		_hovered_tab = get_tab_overlapping_point(event[0], event[1])
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
		if (!__type_map) {
			__type_map = { "up": "vsplit", "down": "vsplit", "left": "hsplit", "right": "hsplit" }
		}

		Common.assert(_type == "leaf", "Tried to split non-leaf node")
		var type = Common.assert(type_map[dir], "Invalid direction")
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
		var do_close = Fn.new {
			if (_views.count > 1) {
				var idx = get_view_idx(_active_view)
				_views.remove(_active_view)
				set_active_view(_views[idx] || _views[_views.count-1])
			} else {
				var parent = get_parent_node(root)
				var is_a = (parent.a == self)
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
}

class RootView is View {
	construct new() { super() }
}
