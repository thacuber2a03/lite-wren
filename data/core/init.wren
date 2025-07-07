import "renderer" for Renderer
import "system" for Clock, Window, Events, Process, Program, Filesystem

import "core/common" for Common, Vector, Rect

import "core/config" for Config

class Core {
	construct new() {
		var projectDir = Program.exeDir
		var args = Process.args
		for (i in 1...args.count) {
			var info = Filesystem.info(args[i]) || {}
			if (info["type"] == "file") {
				files.add(Filesystem.abs(args[i]))
			} else if (info["type"] == "dir") {
				projectDir = args[i]
			}
		}
		Filesystem.chdir(projectDir)

		_clipRectStack = [Rect.new(0,0,0,0)]
		_logItems = []
		_docs = []
		_threads = {} // setmetatable({}, { __mode = "k" })
		_projectFiles = {}
		_redraw = true
	}

	init() {
		import "core/rootview" for RootView
		_rootView = RootView.new()
	}

	activeView=(view) {
		Common.assert(view, "Tried to set active view to null")
		if (view != _activeView) {
			_lastActiveView = _activeView
			_activeView = view
		}
	}

	try(f) {
		f = Fiber.new(f)
		var res = f.try()
		return [!f.error, res]
	}

	quit() { quit(false) }
	quit(force) {
		if (force) Process.exit()
		quit(true)
	}

	onEvent(type, params) {
		var didKeymap = false
		if (type == "textinput") {

		} else if (type == "quit") {
			quit()
		}
		return didKeymap
	}

	step() {
		var didKeymap = false
		var mouseMoved = false
		var mousePos = Vector.zero
		var mouseDelta = Vector.zero

		while (true) {
			var e = Events.poll
			if (!e) break
			var type = e[0]
			if (type == "mousemoved") {
				mouseMoved = true
				mousePos.set(e[1], e[2])
				mouseDelta = mouseDelta + Vector.new(e[3], e[4])
			} else if (type == "textinput" && didKeymap) {
				didKeymap = false
			} else {
				var res = try { onEvent(e[0], e[1..-1]) }
				didKeymap = res[1] || didKeymap
			}
			_redraw = true
		}
		if (mouseMoved) try {
			onEvent("mousemoved", [mousePos.x, mousePos.y, mouseDelta.x, mouseDelta.y])
		}

		var size = Renderer.size

		_rootView.size.set(size[0], size[1])
		_rootView.update()
		if (!_redraw) return false
		_redraw = false

		var name = "---"
		var title = name != "---" ? "%(name) - lite-wren" : "lite-wren"
		if (title != _windowTitle) {
			Window.title = title
			_windowTitle = title
		}

		Renderer.beginFrame()
		_clipRectStack[0].set(0,0,size[0], size[1])
		Renderer.clipRect = _clipRectStack[0].toList
		_rootView.draw()
		Renderer.endFrame()

		return false
	}

	run() {
		while (true) {
			_frameStart = Clock.now
			var didRedraw = step()
			if (!didRedraw && !Window.hasFocus) Events.wait(0.25)
			var elapsed = Clock.now - _frameStart
			Clock.sleep(0.max(1/Config.fps-elapsed))
		}
	}

	redraw { _redraw }
	redraw=(v) { _redraw=v }
}

Core = Core.new()
