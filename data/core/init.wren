import "renderer" for Renderer
import "system" for Clock, Window, Events, Process

class Core {
	construct new() {

	}

	try(f) {
		var fib = Fiber.new {
			// something else
			f.call()
		}
		var res = fib.try()
		return [!fib.error, res]
	}

	quit() {
		Process.exit()
	}

	onEvent(type, params) {
		var didKeymap = true
		if (type == "quit") {
			quit()
		}
		return didKeymap
	}

	step() {
		var didKeymap = false
		var mouseMoved = false
		var mouse = {
			"x": 0, "y": 0,
			"dx": 0, "dy": 0,
		}

		while (true) {
			var e = Events.poll
			if (!e) break
			var type = e[0]
			if (type == "mousemoved") {
				mouseMoved = true
				mouse["x"] = e[1]
				mouse["y"] = e[2]
				mouse["dx"] = mouse["dx"] + e[3]
				mouse["dy"] = mouse["dy"] + e[4]
			} else if (type == "textinput") {
				didKeymap = false
			} else {
				var t = try { onEvent(type, e[1..-1]) }
				didKeymap = t[1] || didKeymap
			}
			this.redraw = true
		}

		if (mouseMoved) {
			try { onEvent(e[0], e[1..-1]) }
		}

		if (!redraw) return false
		redraw = false

		// var name =
		// var title = name != "---" ? name + " - lite-wren" : "lite-wren"
		// if (title != _window_title) {
		// 	Window.title = title
		// 	_window_title = title
		// }

		Renderer.beginFrame()
		Renderer.drawRect(0, 0, 100, 100, [255, 255, 255, 255])
		// _clip_rect_stack[0] = Rect.new(0, 0, width, height)
		// Renderer.clip = _clip_rect_stack[0]
		Renderer.endFrame()

		return true
	}

	run() {
		while (true) {
			_frame_start = Clock.now
			var didRedraw = step()
			// run_threads()
			if (!(didRedraw || Window.hasFocus)) Events.wait(0.25)
			var elapsed = Clock.now - _frame_start
			Clock.sleep(0.max(1/60 /* config.fps */ -elapsed))
		}
	}

	onError() {

	}

	redraw=(v) { _redraw = v }
	redraw { _redraw }
}
