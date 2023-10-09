import "api" for Program, Renderer
import "core/config" for Config
import "core/common" for Common
import "core/shapes" for Rect
import "core/rootview" for RootView

class Core {
	static redraw { __redraw }
	static redraw=(v) { __redraw = v }

	static root_view { __root_view }

	static init() {
		var project_dir = Program.EXEDIR
		var files = []
		if (Program.ARGS.count > 1) {
			for (i in 1...Program.ARGS.count) {
				var info = Program.get_file_info(Program.ARGS[i]) || {}

				if (info.contains("type")) {
					if (info["type"] == "file") {
						files.add(Program.absolute_path(Program.ARGS[i]))
					} else if (info["type"] == "dir") {
						project_dir = Program.ARGS[i]
					}
				}
			}
		}

		Program.chdir(project_dir)

		__frame_start = 0
		__clip_rect_stack = [ Rect.new(0, 0, 0, 0) ]
		__log_items = []
		__docs = []
		__threads = []
		__project_files = []
		__redraw = true

		__root_view = RootView.new()
		// until I find where the hell is __active_view actually set
		set_active_view(__root_view)
	}

	static quit(force) {
		if (force) {
			Program.exit()
		}
		return Core.quit(true)
	}

	static quit() { Core.quit(false) }

	static set_active_view(view) {
		Common.assert(view, "Tried to set active view to null")
		if (view != __active_view) {
			__last_active_view = __active_view
			__active_view = view
		}
	}

	static try(args, fn) {
		var f = Fiber.new(fn)
		var res = f.try(args)
		if (f.error) return [false, f.error]
		return [true, res]
	}

	static on_event(event) {
		if (event && event.count > 0) {
			var did_keymap = false

			var type = event[0]
			if (type == "quit") Core.quit(true)
		}
	}

	static step() {
		var did_keymap = false
		var mouse_moved = false
		var mouse = [0, 0, 0, 0]

		var event = Program.poll_event()
		while (event) {
			if (event == "mousemoved") {
				mouse_moved = true
				mouse[0] = event[1]
				mouse[1] = event[2]
				mouse[2] = mouse[2] - event[3]
				mouse[3] = mouse[3] - event[4]
			} else if (type == "textinput" && did_keymap) {
				did_keymap = false
			} else {
				var r = Core.try(event) { |a| Core.on_event(a) }
				var res = r[1] || did_keymap
			}
			event = Program.poll_event()
		}
		__redraw = true

		if (mouse_moved) {
			Core.try(
				["mousemoved", mouse[0], mouse[1], mouse[2], mouse[3]]
			) { |a| Core.on_event(a) }
		}

		var size = Renderer.get_size()

		__root_view.size.x = size[0]
		__root_view.size.y = size[1]
		__root_view.update()
		if (!__redraw) return false
		__redraw = false

		var name = __active_view.get_name()
		var title = name != "---" ? name + " - lite" : "lite"
		if (title != __window_title) {
			Program.set_window_title(title)
			__window_title = title
		}

		Renderer.begin_frame()
		__clip_rect_stack[0] = Rect.new(0, 0, size[0], size[1])
		Renderer.set_clip_rect(__clip_rect_stack[0].asList)
		__root_view.draw()
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
}

