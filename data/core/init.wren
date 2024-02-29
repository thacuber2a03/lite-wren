import "api" for Program, Renderer
import "core/shapes" for Vector, Rect

class Core {
  static redraw { __redraw }
  static redraw=(v) { __redraw = v }

  static root_view { __root_view }
  static command_view { __command_view }
  static status_view { __status_view }
  static last_active_view { __last_active_view }
  static active_view { __active_view }

  static docs { __docs }
  static project_files { __project_files }

  static init() {
    var project_dir = Program.EXEDIR
    var files = []
    if (Program.ARGS.count > 1) {
      for (i in 1...Program.ARGS.count) {
        var info = Program.get_file_info(Program.ARGS[i])
        if (!info) continue

        if (info["type"] == "file") {
          files.add(Program.absolute_path(Program.ARGS[i]))
        } else if (info["type"] == "dir") {
          project_dir = Program.ARGS[i]
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
    __command_view = CommandView.new()
    __status_view = StatusView.new()

    __root_view.root_node.split("down", __command_view, true)
    __root_view.root_node.b.split("down", __status_view, true)

    Command.add_defaults()
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

  static push_clip_rect(x, y, w, h) { push_clip_rect(Rect.new(x, y, w, h)) }

  static push_clip_rect(rect) {
    var rect2 = __clip_rect_stack[-1]
    var r = rect.x + rect.w
    var b = rect.y + rect.h
    var r2 = rect2.x + rect2.w
    var b2 = rect2.y + rect2.h
    rect.x = rect.x.max(rect2.x)
    rect.y = rect.y.max(rect2.y)
    b = b.min(b2)
    r = r.min(r2)
    rect.w = r - rect.x
    rect.h = b - rect.y
    __clip_rect_stack.add(rect)
    Renderer.set_clip_rect(rect.asList)
  }

  static pop_clip_rect() {
    __clip_rect_stack.removeAt(-1)
    var rect = __clip_rect_stack[-1]
    Renderer.set_clip_rect(rect.x, rect.y, rect.w, rect.h)
  }

  static open_doc() {
    var doc = Doc.new()
    __docs.add(doc)
    // Core.log_quiet("Opened new doc")
    return doc
  }

  static open_doc(filename) {
    var abs_filename = Program.absolute_path(filename)
    for (doc in __docs) {
      if (doc.filename && abs_filename == Program.absolute_path(doc.filename)) {
        return doc
      }
    }

    var doc = Doc.new(filename)
    __docs.add(doc)
    // Core.log_quiet("Opened doc %(filename)")
    return doc
  }

  static try(args, fn) {
    var f = Fiber.new(fn)
    var res = f.call(args)
    if (f.error) return [false, f.error]
    return [true, res]
  }

  static on_event(event) {
    var did_keymap = false

    var type = event[0]
    if (type == "textinput") {
      __root_view.on_text_input(event[1])
    } else if (type == "keypressed") {
      did_keymap = Keymap.on_key_pressed(event[1])
    } else if (type == "keyreleased") {
      Keymap.on_key_released(event[1])
    } else if (type == "mousemoved") {
      __root_view.on_mouse_moved(
        Vector.new(event[1], event[2]),
        Vector.new(event[3], event[4])
      )
    } else if (type == "mousepressed") {
      __root_view.on_mouse_pressed(event[1], Vector.new(event[2], event[3]), event[4])
    } else if (type == "mousereleased") {
      __root_view.on_mouse_released(event[1], Vector.new(event[2], event[3]))
    } else if (type == "mousewheel") {
      __root_view.on_mouse_wheel(event[1])
    } else if (type == "filedropped") {
      // TODO(thacuber2a03): implement
    } else if (type == "quit") {
      Core.quit()
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
      __redraw = true
      event = Program.poll_event()
    }

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

// this looks really weird, but compared to
// writing 'import "core" for Core' at the end of
// every other file, this is the best approach

import "core/common" for Common
import "core/config" for Config
import "core/style" for Style
import "core/command" for Command
import "core/keymap" for Keymap
import "core/rootview" for RootView
import "core/statusview" for StatusView
import "core/commandview" for CommandView
import "core/doc" for Doc
