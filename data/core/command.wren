import "core" for Core
import "core/common" for Common

class Command {
	construct new() {
		__alwaysTrue = Fn.new{ true }

		_map = {}
	}

	add(map) { add(map, __alwaysTrue) }
	add(map, predicate) {
		if (predicate is Class) {
			import "core" for Core
			var klass = predicate // NOTE(thacuber2a03): kidz korner
			predicate = Fn.new{ Core.activeView is klass }
		}
		for (bind in map) {
			Common.assert(!_map[bind.key], "command already exists: %(bind.key)")
			_map[bind.key] = { "predicate": predicate, "perform": bind.value }
		}
	}

	prettifyName(name) {
		name = name.replace(":", ": ")
		           .replace("-", " ")

		var words = []
		var word = ""
		var start = true
		for (char in name) {
			if (Common.isSpace(char)) {
				words.add(word)
				word = ""
			} else {
				word = word + start ? Common.upper(char) : char
				start = false
			}
		}

		return words.join(" ")
	}

	perform(name) {
		var res = Core.try {
			var cmd = _map[name]
			if (cmd && cmd["predicate"].call()) {
				cmd["perform"].call()
				return true
			}
			return false
		}
		return !res[0] || res[1]
	}

	addDefaults() {
		import "core/commands/core"
		// import "core/commands/root"
		// import "core/commands/command"
		// import "core/commands/doc"
		// import "core/commands/findreplace"
	}
}

Command = Command.new()
