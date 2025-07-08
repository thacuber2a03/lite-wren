import "core" for Core
import "core/command" for Command
import "core/logview" for LogView

Command.add({
	"core:quit": Fn.new{ Core.quit() },
	"core:force-quit": Fn.new{ Core.quit() },

	"core:open-log": Fn.new{
		Core.rootView.activeNode.addView(LogView.new())
	}
})
