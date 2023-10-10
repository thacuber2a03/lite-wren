import "core" for Core
import "core/common" for Common

var Always_true = Fn.new { true }

var Perform = Fn.new { |name|
	var cmd = Command.map[name]
	if (cmd && cmd["predicate"].call()) {
		cmd["perform"].call()
		return true
	}
	return false
}

class Command {
	static map {
		if (!__map) __map = {}
		return __map
	}

	static add(predicate, map) {
		predicate = predicate || Always_true
		// string predicates are unsupported
		if (predicate is Class) {
			var klass = predicate
			predicate = Fn.new { Core.active_view is klass }
		}
		for (entry in map) {
			var name = entry.key
			var fn = entry.value

			Common.assert(!Command.map[name], "command already exists: %(name)")
			Command.map[name] = { "predicate": predicate, "perform": fn }
		}
	}

	static prettify_name(name) {
		// TODO(thacuber2a03): capitalize
		return name.replace(":", ": ").replace("-", " ")
	}

	static get_all_valid() {
		var res = []
		for (entry in Command.map) {
			if (entry.value["predicate"].call()) res.add(name)
		}
		return res
	}

	static perform(args) {
		var res = Core.try(args, Perform)
		return !res[0] || res[1]
	}
}
