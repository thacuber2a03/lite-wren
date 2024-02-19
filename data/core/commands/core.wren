import "api" for Program
import "core" for Core
import "core/common" for Common
import "core/command" for Command
import "core/keymap" for Keymap
import "core/logview" for LogView

var Fullscreen = false

Command.add(null, {
  "core:quit": Fn.new { Core.quit() },
  "core:force-quit": Fn.new { Core.quit(true) },

  "core:toggle-fullscreen": Fn.new {
    Fullscreen = !Fullscreen
    Program.set_window_mode(Fullscreen ? "fullscreen" : "normal")
  },

  "core:find-command": Fn.new {
    var commands = Command.get_all_valid()
    Core.command_view.enter("Do Command", Fn.new { |text, item|
      if (item) Command.perform(item.command)
    }, Fn.new { |text|
      var res = Common.fuzzy_match(commands, text)
      for (i in 0...res.count) {
        var name = res[i]
        res[i] = {
          "text": Command.prettify_name(name),
          "info": Keymap.get_binding(name),
          "command": name,
        }
      }
      return res
    })
  },

  "core:new-doc": Fn.new {
    Core.root_view.open_doc(Core.open_doc())
  },
})
