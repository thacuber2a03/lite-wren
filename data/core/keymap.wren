import "core/common" for Common

class Keymap {
	construct new() {
		__modkeys = [ "ctrl", "alt", "altgr", "shift" ]
		__modkeyMap = {
			"left ctrl":   "ctrl",
			"right ctrl":  "ctrl",
			"left shift":  "shift",
			"right shift": "shift",
			"left alt":    "alt",
			"right alt":   "altgr",
		}

		_modkeys = {}
		_map = {}
		_reverseMap = {}
	}

	keyToStroke_(k) {
		var stroke = ""
		for (mk in __modkeys) {
			if (_modkeys[mk]) {
				stroke = stroke + mk + "+"
			}
		}
		return stroke + k
	}

	add(map)            { add(false, map) }
	add(overwrite, map) {
		for (bind in map) {
			var stroke = bind.key
			var commands = bind.value

			if (commands is String) commands = [commands]

			if (overwrite) {
				_map[stroke] = commands
			} else {
				_map[stroke] = _map[stroke] || []
				for (i in (commands.count-1)..0) {
					_map[stroke].insert(0, commands[i])
				}
			}

			for (cmd in commands) _reverseMap[cmd] = stroke
		}
	}

	binding(cmd) { Common.assert(_reverseMap[cmd], "Keymap.binding: no bind for %(cmd)") }

	onKeyPressed(k) {
		var mk = __modkeyMap[k]
		if (mk) {
			_modkeys[mk] = true
			// work-around for windows where `altgr` is treated as `ctrl+alt`
			// NOTE(thacuber2a03): haha, cope Windows users
			if (mk == "altgr") _modkeys["ctrl"] = false
		} else {
			var stroke = keyToStroke_(k)
			var commands = _map[stroke]
			if (commands) {
				for (cmd in commands) {
					// var performed = Command.perform(cmd)
					// if (performed) break
				}
				return true
			}
		}
		return false
	}

	onKeyReleased(k) {
		var mk = __modkeyMap[k]
		if (mk) _modkeys[mk] = false
	}
}

// NOTE(thacuber2a03): singletons go brrrrrrrrrrr
Keymap = Keymap.new()

Keymap.add({
	"ctrl+shift+p": "core:find-command",
	"ctrl+p":       "core:find-file",
	"ctrl+o":       "core:open-file",
	"ctrl+n":       "core:new-doc",
	"alt+return":   "core:toggle-fullscreen",

	"alt+shift+j": "root:split-left",
	"alt+shift+l": "root:split-right",
	"alt+shift+i": "root:split-up",
	"alt+shift+k": "root:split-down",
	"alt+j":       "root:switch-to-left",
	"alt+l":       "root:switch-to-right",
	"alt+i":       "root:switch-to-up",
	"alt+k":       "root:switch-to-down",

	"ctrl+w":         "root:close",
	"ctrl+tab":       "root:switch-to-next-tab",
	"ctrl+shift+tab": "root:switch-to-previous-tab",
	"ctrl+pageup":    "root:move-tab-left",
	"ctrl+pagedown":  "root:move-tab-right",
	"alt+1":          "root:switch-to-tab-1",
	"alt+2":          "root:switch-to-tab-2",
	"alt+3":          "root:switch-to-tab-3",
	"alt+4":          "root:switch-to-tab-4",
	"alt+5":          "root:switch-to-tab-5",
	"alt+6":          "root:switch-to-tab-6",
	"alt+7":          "root:switch-to-tab-7",
	"alt+8":          "root:switch-to-tab-8",
	"alt+9":          "root:switch-to-tab-9",

	"ctrl+f":       "find-replace:find",
	"ctrl+r":       "find-replace:replace",
	"f3":           "find-replace:repeat-find",
	"shift+f3":     "find-replace:previous-find",
	"ctrl+g":       "doc:go-to-line",
	"ctrl+s":       "doc:save",
	"ctrl+shift+s": "doc:save-as",

	"ctrl+z":               "doc:undo",
	"ctrl+y":               "doc:redo",
	"ctrl+x":               "doc:cut",
	"ctrl+c":               "doc:copy",
	"ctrl+v":               "doc:paste",
	"escape":               [ "command:escape", "doc:select-none" ],
	"tab":                  [ "command:complete", "doc:indent" ],
	"shift+tab":            "doc:unindent",
	"backspace":            "doc:backspace",
	"shift+backspace":      "doc:backspace",
	"ctrl+backspace":       "doc:delete-to-previous-word-start",
	"ctrl+shift+backspace": "doc:delete-to-previous-word-start",
	"delete":               "doc:delete",
	"shift+delete":         "doc:delete",
	"ctrl+delete":          "doc:delete-to-next-word-end",
	"ctrl+shift+delete":    "doc:delete-to-next-word-end",
	"return":               [ "command:submit", "doc:newline" ],
	"keypad enter":         [ "command:submit", "doc:newline" ],
	"ctrl+return":          "doc:newline-below",
	"ctrl+shift+return":    "doc:newline-above",
	"ctrl+j":               "doc:join-lines",
	"ctrl+a":               "doc:select-all",
	"ctrl+d":               [ "find-replace:select-next", "doc:select-word" ],
	"ctrl+l":               "doc:select-lines",
	"ctrl+/":               "doc:toggle-line-comments",
	"ctrl+up":              "doc:move-lines-up",
	"ctrl+down":            "doc:move-lines-down",
	"ctrl+shift+d":         "doc:duplicate-lines",
	"ctrl+shift+k":         "doc:delete-lines",

	"left":       "doc:move-to-previous-char",
	"right":      "doc:move-to-next-char",
	"up":         [ "command:select-previous", "doc:move-to-previous-line" ],
	"down":       [ "command:select-next", "doc:move-to-next-line" ],
	"ctrl+left":  "doc:move-to-previous-word-start",
	"ctrl+right": "doc:move-to-next-word-end",
	"ctrl+[":     "doc:move-to-previous-block-start",
	"ctrl+]":     "doc:move-to-next-block-end",
	"home":       "doc:move-to-start-of-line",
	"end":        "doc:move-to-end-of-line",
	"ctrl+home":  "doc:move-to-start-of-doc",
	"ctrl+end":   "doc:move-to-end-of-doc",
	"pageup":     "doc:move-to-previous-page",
	"pagedown":   "doc:move-to-next-page",

	"shift+left":       "doc:select-to-previous-char",
	"shift+right":      "doc:select-to-next-char",
	"shift+up":         "doc:select-to-previous-line",
	"shift+down":       "doc:select-to-next-line",
	"ctrl+shift+left":  "doc:select-to-previous-word-start",
	"ctrl+shift+right": "doc:select-to-next-word-end",
	"ctrl+shift+[":     "doc:select-to-previous-block-start",
	"ctrl+shift+]":     "doc:select-to-next-block-end",
	"shift+home":       "doc:select-to-start-of-line",
	"shift+end":        "doc:select-to-end-of-line",
	"ctrl+shift+home":  "doc:select-to-start-of-doc",
	"ctrl+shift+end":   "doc:select-to-end-of-doc",
	"shift+pageup":     "doc:select-to-previous-page",
	"shift+pagedown":   "doc:select-to-next-page",
})
