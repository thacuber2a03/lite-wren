import core for Core

class Prelude {
  foreign static ARGS
  static VERSION { " VERSION " }
  static PATHSEP { " PATHSEP " }
  foreign static PLATFORM
  foreign static SCALE
  foreign static EXEFILE

  static start() {
    var err = Fiber.new {
      Core.init()
      Core.run()
    }.try()

    if (err != null) Core.on_error(err)
  }
}

class System {
  foreign static poll_event()
  foreign static wait_event(seconds)
  foreign static set_cursor(cursor)
  foreign static set_window_title(title)
  foreign static set_window_mode(mode)
  foreign static window_has_focus()
  foreign static show_confirm_dialog(title, msg)
  foreign static chdir(dir)
  foreign static list_dir(path)
  foreign static absolute_path(path)
  foreign static get_file_info(file)
  foreign static get_clipboard()
  foreign static set_clipboard(contents)
  foreign static get_time()
  foreign static sleep(seconds)
  foreign static exec(command)
  foreign static fuzzy_match(str, pattern)
}

