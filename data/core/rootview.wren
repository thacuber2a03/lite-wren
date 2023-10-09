import "api" for Program, Renderer
import "core/keymap" for Keymap
import "core/style" for Style
import "core/view" for View

class EmptyView is View {
	construct new() {
		super()
	}

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

class RootView is EmptyView {
	construct new() { super() }
}
