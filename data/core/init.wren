import "renderer" for Renderer
import "system" for Clock, Window, Events, Process, Program, Filesystem
import "core/config" for Config
import "core/common" for Common, Vector, Rect

class CoreImpl {
	construct new() {
		_clipRectStack = [Rect.new()]
	}

	init() {
		// Renderer.debug = true

		var projectDir = Program.executableDirectory
		var files = []
		var args = Process.args
		for (i in 1...args.count) {
			var info = Filesystem.info(args[i]) || {}
			var type = info["type"]
			if (type == "file") {
				files.add(Filesystem.abs(args[i]))
			} else if (type == "dir") {
				projectDir = args[i]
			}
		}

		Filesystem.chdir(projectDir)

		import "core/rootview" for RootView
		// import "core/commandview" for CommandView
		import "core/statusview" for StatusView

		_rootView = RootView.new()
		// _commandView = CommandView.new()
		_statusView = StatusView.new()

		// _rootView.rootNode.split("down", _commandView, true)
		 _rootView.rootNode.split("down", _statusView, true)

		redraw = true
	}

	try(f) {
		var fib = Fiber.new {
			// TODO(thacuber2a03): something else
			f.call()
		}
		var res = fib.try()
		return [fib.error == null, res]
	}

	quit() {
		Process.exit()
	}

	setActiveView(view) {
		Common.assert(view, "Tried to set active view to null")
		if (view != activeView) {
			lastActiveView = activeView
			activeView = view
		}
	}

	onEvent(type, params) {
		var didKeymap = true
		if (type == "quit") {
			quit()
		} else if (type == "mousemoved") {
			_rootView.onMouseMoved(Vector.new(params[0], params[1]), Vector.new(params[2], params[3]))
		} else if (type == "mousepressed") {
			_rootView.onMousePressed(params[0], Vector.new(params[1], params[2]), params[3])
		} else if (type == "mousereleased") {
			_rootView.onMouseReleased(params[0], Vector.new(params[1], params[2]))
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
			redraw = true
		}

		if (mouseMoved) try { onEvent("mousemoved", [mouse["x"], mouse["y"], mouse["dx"], mouse["dy"]]) }

		var size = Renderer.size

		_rootView.size.set(size[0], size[1])
		_rootView.update()
		if (!redraw) return false
		redraw = false

		var name = activeView.name
		var title = name != "---" ? "%(name) - lite-wren" : "lite-wren"
		if (title != _windowTitle) {
			Window.title = title
			_windowTitle = title
		}

		Renderer.beginFrame()
		_clipRectStack[0].set(0,0,size[0],size[1])
		Renderer.clip = _clipRectStack[0].toList
		_rootView.draw()
		Renderer.endFrame()

		return true
	}

	run() {
		while (true) {
			frameStart = Clock.now
			var didRedraw = step()
			// run_threads()
			if (!(didRedraw || Window.hasFocus)) Events.wait(0.25)
			var elapsed = Clock.now - frameStart
			Clock.sleep(0.max(1/Config.fps-elapsed))
		}
	}

	onError() {

	}

	lastActiveView { _lastActiveView }
	lastActiveView=(v) { _lastActiveView=v }
	activeView { _activeView }
	activeView=(v) { _activeView=v }
	frameStart { _frameStart }
	frameStart=(v) { _frameStart=v }
	redraw { _redraw }
	redraw=(v) { _redraw = v }

	rootView { _rootView }
	statusView { _statusView }
	commandView { _commandView }
}

var Core = CoreImpl.new()
