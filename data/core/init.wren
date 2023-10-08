import "prelude" for Program, Renderer

class Core {
	static init() {
	}

	static run() {
		while (true) {
			__frame_start = Program.get_time()

			var event = Program.poll_event()
			if (event[0] == "quit") break

			Renderer.begin_frame()
			Renderer.end_frame()

			if (!Program.window_has_focus()) Program.wait_event(0.25)
			var elapsed = Program.get_time() - __frame_start
			Program.sleep(0.max(1/60 - elapsed))
		}
	}

	static on_error(err) {
		System.print(err)
	}
}

