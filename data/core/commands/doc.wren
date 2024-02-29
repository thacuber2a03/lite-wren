import "core" for Core
import "core/command" for Command
import "core/docview" for DocView
import "core/doc/translate" for Translate

var GetDoc = Fn.new { Core.active_view.doc }

var commands = {
  "doc:move-to-previous-char": Fn.new {
    var doc = GetDoc.call()
    if (doc.has_selection) {
      var sel = doc.get_selection(true)[0]
      doc.set_selection(sel)
    } else {
      doc.move_to([Translate.previous_char])
    }
  },

  "doc:move-to-next-char": Fn.new {
    var doc = GetDoc.call()
    if (doc.has_selection) {
      var sel = doc.get_selection(true)[1]
      doc.set_selection(sel)
    } else {
      doc.move_to([Translate.next_char])
    }
  }
}

Command.add(Fn.new { Core.active_view is DocView }, commands)
