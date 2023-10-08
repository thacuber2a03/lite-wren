import "api" for Program, Renderer
import "core/config" for Config
import "core/shapes" for Rect

class Core {
	static init() {
	}

	static quit(force) {
		if (force) {
			Program.exit(0)
		}
	}

	static try(args, fn) {
		var f = Fiber.new { fn.call() }
		var res = f.try()
		if (f.error) return [false, f.error]
		return [true, res]
	}

	static on_event(event) {
		System.print(event)
		var did_keymap = false

		var type = event[0]
		if (type == "quit") core.quit(true)
	}

	static step() {
		var did_keymap = false
		var mouse_moved = false
		var mouse = [0, 0, 0, 0]

		var event = Program.poll_event()
		while (event)
		{
			if (event == "mousemoved") {
				mouse_moved = true
				mouse[0] = event[1]
				mouse[1] = event[2]
				mouse[2] = mouse[2] - event[3]
				mouse[3] = mouse[3] - event[4]
			} else if (type == "textinput" && did_keymap) {
				did_keymap = false
			} else {
				var r = Core.try(Fn.new { |a| Core.on_event(a) }, event)
				var res = r[1] || did_keymap
			}
			event = Program.poll_event()
		}
		Core.redraw = true

		if (mouse_moved) {
			Core.try(
				Fn.new { |a| Core.on_event(a) },
				["mousemoved", mouse[0], mouse[1], mouse[2], mouse[3]]
			)
		}

		var size = Renderer.get_size()

		if (!Core.redraw) return false
		Core.redraw = false

		var title = "lite"
		if (title != __window_title) {
			Program.set_window_title(title)
			__window_title = title
		}

		Renderer.begin_frame()
		if (!__clip_rect_stack) __clip_rect_stack = []
		__clip_rect_stack.add(Rect.new(0, 0, size[0], size[1]))
		Renderer.set_clip_rect(__clip_rect_stack[0].asList)
		Renderer.end_frame()
		return true
	}

	static run() {
		while (true) {
			__frame_start = Program.get_time()
			var did_redraw = Core.step()
			if (!did_redraw && !Program.window_has_focus()) Program.wait_event(0.25)
			var elapsed = Program.get_time() - __frame_start
			Program.sleep(0.max(1/Config.fps - elapsed))
		}
	}

	redraw {
		if (!__redraw) __redraw = false
		return __redraw
	}

	redraw=(v) { __redraw = v }
}

