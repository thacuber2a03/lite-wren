import "api" for Program, Font
import "core" for Core
import "core/shapes" for Rect
import "core/common" for Common
import "core/command" for Command
import "core/config" for Config
import "core/style" for Style
import "core/view" for View
import "core/docview" for DocView
import "core/logview" for LogView

class StatusView is View {
	static separator { "      " }
	static separator2 { "   |   " }

	construct new() {
		super()
		_message_timeout = 0
		_message = []
	}

	on_mouse_pressed(button, mousePos, clicks) {
		Core.set_active_view(Core.last_active_view)
		if (Program.get_time() < _message_timeout && !(Core.active_view is LogView)) {
			Command.perform("core:open-log")
		}
	}

	show_message(icon, icon_color, text) {
		_message = [
			icon_color, Style.icon_font, icon,
			Style.dim, Style.font, StatusView.separator2, Style.text, text
		]
		_message_timeout = Program.get_time() + Config.message_timeout
	}

	update() {
		this.size.y = Style.font.height + Style.padding.y * 2

		if (Program.get_time() < _message_timeout) {
			this.scroll[1].y = this.size.y
		} else {
			this.scroll[1].y = 0
		}

		super.update()
	}

	draw_items(items, x, y, draw_fn) {
		var font = Style.font
		var color = Style.text

		for (item in items) {
			if (item is Font) {
				font = item
			} else if (item is List) {
				color = item
			} else {
				var res = draw_fn.call([font, color, item.toString, null, Rect.new(x, y, 0, this.size.y)])
				x = res is List ? res[0] : res
			}
		}

		return x
	}

	draw_items(items) { draw_items(items, false, 0) }
	draw_items(items, right_align) { draw_items(items, right_align, 0) }

	draw_items(items, right_align, yoffset) {
		var off = get_content_offset()
		off.y = off.y + (yoffset || 0)
		if (right_align) {
			var w = draw_items(items, 0, 0) { |args| args[4].x + args[0].width(args[2]) }
			off.x = off.x + this.size.x - w - Style.padding.x
			draw_items(items, off.x, off.y) { |args| Common.draw_text(args[0], args[1], args[2], args[3], args[4]) }
		} else {
			off.x = off.x + Style.padding.x
			draw_items(items, off.x, off.y) { |args| Common.draw_text(args[0], args[1], args[2], args[3], args[4]) }
		}
	}

	get_items() {
		if (Core.active_view.type == "DocView") {
			var dv = Core.active_view
			var sel = dv.doc.get_selection()
			sel = sel[0]
			var dirty = dv.doc.is_dirty

			return [
				[
					dirty ? Style.accent : Style.text, Style.icon_font, "f",
					Style.dim, Style.font, StatusView.separator2, Style.text,
					dv.doc.filename ? Style.text : Style.dim, dv.doc.name,
					Style.text,
					StatusView.separator,
					"line: ", sel.line,
					StatusView.separator,
					sel.col > Config.line_limit ? Style.accent : Style.text, "col: ", sel.col,
					Style.text,
					StatusView.separator,
					"%(sel.line / dv.doc.lines.count * 100)\%",
				],
				[
					Style.icon_font, "g",
					Style.font, Style.dim, StatusView.separator2, Style.text,
					dv.doc.lines.count, " lines",
					StatusView.separator,
					dv.doc.crlf ? "CRLF" : "LF"
				]
			]
		}

		return [
			[],
			[
				Style.icon_font, "g",
				Style.font, Style.dim, StatusView.separator2,
				Core.docs.count, Style.text, " / ",
				Core.project_files.count, " files"
			]
		]
	}

	draw() {
		draw_background(Style.background2)

		if (_message) draw_items(_message, false, this.size.y)

		var items = get_items()
		draw_items(items[0])
		draw_items(items[1], true)
	}
}
