import "api" for Program, Renderer
import "core/config" for Config
import "core/shapes" for Rect

class Core {
	static init() {
	}

	static try(fn, args) {
		var f = Fiber.new { fn.call() }
		var res = f.try()
		if (f.error) return [false, f.error]
		return [true, res]
	}

	static on_event(event) {
		var did_keymap = false

		var type = event[0]
		if (type == "quit") core.quit()
	}

	static step() {
		var did_keymap = false
		var mouse_moved = false
		var mouse = [0, 0, 0, 0]

		var event = Program.poll_event()
		if (event == "mousemoved") {
			mouse_moved = true
			mouse[0] = event[1]
			mouse[1] = event[2]
			mouse[2] = mouse[2] - event[3]
			mouse[3] = mouse[3] - event[4]
		} else if (type == "textinput" && did_keymap) {
			did_keymap = false
		} else {
			var res = Core.try(Fn.new { |a| Core.on_event(a) }, event)
		}

		if (mouse_moved) {
			Core.try(
				Fn.new { |a| Core.on_event(a) },
				["mousemoved", mouse[0], mouse[1], mouse[2], mouse[3]]
			)
		}

		var size = Renderer.get_size()

		var title = "lite"
		if (title != __window_title) {
			Program.set_window_title(title)
			__window_title = title
		}

		Renderer.begin_frame()
		if (!__clip_rect_stack) __clip_rect_stack = []
		__clip_rect_stack.add(Rect.new(0, 0, size[0], size[1]))
		// I need a list version of this one urgently
		Renderer.set_clip_rect(
			__clip_rect_stack[0].x,
			__clip_rect_stack[0].y,
			__clip_rect_stack[0].width,
			__clip_rect_stack[0].height
		)
		Renderer.end_frame()
	}

	static run() {
		while (true) {
			__frame_start = Program.get_time()
			var did_redraw = Core.step()
			if (!did_redraw && !Program.window_has_focus()) {
				Program.wait_event(0.25)
			}
			var elapsed = Program.get_time() - __frame_start
			Program.sleep(0.max(1/Config.fps - elapsed))
		}
	}
}

